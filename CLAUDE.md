# git-config

Git configuration, aliases, and custom subcommands for a Fedora workstation. Licensed GPLv3.

## Repo layout

```
install.sh          # idempotent installer: packages + symlinks + git-who
bin/                # git subcommands (git-foo -> `git foo`), symlinked to ~/bin
dotfiles/
  gitconfig         # -> ~/.gitconfig (global git config)
  git/attributes    # -> ~/.config/git/attributes (merge/diff drivers)
  git/gitk          # -> ~/.config/git/gitk (gitk UI preferences)
```

## Conventions

- **install.sh** resolves its own directory (`REPO=...`) so it works from any cwd. Uses `set -euo pipefail`. Supports `--links` to skip dnf/sudo steps.
- **Symlinks are explicit** in `create_symlinks()` -- no stow. The `bin/` scripts are linked via a `for` loop over `"$REPO"/bin/*`.
- **GPL headers** go on `install.sh` and every `bin/` script. Do NOT add a header to `dotfiles/gitconfig` or other config files.
- **Third-party files** get a provenance comment instead of a GPL header.
- **git-who** is a third-party Go binary installed via `go install` into `~/bin` (not version-controlled). The `install_git_who()` function handles this separately.

## Key technical details

- The `bin/` scripts are mostly **Perl** (with `perl-boolean`, `perl-Carp-Assert`, `perl-List-MoreUtils` from CPAN). `git-wtf` is **Ruby**.
- `core.editor` is set to `emacs -nw` in gitconfig.
- Git send-email is configured to use **msmtp** as the SMTP transport.
- Commit signing uses **gpg2** (`gpg.program = gpg2`).
- The gitk config uses **meld** as its external diff tool.

## When editing

- If adding a new `bin/` script, the loop picks it up automatically -- just add the GPL header and make it executable.
- If adding a new dotfile under `dotfiles/`, add an explicit `link` call in `create_symlinks()`.
- If adding a Perl dependency, add the `perl-*` RPM to the `PACKAGES` array with a comment listing which scripts use it.
