#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
server_dir="$(cd "$script_dir/.." && pwd)"
cd "$server_dir"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source ./.env
  set +a
fi

: "${SUPABASE_DB_URL:?Set SUPABASE_DB_URL to the Supabase direct Postgres URI}"
: "${DIRECT_URL:?Set DIRECT_URL to the Neon direct Postgres URI}"
SUPABASE_DB_URL="${SUPABASE_DB_URL//$'\r'/}"
DIRECT_URL="${DIRECT_URL//$'\r'/}"

for command_name in pg_dump psql perl; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    for postgres_bin in /c/Program\ Files/PostgreSQL/*/bin /mnt/c/Program\ Files/PostgreSQL/*/bin; do
      if [[ -x "$postgres_bin/$command_name.exe" ]]; then
        export PATH="$postgres_bin:$PATH"
        break
      fi
    done
  fi
  if [[ "$command_name" != "perl" ]] && ! command -v "$command_name" >/dev/null 2>&1 &&
    command -v "$command_name.exe" >/dev/null 2>&1; then
    ln -sf "$(command -v "$command_name.exe")" "$server_dir/$command_name"
    export PATH="$server_dir:$PATH"
  fi
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$command_name" >&2
    printf '%s\n' 'Install PostgreSQL client tools and restart Git Bash so pg_dump and psql are on PATH.' >&2
    exit 127
  fi
done

work_dir="$(mktemp -d -p "$server_dir")"
trap 'rm -rf "$work_dir"' EXIT
dump_file="$work_dir/public.sql"
dump_file_windows="$(wslpath -w "$dump_file" 2>/dev/null || printf '%s' "$dump_file")"

"$server_dir/pg_dump" "$SUPABASE_DB_URL" \
  --schema=public \
  --no-owner \
  --no-privileges \
  --format=plain \
  --file="$dump_file_windows"

# Public tables may reference Firebase's auth.users. The auth schema is intentionally
# not migrated; the user ID columns remain UUID values and their FK constraints go.
perl -0pi -e \
  's/CREATE SCHEMA public;\n//g; s/ALTER SCHEMA public[^;]*;\n//g; s/ALTER TABLE ONLY public\.[^;]+?ADD CONSTRAINT[^;]*REFERENCES auth\.users\(id\)[^;]*;\n//gs; s/CREATE POLICY[^;]*auth\.[^;]*;\n//gs' \
  "$dump_file"

"$server_dir/psql" "$DIRECT_URL" \
  --set=ON_ERROR_STOP=1 \
  --file="$dump_file_windows"

export DATABASE_URL="$DIRECT_URL"
npx prisma db pull --force
npx prisma migrate diff \
  --from-empty \
  --to-schema-datamodel prisma/schema.prisma \
  --script > "$work_dir/migration.sql"
mkdir -p prisma/migrations/0_init
cp "$work_dir/migration.sql" prisma/migrations/0_init/migration.sql
npx prisma migrate resolve --applied 0_init
npx prisma generate

printf '%s\n' 'Public schema migration completed. Auth schema was not migrated.'
