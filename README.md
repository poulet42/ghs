# ghs

Switch your SSH key and `gh` account together, in one command. For people with
several GitHub accounts (work + personal) on one machine.

```
$ ghs switch --user my-personal-login
✓ Switched active account for github.com to my-personal-login
ghs: my-personal-login (ssh ~/.ssh/id_personal)
```

It runs `gh auth switch` (same flags, same rotation) and sets `GIT_SSH_COMMAND` for the current shell to the key mapped to the account that became active.

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
| `ghs switch` | Same as `gh auth switch` (toggles with two accounts, prompts with more), then applies that account's SSH key |
| `ghs switch -u <login>` | Switch to a given account, like `gh auth switch --user` |
| `ghs status` | Show accounts and keys, `*` marks the active one |

## Config

`~/.config/ghs/profiles` (override with `GHS_CONFIG`), one account per line:

```
# gh-user              ssh-key
my-work-login          ~/.ssh/id_work
my-personal-login      ~/.ssh/id_personal
```

## Notes

- The switch only affects the current shell; new terminals use your normal `~/.ssh/config`.
- Update: `git -C ~/.ghs pull`.
- Uninstall: delete `~/.ghs`, the `source` line in your rc file, and `~/.config/ghs`.

MIT
