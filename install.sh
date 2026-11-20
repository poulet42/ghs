#!/bin/sh
# Installs ghs into ~/.ghs and sources it from your shell rc file.
set -e

dir="${GHS_HOME:-$HOME/.ghs}"
repo="https://github.com/poulet42/ghs.git"

if [ -d "$dir/.git" ]; then
  git -C "$dir" pull --ff-only
else
  git clone --depth 1 "$repo" "$dir"
fi

case "${SHELL:-}" in
  */zsh) rc="$HOME/.zshrc" ;;
  *) rc="$HOME/.bashrc" ;;
esac

line="source \"$dir/ghs.sh\""
grep -qxF "$line" "$rc" 2>/dev/null || printf '\n%s\n' "$line" >> "$rc"

echo "ghs installed. Restart your shell (or: source $rc), then run: ghs init"
