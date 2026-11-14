import 'dotenv/config';
import {
  GetObjectCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { PrismaClient } from '@prisma/client';

const required = (name: string): string => {
  const value = process.env[name];
  if (!value) throw new Error(`Missing ${name}`);
  return value;
};

const source = new S3Client({
  endpoint: required('SUPABASE_S3_ENDPOINT'),
  region: 'us-east-1',
  forcePathStyle: true,
  requestHandler: { requestTimeout: 60_000 },
  credentials: {
    accessKeyId: required('SUPABASE_S3_ACCESS_KEY'),
    secretAccessKey: required('SUPABASE_S3_SECRET_KEY'),
  },
});
const target = new S3Client({
  endpoint: required('B2_ENDPOINT'),
  region: required('B2_REGION'),
  requestHandler: { requestTimeout: 60_000 },
  credentials: {
    accessKeyId: required('B2_ACCESS_KEY_ID'),
    secretAccessKey: required('B2_SECRET_ACCESS_KEY'),
  },
});

const buckets = required('SUPABASE_STORAGE_BUCKETS')
  .split(',')
  .map((bucket) => bucket.trim())
  .filter(Boolean);
const targetBucket = required('B2_BUCKET_NAME');
const publicUrl = (process.env.B2_PUBLIC_URL ?? '').replace(/\/$/, '');
const projectRef = required('SUPABASE_PROJECT_REF');

const prisma = new PrismaClient({
  datasources: { db: { url: required('DIRECT_URL') } },
});

async function copyBucket(bucket: string): Promise<void> {
  let continuationToken: string | undefined;
  do {
    const listed = await source.send(
      new ListObjectsV2Command({
        Bucket: bucket,
        ContinuationToken: continuationToken,
      }),
    );
    for (const object of listed.Contents ?? []) {
      if (!object.Key) continue;
      const downloaded = await source.send(
        new GetObjectCommand({ Bucket: bucket, Key: object.Key }),
      );
      if (!downloaded.Body) throw new Error(`Empty source object: ${object.Key}`);
      const targetKey = `${bucket}/${object.Key}`;
      await target.send(
        new PutObjectCommand({
          Bucket: targetBucket,
          Key: targetKey,
          Body: await downloaded.Body.transformToByteArray(),
          ContentType: downloaded.ContentType ?? 'application/octet-stream',
        }),
      );
      console.log(`Copied ${bucket}/${object.Key}`);
    }
    continuationToken = listed.IsTruncated
      ? listed.NextContinuationToken
      : undefined;
  } while (continuationToken);
}

async function rewritePublicUrls(): Promise<void> {
  if (!publicUrl) {
    console.warn('B2_PUBLIC_URL is empty; copied objects will keep their source URLs');
    return;
  }
  const columns = await prisma.$queryRaw<
    Array<{ table_name: string; column_name: string }>
  >`SELECT table_name, column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND data_type IN ('text', 'character varying')`;

  for (const column of columns) {
    const table = `"public"."${column.table_name.replace(/"/g, '""')}"`;
    const field = `"${column.column_name.replace(/"/g, '""')}"`;
    for (const bucket of buckets) {
      const oldBase = `https://${projectRef}.supabase.co/storage/v1/object/public/${bucket}/`;
      await prisma.$executeRawUnsafe(
        `UPDATE ${table} SET ${field} = replace(${field}, $1, $2) WHERE ${field} LIKE $3`,
        oldBase,
        `${publicUrl}/${bucket}/`,
        `%${oldBase}%`,
      );
    }
  }
}

async function main(): Promise<void> {
  for (const bucket of buckets) await copyBucket(bucket);
  await rewritePublicUrls();
}

main()
  .catch((error: unknown) => {
    console.error('Storage migration failed', error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
