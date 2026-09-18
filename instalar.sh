#!/usr/bin/env bash
# Bootstrap público para instalar o núcleo privado sem colocar credenciais na URL ou nos logs.
set -euo pipefail

REPO_URL="${DESKCOMM_REPO_URL:-https://github.com/sysadmin-stack/DeskcommCRM.git}"
REPO_DIR="${DESKCOMM_REPO_DIR:-deskcommcrm}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/deskcomm"
CREDENTIAL_FILE="$CONFIG_DIR/github-readonly"
HELPER="$CONFIG_DIR/git-credential-deskcomm"

die() { printf '✖ %s\n' "$*" >&2; exit 1; }
command -v git >/dev/null 2>&1 || die "git não encontrado"
command -v docker >/dev/null 2>&1 || die "docker não encontrado"
[ ! -e "$REPO_DIR" ] || die "a pasta $REPO_DIR já existe; não vou sobrescrevê-la"

TTY_IN=""
if [ -r /dev/tty ] && { : < /dev/tty; } 2>/dev/null; then TTY_IN=/dev/tty; fi
usuario="${DESKCOMM_GITHUB_USER:-}"
token="${DESKCOMM_GITHUB_TOKEN:-}"

if [ -z "$usuario" ] || [ -z "$token" ]; then
  [ -n "$TTY_IN" ] || die "sem terminal: defina DESKCOMM_GITHUB_USER e DESKCOMM_GITHUB_TOKEN"
  printf 'Usuário técnico do GitHub: ' > "$TTY_IN"
  IFS= read -r usuario < "$TTY_IN"
  printf 'Token somente leitura (contents + packages): ' > "$TTY_IN"
  IFS= read -r -s token < "$TTY_IN"
  printf '\n' > "$TTY_IN"
fi

[ -n "$usuario" ] || die "usuário vazio"
[ -n "$token" ] || die "token vazio"
case "$usuario$token" in *$'\n'*|*$'\r'*) die "credencial contém quebra de linha";; esac

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"
umask 077
printf '%s\n%s\n' "$usuario" "$token" > "$CREDENTIAL_FILE"

cat > "$HELPER" <<'HELPER_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
[ "${1:-get}" = get ] || exit 0
arquivo="${XDG_CONFIG_HOME:-$HOME/.config}/deskcomm/github-readonly"
[ -r "$arquivo" ] || exit 1
{ IFS= read -r usuario; IFS= read -r token; } < "$arquivo"
printf 'username=%s\npassword=%s\n' "$usuario" "$token"
HELPER_SCRIPT
chmod 700 "$HELPER"

printf '%s' "$token" | docker login ghcr.io --username "$usuario" --password-stdin >/dev/null
git -c credential.helper="$HELPER" clone --depth 1 "$REPO_URL" "$REPO_DIR"
git -C "$REPO_DIR" config credential.helper "$HELPER"

unset token DESKCOMM_GITHUB_TOKEN
cd "$REPO_DIR"
exec bash hostgator-setup-kit/install.sh
