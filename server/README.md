# WedConnect API

This is the NestJS replacement backend for the Flutter application.

## Stack

- NestJS and TypeScript
- Neon-hosted PostgreSQL through Prisma 6
- Backblaze B2 S3-compatible object storage (B2 credentials are server-only)
- Argon2id password hashing
- Short-lived JWT access tokens and one-time rotated refresh tokens

## Local setup

1. Copy `.env.example` to `.env`; use a development Neon database and random secrets.
2. Install dependencies with `npm install`.
3. Generate the Prisma client: `npx prisma generate`.
4. Apply migrations after reviewing the schema: `npx prisma migrate dev --name initial`.
5. Start the API with `npm run start:dev`.

The API is served under `/api`. Never put `DATABASE_URL`, JWT secrets, or R2 secret keys in the Flutter app.

## Migration variables

- `SUPABASE_DB_URL`: Supabase Dashboard > **Connect** > direct Postgres URI. This is
  only used as the source by `scripts/migrate-db.sh`.
- `DATABASE_URL`: Neon Dashboard > **Connect** > pooled connection string.
- `DIRECT_URL`: Neon Dashboard > **Connect** > direct connection string.
- `SUPABASE_PROJECT_REF`: the project reference in the Supabase project URL.
- `SUPABASE_S3_ENDPOINT`, `SUPABASE_S3_ACCESS_KEY`, and
  `SUPABASE_S3_SECRET_KEY`: Supabase Dashboard > **Storage** > S3 connection
  details. These are source credentials and must never be committed.
- `B2_ENDPOINT` and `B2_REGION`: Backblaze B2 bucket details. The endpoint looks
  like `https://s3.<region>.backblazeb2.com`.
- `B2_ACCESS_KEY_ID` and `B2_SECRET_ACCESS_KEY`: a Backblaze application key
  restricted to the target bucket with read/write permissions. Do not use the
  master application key.
- `B2_BUCKET_NAME`: the target bucket created in Backblaze B2.
- `B2_PUBLIC_URL`: a B2 public/custom-domain URL without a trailing slash, or
  leave it empty when all downloads are private and presigned.

On Windows, `migrate-db.sh` must be run from Git Bash/WSL with PostgreSQL
client tools installed and available on `PATH` (`pg_dump`, `psql`, and `perl`).
The script fails before touching either database if a tool is missing. Run it
only after reviewing its dump and confirming a Neon backup. Run
`npm run migrate:storage` only after the database import and B2 bucket are
ready. Neither command creates sample data.

## Security boundary

Registration requires a 12-character password with mixed character classes and a breach check using the Have I Been Pwned k-anonymity API. Login uses Argon2id, locks after five failed attempts for 15 minutes, and revokes refresh-token families on rotation. Helmet, strict DTO validation, and a 10 requests/minute global limiter are enabled.

`JwtAuthGuard`, `RolesGuard`, and the `@Roles()` decorator are reusable for protected feature modules. MFA enrollment, email/phone verification, CAPTCHA, recovery identity verification, and approval workflows must be completed before production release; their schema primitives are included so they can be added without another identity provider.

## Migration order

1. Export Supabase tables and storage object manifests without exposing secrets.
2. Map the export into the Prisma models and verify row/object counts.
3. Import into a staging Neon database and R2 bucket.
4. Add protected feature endpoints and migrate Flutter calls behind one API client.
5. Run authentication, authorization, import reconciliation, and security tests.
6. Cut over production only after a rollback export and token/session invalidation plan are approved.
