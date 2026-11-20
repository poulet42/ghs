# ghs: switch SSH key + gh account. Source this file from ~/.zshrc or ~/.bashrc.
# Profiles: ${GHS_CONFIG:-~/.config/ghs/profiles}, one per line: <name> <ssh-key-path> <gh-user>

_ghs_readkey() {
  local k rest
  k=$(dd bs=1 count=1 2>/dev/null </dev/tty)
  if [ "$k" = $'\033' ]; then
    rest=$(dd bs=1 count=2 2>/dev/null </dev/tty)
    k="$k$rest"
  fi
  printf '%s' "$k"
}

_ghs_draw() {
  # $1 items, $2 cursor, $3 selected indices (" 1 3 "), $4 mode
  local i=0 line ptr mark
  printf '%s\n' "$1" | while IFS= read -r line; do
    i=$((i + 1))
    ptr=" "; [ "$i" -eq "$2" ] && ptr=$'\033[36m❯\033[0m'
    if [ "$4" = multi ]; then
      case "$3" in
        *" $i "*) mark=$'\033[32m◉\033[0m'; line=$'\033[32m'"$line"$'\033[0m' ;;
        *) mark=$'\033[2m○\033[0m' ;;
      esac
      printf '\033[2K  %s %s %s\n' "$ptr" "$mark" "$line"
    else
      [ "$i" -eq "$2" ] && line=$'\033[36m'"$line"$'\033[0m'
      printf '\033[2K  %s %s\n' "$ptr" "$line"
    fi
  done
}

# _ghs_menu <multi|one> <title> <items> [start-index]; UI on stderr, result on stdout
_ghs_menu() {
  local mode="$1" title="$2" items="$3" cur="${4:-1}" sel=" " n old k i out="" hint
  n=$(printf '%s\n' "$items" | wc -l | tr -d ' ')
  old=$(stty -g </dev/tty)
  stty -icanon -echo -isig </dev/tty
  hint='↑/↓ move · enter confirm · q cancel'
  [ "$mode" = multi ] && hint='↑/↓ move · space toggle · a all · enter confirm · q cancel'
  {
    printf '\033[?25l\n\033[1;36m%s\033[0m\n\033[2m%s\033[0m\n' "$title" "$hint"
    _ghs_draw "$items" "$cur" "$sel" "$mode"
  } >&2
  while :; do
    k=$(_ghs_readkey)
    case "$k" in
      $'\033[A' | k) [ "$cur" -gt 1 ] && cur=$((cur - 1)) ;;
      $'\033[B' | j) [ "$cur" -lt "$n" ] && cur=$((cur + 1)) ;;
      " ")
        if [ "$mode" = multi ]; then
          case "$sel" in *" $cur "*) sel="${sel/ $cur / }" ;; *) sel="$sel$cur " ;; esac
        fi ;;
      a)
        if [ "$mode" = multi ]; then
          sel=" "; i=1; while [ "$i" -le "$n" ]; do sel="$sel$i "; i=$((i + 1)); done
        fi ;;
      q | $'\003') out="__cancel__"; break ;;
      "") break ;;
    esac
    printf '\033[%sA' "$n" >&2
    _ghs_draw "$items" "$cur" "$sel" "$mode" >&2
  done
  printf '\033[%sA\033[J\033[?25h' "$((n + 3))" >&2
  stty "$old" </dev/tty
  [ "$out" = "__cancel__" ] && return 1
  if [ "$mode" = multi ]; then
    printf '%s' "$sel" | tr ' ' '\n' | grep . | sort -n | while read -r i; do
      printf '%s\n' "$items" | sed -n "${i}p"
    done
  else
    printf '%s\n' "$items" | sed -n "${cur}p"
  fi
}

_ghs_init() {
  local cfg="${GHS_CONFIG:-$HOME/.config/ghs/profiles}" keys users picked user key name f idx used
  [ -t 0 ] || { echo "ghs: init needs a terminal" >&2; return 1; }
  users=$(gh auth status 2>&1 | sed -n 's/.*account \([^ ]*\).*/\1/p' | sort -u)
  [ -n "$users" ] || { echo "ghs: no gh accounts. Run 'gh auth login' for each account first." >&2; return 1; }
  keys=$(for f in "$HOME"/.ssh/*.pub; do [ -f "${f%.pub}" ] && printf '%s\n' "${f%.pub}"; done)

  picked=$(_ghs_menu multi "GitHub accounts to manage" "$users") || { echo "ghs: cancelled" >&2; return 1; }
  [ -n "$picked" ] || { echo "ghs: nothing selected" >&2; return 1; }
  mkdir -p "$(dirname "$cfg")"
  used=" "

  while IFS= read -r user; do
    if [ -f "$cfg" ] && awk -v u="$user" '$3==u{f=1} END{exit !f}' "$cfg"; then
      printf '\033[33m!\033[0m %s already configured, skipped\n' "$user" >&2
      continue
    fi
    idx=1
    while IFS= read -r key; do
      case "$used" in *" $key "*) idx=$((idx + 1)) ;; *) break ;; esac
    done < <(printf '%s\n' "$keys")
    key=$(_ghs_menu one "SSH key for $user" "$keys" "$idx") || { echo "ghs: cancelled" >&2; return 1; }
    printf 'Profile name for %s [%s]: ' "$user" "$user" >&2
    read -r name </dev/tty
    name="${name:-$user}"
    printf '%s %s %s\n' "$name" "$key" "$user" >> "$cfg"
    used="$used$key "
    printf '\033[32m✔\033[0m %s → %s (%s)\n' "$name" "$key" "$user" >&2
  done < <(printf '%s\n' "$picked")
  printf '\n\033[2mSaved to %s. Try: ghs list\033[0m\n' "$cfg" >&2
}

_ghs_switch() {
  local cfg="${GHS_CONFIG:-$HOME/.config/ghs/profiles}" active name key user
  gh auth switch || return $?
  active=$(gh auth status 2>&1 | awk '/account /{a=$0; sub(/.*account /,"",a); sub(/ .*/,"",a)} /Active account: true/{print a; exit}')
  while read -r name key user; do
    [ "$user" = "$active" ] || continue
    key="${key/#\~/$HOME}"
    export GIT_SSH_COMMAND="ssh -i $key -o IdentitiesOnly=yes"
    echo "ghs: $name (ssh $key, gh $user)"
    return 0
  done < <(grep -vE '^\s*(#|$)' "$cfg" 2>/dev/null)
  echo "ghs: no profile for gh account '$active'; SSH key unchanged (ghs init)" >&2
  return 1
}

ghs() {
  [ "${1:-}" = switch ] && { _ghs_switch; return $?; }
  [ "${1:-}" = init ] && { _ghs_init; return $?; }
  local cfg="${GHS_CONFIG:-$HOME/.config/ghs/profiles}"
  if [ ! -f "$cfg" ]; then
    echo "ghs: no config at $cfg. Run: ghs init" >&2
    return 1
  fi

  local name key user
  case "${1:-}" in
    "" | list | -l)
      while read -r name key user; do
        case "$name" in "" | \#*) continue ;; esac
        printf '%s\t%s\t%s\n' "$name" "$key" "$user"
      done < "$cfg"
      return 0
      ;;
  esac

  while read -r name key user; do
    [ "$name" = "$1" ] || continue
    key="${key/#\~/$HOME}"
    [ -f "$key" ] || { echo "ghs: key not found: $key" >&2; return 1; }
    export GIT_SSH_COMMAND="ssh -i $key -o IdentitiesOnly=yes"
    gh auth switch --user "$user" >/dev/null 2>&1 && echo "ghs: $name (ssh $key, gh $user)"
    return $?
  done < <(grep -vE '^\s*(#|$)' "$cfg")

  echo "ghs: unknown profile '$1' (try: ghs list)" >&2
  return 1
}
