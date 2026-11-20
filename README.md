# ghs

Switch your SSH key and `gh` account together, in one command. For people with
several GitHub accounts (work + personal) on one machine.

```
$ ghs personal
ghs: personal (ssh ~/.ssh/id_personal, gh my-personal-login)
```

It sets `GIT_SSH_COMMAND` for the current shell and runs `gh auth switch`.

## Install

Requires `git`, [`gh`](https://cli.github.com), zsh or bash.

```sh
curl -fsSL https://raw.githubusercontent.com/poulet42/ghs/main/install.sh | sh
```

Then restart your shell and run the guided setup:

```sh
ghs init
```

Log in each account first with `gh auth login`.

<details>
<summary>Manual install</summary>

```sh
git clone https://github.com/poulet42/ghs ~/.ghs
echo 'source ~/.ghs/ghs.sh' >> ~/.zshrc   # or ~/.bashrc
```
</details>

## Usage

| Command | Does |
| --- | --- |
| `ghs init` | Guided setup: pick `gh` accounts (checkboxes), pick an SSH key for each |
| `ghs <name>` | Switch to a profile |
| `ghs switch` | Same as `gh auth switch` (toggles with two accounts, prompts with more), then applies that account's SSH key |
| `ghs list` | Show profiles |

## Config

`~/.config/ghs/profiles` (override with `GHS_CONFIG`), one profile per line:

```
# name  ssh-key              gh-user
work     ~/.ssh/id_work       my-work-login
personal ~/.ssh/id_personal   my-personal-login
```

## Notes

- The switch only affects the current shell; new terminals use your normal `~/.ssh/config`.
- Update: `git -C ~/.ghs pull`.
- Uninstall: delete `~/.ghs`, the `source` line in your rc file, and `~/.config/ghs`.

MIT
