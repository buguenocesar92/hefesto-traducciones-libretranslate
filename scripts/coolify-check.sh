#!/usr/bin/env bash
# Verifica que un compose cumple el contrato Coolify del MVP Hefesto.
# Uso: scripts/coolify-check.sh [ruta/al/compose.yaml]
#
# 1. Genera un .env temporal con valores ficticios no secretos para cada
#    ${VAR} requerida en el compose. Las de host o URL reciben
#    https://ejemplo.invalid; DB_NAME mvp_prueba y DB_SSLMODE disable.
# 2. Renderiza el compose con `docker compose config --format json`.
# 3. Con jq comprueba en los servicios sin profiles que no haya puertos,
#    container_name, privileged, cap_add, devices, network_mode/pid/ipc
#    host, security_opt unconfined, bind a /var/run/docker.sock ni bind
#    fuera del repo.
# 4. Comprueba en el YAML original que no haya 'name:' raíz ni 'name:'
#    dentro de las secciones volumes: o networks:.
# 5. Si el compose declara DB_NAME/DB_SSLMODE, valida que en el render
#    aparezcan mvp_prueba y disable (apps supabase-pg).
#
# Acumula TODOS los hallazgos y los imprime juntos. Sale con 0 si todo
# OK, 1 si hay hallazgos y 2 si el uso es incorrecto.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_COMPOSE="$SCRIPT_DIR/../compose.yaml"

if [[ $# -gt 1 ]]; then
  printf 'Uso: %s [ruta/al/compose.yaml]\n' "$0" >&2
  exit 2
fi

if [[ -n "${1:-}" ]]; then
  COMPOSE="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
else
  COMPOSE="$DEFAULT_COMPOSE"
fi

if [[ ! -f "$COMPOSE" ]]; then
  printf 'ERROR: compose no encontrado: %s\n' "$COMPOSE" >&2
  exit 1
fi

BASE_DIR="$(cd "$(dirname "$COMPOSE")" && pwd)"

# ---------- 1. Generar .env temporal con valores ficticios ----------
TMP_ENV="$(mktemp -t coolify-check-env-XXXXXX)"
RENDER="${TMP_ENV}.render.json"
RENDER_ERR="${TMP_ENV}.render.err"
FILTER="${TMP_ENV}.filter.jq"
trap 'rm -f "$TMP_ENV" "$RENDER" "$RENDER_ERR" "$FILTER"' EXIT

cat > "$FILTER" <<'JQ'
def check_bind($src; $base):
  if $src == "/var/run/docker.sock" then
    "bind a /var/run/docker.sock"
  elif ($src | startswith("/")) and (($base + "/") | . as $p | ($src | startswith($p) | not)) then
    "bind fuera del repo: \($src)"
  else empty end;

def check_service($name; $svc; $base):
  [
    (if ($svc.ports // null) and (($svc.ports | length) > 0) then "expone ports (\($svc.ports | tojson))" else empty end),
    (if $svc.container_name then "container_name fijo (\($svc.container_name))" else empty end),
    (if $svc.privileged == true then "privileged" else empty end),
    (if ($svc.cap_add // []) | length > 0 then "cap_add (\($svc.cap_add | join(",")))" else empty end),
    (if ($svc.devices // []) | length > 0 then "devices (\($svc.devices | tojson))" else empty end),
    (if $svc.network_mode == "host" then "network_mode host" else empty end),
    (if $svc.pid == "host" then "pid host" else empty end),
    (if $svc.ipc == "host" then "ipc host" else empty end),
    (if ($svc.security_opt // []) | index("unconfined") != null then "security_opt unconfined" else empty end),
    ([$svc.volumes // [] | .[] | select(.type == "bind") | .source | check_bind(.; $base)])
  ] | flatten;

. as $root |
[
  (
    [($root.services // {} | to_entries[]
      | select((.value.profiles // null) == null)
      | . as $e
      | check_service($e.key; $e.value; $base) as $errs
      | select(($errs | length) > 0)
      | $errs | map("\($e.key): \(.)"))]
    | flatten
  )
] | flatten | if length == 0 then empty else .[] end
JQ

mapfile -t VARS < <(grep -oE '\$\{?[A-Za-z_][A-Za-z0-9_]*\}?' "$COMPOSE" \
  | sed -E 's/^\$\{?//; s/\}?$//' | sort -u)

for v in "${VARS[@]}"; do
  case "$v" in
    DB_NAME)          val=mvp_prueba ;;
    DB_SSLMODE)       val=disable ;;
    *URL|*HOST|*ENDPOINT|*DOMAIN|*_ADDR) val=https://ejemplo.invalid ;;
    *)                val=x1234567890 ;;
  esac
  printf '%s=%s\n' "$v" "$val" >> "$TMP_ENV"
done

# ---------- 2. Renderizar el compose ----------
RENDER_OK=1
if ! docker compose --project-directory "$BASE_DIR" -f "$COMPOSE" \
     --env-file "$TMP_ENV" config --format json > "$RENDER" 2>"$RENDER_ERR"; then
  RENDER_OK=0
fi

# Acumular hallazgos
ERRORS=""

if [[ "$RENDER_OK" -ne 1 ]]; then
  ERRORS+="compose: el compose no se renderiza"$'\n'
  while IFS= read -r line; do
    ERRORS+="  ${line}"$'\n'
  done < "$RENDER_ERR"
fi

# ---------- 3. Validar servicios sin profiles con jq ----------
if [[ "$RENDER_OK" -eq 1 ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    ERRORS+="${line}"$'\n'
  done < <(jq -r --arg base "$BASE_DIR" -f "$FILTER" "$RENDER")
fi

# ---------- 4. Validar nombres fijos en el YAML original ----------
if grep -qE '^name:' "$COMPOSE"; then
  ERRORS+="compose: \"name:\" raíz fijo ($(grep -E '^name:' "$COMPOSE" | head -1 | sed -E 's/^name:[[:space:]]*//'))"$'\n'
fi

if sed -n '/^volumes:/,/^[a-zA-Z0-9]/{p;}' "$COMPOSE" \
     | grep -qE '^[[:space:]]+name:'; then
  ERRORS+="compose: volumen con \"name:\" fijo en ${COMPOSE}"$'\n'
fi

if sed -n '/^networks:/,/^[a-zA-Z0-9]/{p;}' "$COMPOSE" \
     | grep -qE '^[[:space:]]+name:'; then
  ERRORS+="compose: network con \"name:\" fijo en ${COMPOSE}"$'\n'
fi

# ---------- 5. Validar DB_NAME/DB_SSLMODE si la app es supabase-pg ----------
if grep -qE '^[[:space:]]+(DB_NAME|DB_SSLMODE):' "$COMPOSE"; then
  if ! grep -q '^DB_NAME=mvp_prueba$' "$TMP_ENV"; then
    ERRORS+="compose: app supabase-pg sin DB_NAME=mvp_prueba"$'\n'
  fi
  if ! grep -q '^DB_SSLMODE=disable$' "$TMP_ENV"; then
    ERRORS+="compose: app supabase-pg sin DB_SSLMODE=disable"$'\n'
  fi
  if [[ "$RENDER_OK" -eq 1 ]]; then
    if ! grep -q 'mvp_prueba' "$RENDER"; then
      ERRORS+="compose: mvp_prueba no aparece en el render"$'\n'
    fi
    if ! grep -q 'disable' "$RENDER"; then
      ERRORS+="compose: disable no aparece en el render"$'\n'
    fi
  fi
fi

# ---------- Resultado ----------
if [[ -n "$ERRORS" ]]; then
  printf 'servicio: motivo\n' >&2
  printf '%s' "$ERRORS" >&2
  exit 1
fi

printf 'OK: %s cumple el contrato Coolify\n' "$COMPOSE"