# WedConnect API

This is the NestJS replacement backend for the Flutter application.

## Stack

- NestJS and TypeScript
- Neon-hosted PostgreSQL through Prisma 6
- Cloudflare R2 for object storage (R2 credentials are server-only)
- Argon2id password hashing
- Short-lived JWT access tokens and one-time rotated refresh tokens

## Local setup

1. Copy `.env.example` to `.env`; use a development Neon database and random secrets.
2. Install dependencies with `npm install`.
3. Generate the Prisma client: `npx prisma generate`.
4. Apply migrations after reviewing the schema: `npx prisma migrate dev --name initial`.
5. Start the API with `npm run start:dev`.

The API is served under `/api`. Never put `DATABASE_URL`, JWT secrets, or R2 secret keys in the Flutter app.

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
