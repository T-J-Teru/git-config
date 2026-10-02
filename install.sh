#!/usr/bin/env bash
#
# install.sh -- set up this machine's git environment from the git-config repo.
#
# Idempotent: safe to re-run. It (1) installs the required packages, (2) creates
# symlinks from the home directory into this repo, and (3) installs the git-who
# helper via `go install`. Any pre-existing *real* file that would be overwritten
# is backed up to <file>.bak first.
#
# Usage:  ./install.sh            # packages + symlinks + git-who
#         ./install.sh --links    # symlinks only (skip dnf and go install)
#
# See README.md for what each piece is and its dependencies.

set -euo pipefail

# Resolve the repo root (directory containing this script), regardless of cwd.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#-----------------------------------------------------------------------------#
# 1. Packages
#-----------------------------------------------------------------------------#

PACKAGES=(
  # git itself.
  git

  # Full standard Perl. Fedora splits the Perl stdlib into many RPMs -- including
  # Getopt::Long, Pod::Usage, File::Temp, File::Copy, POSIX, PathTools and
  # Scalar::List::Utils, all used by the Perl scripts -- that are only guaranteed by
  # the 'perl' meta-package. git alone pulls in just perl-interpreter, so without
  # this the scripts can fail on a minimal install.
  perl

  # Non-core (CPAN) Perl modules the scripts use; the 'perl' meta does NOT provide these:
  #   boolean         -- all six git-* Perl scripts
  #   Carp::Assert    -- git-bgrep, git-conflicts, git-label, git-subdir
  #   List::MoreUtils -- git-prepare-commit-msg
  perl-boolean perl-Carp-Assert perl-List-MoreUtils

  # git-wtf is a Ruby script.
  ruby

  # git send-email delivers through msmtp (sendemail.smtpserver in gitconfig).
  msmtp

  # Commit signing / verification: gitconfig sets gpg.program = gpg2.
  gnupg2

  # gitk's external diff tool (set extdifftool meld in dotfiles/git/gitk).
  meld

  # Go toolchain, used by install_git_who to build git-who (see below).
  golang
)

install_packages() {
  echo ">> Installing packages (sudo)..."
  sudo dnf install -y "${PACKAGES[@]}"
}

#-----------------------------------------------------------------------------#
# 2. Symlinks
#-----------------------------------------------------------------------------#

# link SRC DEST : symlink DEST -> SRC, backing up an existing real DEST.
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    ln -sfn "$src" "$dest"                      # already a symlink: repoint
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.bak"                       # real file: back it up
    echo "   backed up existing $dest -> $dest.bak"
    ln -s "$src" "$dest"
  else
    ln -s "$src" "$dest"
  fi
  echo "   linked $dest -> $src"
}

create_symlinks() {
  echo ">> Creating symlinks..."

  # Global git config (~/.gitconfig): user, aliases, merge/diff drivers, etc.
  link "$REPO/dotfiles/gitconfig" "$HOME/.gitconfig"

  # Global attributes file (git's default is ~/.config/git/attributes): wires up
  # the ChangeLog merge driver and the texinfo/python diff+whitespace rules.
  link "$REPO/dotfiles/git/attributes" "$HOME/.config/git/attributes"

  # gitk UI preferences (fonts, colors, layout). gitk reads ~/.config/git/gitk.
  link "$REPO/dotfiles/git/gitk" "$HOME/.config/git/gitk"

  # ~/bin helper scripts (link every file the repo tracks under bin/). These are
  # git subcommands: on PATH, `git foo` runs ~/bin/git-foo.
  for f in "$REPO"/bin/*; do
    link "$f" "$HOME/bin/$(basename "$f")"
  done
}

#-----------------------------------------------------------------------------#
# 3. git-who (third-party Go tool)
#-----------------------------------------------------------------------------#

# git-who (github.com/sinclairtarget/git-who) is a compiled Go binary -- too big
# and platform-specific to version-control -- so we build it with `go install`
# into ~/bin instead. Idempotent: re-running just rebuilds/updates it. If Go
# isn't available, skip with a note rather than failing (the rest still installs).
install_git_who() {
  local dest="$HOME/bin/git-who"
  if command -v go >/dev/null 2>&1; then
    echo ">> Installing git-who via go install -> $dest"
    mkdir -p "$HOME/bin"
    GOBIN="$HOME/bin" go install github.com/sinclairtarget/git-who@latest
  elif [[ -x "$dest" ]]; then
    echo ">> git-who already present at $dest (go not found; keeping it)"
  else
    echo ">> NOTE: git-who not installed -- 'go' not found."
    echo "   Install Go (dnf install golang) and re-run, or build it yourself:"
    echo "     GOBIN=~/bin go install github.com/sinclairtarget/git-who@latest"
  fi
}

#-----------------------------------------------------------------------------#
# main
#-----------------------------------------------------------------------------#

main() {
  if [[ "${1:-}" != "--links" ]]; then
    install_packages
  fi
  create_symlinks
  if [[ "${1:-}" != "--links" ]]; then
    install_git_who
  fi
  echo
  echo ">> Done. Open a new shell (so ~/bin is on PATH) and the git aliases/"
  echo "   subcommands are ready."
}

main "$@"
