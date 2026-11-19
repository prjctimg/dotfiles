/*
 * super-tap — open the Sway apps menu when Meta/Super is tapped by itself.
 *
 * Sway cannot bind a bare modifier key without also firing for every Super
 * chord, so this tiny evdev monitor watches for a Super press/release with no
 * other key pressed in between. Keyboard events are read in parallel with
 * Sway (evdev allows multiple readers).
 */
#define _GNU_SOURCE
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

/* Minimal evdev ABI — Puppy's kernel headers are incomplete. */
struct input_event {
    struct timeval time;
    unsigned short type;
    unsigned short code;
    int value;
};
#define EV_KEY 0x01
#define KEY_LEFTMETA 125
#define KEY_RIGHTMETA 126
#define O_RDONLY 0
#define O_RDWR 2
#define O_CREAT 0100
#define O_NONBLOCK 04000
#define LOCK_EX 2
#define LOCK_NB 4
extern int flock(int fd, int operation);
extern int open(const char *path, int flags, ...);
#define EINTR 4
#define EIO 5
#define ENODEV 19

#define MAX_DEV 32
#define TAP_MAX_MS 700

/* This Puppy image ships a glibc errno.h that needs unavailable Linux
 * headers; declare the libc accessor directly and avoid including errno.h. */
extern int *__errno_location(void);
#define errno (*__errno_location())

static long now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000L + ts.tv_nsec / 1000000L;
}

static void launch_menu(void) {
    pid_t pid = fork();
    if (pid < 0) return;
    if (pid == 0) {
        setsid();
        freopen("/dev/null", "r", stdin);
        freopen("/dev/null", "w", stdout);
        freopen("/dev/null", "w", stderr);
        execlp("wofi", "wofi", "--show", "drun", (char *)NULL);
        _exit(127);
    }
}

int main(void) {
    struct pollfd fds[MAX_DEV];
    int nfds = 0;

    /* One monitor only, even across Sway reloads. */
    int lock = open("/tmp/super-tap.lock", O_CREAT | O_RDWR, 0600);
    if (lock >= 0) {
        if (flock(lock, LOCK_EX | LOCK_NB) != 0) return 0;
    }

    signal(SIGCHLD, SIG_IGN);

    for (int i = 0; i < 32; i++) {
        char path[64];
        snprintf(path, sizeof(path), "/dev/input/event%d", i);
        int fd = open(path, O_RDONLY | O_NONBLOCK);
        if (fd < 0) continue;
        fds[nfds].fd = fd;
        fds[nfds].events = POLLIN;
        fds[nfds].revents = 0;
        nfds++;
    }
    if (nfds == 0) return 0;

    int super_down = 0;
    int other_pressed = 0;
    long pressed_at = 0;

    for (;;) {
        int rc = poll(fds, nfds, -1);
        if (rc < 0) {
            if (errno == EINTR) continue;
            break;
        }
        for (int i = 0; i < nfds; i++) {
            if (!(fds[i].revents & POLLIN)) continue;
            struct input_event ev;
            ssize_t n;
            while ((n = read(fds[i].fd, &ev, sizeof(ev))) == (ssize_t)sizeof(ev)) {
                if (ev.type != EV_KEY) continue;
                if (ev.code == KEY_LEFTMETA || ev.code == KEY_RIGHTMETA) {
                    if (ev.value == 1) {
                        super_down = 1;
                        other_pressed = 0;
                        pressed_at = now_ms();
                    } else if (ev.value == 0 && super_down) {
                        if (!other_pressed && now_ms() - pressed_at < TAP_MAX_MS)
                            launch_menu();
                        super_down = 0;
                        other_pressed = 0;
                    }
                } else if (super_down && ev.value != 0) {
                    other_pressed = 1;
                }
            }
            if (n < 0 && (errno == ENODEV || errno == EIO)) {
                close(fds[i].fd);
                fds[i].fd = -1;
            }
        }
    }
    return 0;
}
