#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source ./.env
  set +a
fi

: "${SUPABASE_DB_URL:?Set SUPABASE_DB_URL to the Supabase direct Postgres URI}"
: "${DIRECT_URL:?Set DIRECT_URL to the Neon direct Postgres URI}"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
dump_file="$work_dir/public.sql"

pg_dump "$SUPABASE_DB_URL" \
  --schema=public \
  --no-owner \
  --no-privileges \
  --format=plain \
  --file="$dump_file"

# Public tables may reference Firebase's auth.users. The auth schema is intentionally
# not migrated; the user ID columns remain UUID values and their FK constraints go.
perl -0pi -e \
  's/ALTER TABLE ONLY public\.[^;]+?ADD CONSTRAINT[^;]*REFERENCES auth\.users\(id\)[^;]*;\n//gs' \
  "$dump_file"

psql "$DIRECT_URL" \
  --set=ON_ERROR_STOP=1 \
  --file="$dump_file"

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
