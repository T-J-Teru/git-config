# git-config

Personal **git** configuration and helper scripts, version-controlled and installed
by `install.sh`. The repo holds the **real files**; the home directory gets
**symlinks** pointing back into it. Edit files here, not the symlinks.

The repo can live anywhere — `install.sh` resolves its own location at runtime and
points every symlink back into wherever it's checked out.

## Layout

```
git-config/
├── README.md
├── install.sh                 # idempotent: packages + symlinks + git-who
├── bin/                       -> ~/bin/<name>   (git subcommands; `git foo` = ~/bin/git-foo)
│   ├── git-bgrep              # perl
│   ├── git-conflicts         # perl
│   ├── git-copy-sha          # bash
│   ├── git-ff-merge          # bash  (the `ff` alias)
│   ├── git-label             # perl
│   ├── git-prepare-commit-msg# perl
│   ├── git-repo-id           # bash
│   ├── git-subdir            # perl
│   ├── git-update-changelogs # perl
│   └── git-wtf               # ruby
└── dotfiles/
    ├── gitconfig             -> ~/.gitconfig
    └── git/
        ├── attributes        -> ~/.config/git/attributes
        └── gitk              -> ~/.config/git/gitk
```

## Install

```bash
git clone <this-repo> git-config     # clone it wherever you like
cd git-config
./install.sh            # installs packages (sudo), creates symlinks, builds git-who
# open a new shell so ~/bin is on PATH
```

Re-running `install.sh` is safe. Use `./install.sh --links` to (re)create symlinks
only, skipping `dnf` and the `go install` of git-who.

## Dependencies & notes

Packages installed by `install.sh` (Fedora): `git`, `perl`, `perl-boolean`,
`perl-Carp-Assert`, `perl-List-MoreUtils`, `ruby`, `msmtp`, `gnupg2`, `meld`,
`golang`. The `perl` meta-package is included deliberately: on Fedora the Perl
stdlib is split into separate RPMs (`Getopt::Long`, `Pod::Usage`, `File::Temp`,
`POSIX`, …) that `git` alone doesn't guarantee. The three `perl-*` CPAN modules
are not part of that meta-package, so they're listed explicitly.

Things worth knowing (first-pass items to revisit):

- **No `~/lib` dependency** — the Perl scripts used to `use lib "$ENV{HOME}/lib"`
  for the local `GiveHelp` (`-h`/`--help`) and `Boolean` (`True`/`False`) helpers.
  Those have been replaced with the standard `Pod::Usage` (driving `--help` from
  each script's own POD) and the CPAN `boolean` module, so the scripts are now
  self-contained and need nothing from `~/lib`.
- **`git-who`** — third-party Go tool (github.com/sinclairtarget/git-who). Built
  via `go install` into `~/bin` rather than version-controlled (3.3 MB binary).
- **`git-merge-changelog`** — the `[merge "merge-changelog"]` driver in gitconfig
  (used for `ChangeLog` files via `dotfiles/git/attributes`) calls this tool, which
  is **not** packaged in Fedora (it ships with gnulib). Without it, ChangeLog
  merges fall back to the default driver. Install manually if needed.
- **Dropped from the old-machine copy:**
  - `git-interpret-trailers` — `git interpret-trailers` is a built-in git command
    (`/usr/libexec/git-core`); the stray binary copy was redundant.
  - `~/.gitattributes` — an exact duplicate of `~/.config/git/attributes`, and git
    doesn't read `~/.gitattributes` by default. Only the canonical
    `~/.config/git/attributes` is kept.

## License

This repository is licensed under the GNU General Public License, version 3 or
later — see [LICENSE](LICENSE). The `bin/` scripts I wrote and `install.sh` carry
the GPLv3 license-grant header; the git config files (`gitconfig`, `attributes`,
`gitk`) are left unheadered.

`bin/git-wtf` is the one exception: it's a third-party script by William Morgan,
already distributed under GPLv3-or-later (it keeps its own `COPYRIGHT` notice). It
is license-compatible but not my work, so it does not carry the repo's header —
see the note at the top of that file.

## Open questions

- `git-prepare-commit-msg` is kept as a `~/bin` script. If it's meant to run as a
  git **hook** (its name matches the `prepare-commit-msg` hook), it may need wiring
  via `core.hooksPath` or a per-repo hook instead — revisit.
