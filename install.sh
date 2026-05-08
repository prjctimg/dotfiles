#!/bin/sh
set -e

if ! command -v chezmoi >/dev/null 2>&1; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/prjctimg/dotfiles.git
else
  chezmoi init --apply https://github.com/prjctimg/dotfiles.git
fi
