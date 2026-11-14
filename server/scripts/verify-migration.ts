import 'dotenv/config';
import {
  ListObjectsV2Command,
  S3Client,
} from '@aws-sdk/client-s3';
import { PrismaClient } from '@prisma/client';

const required = (name: string): string => {
  const value = process.env[name];
  if (!value) throw new Error(`Missing ${name}`);
  return value;
};

const sourceDb = new PrismaClient({
  datasources: { db: { url: required('SUPABASE_DB_URL') } },
});
const targetDb = new PrismaClient({
  datasources: { db: { url: required('DIRECT_URL') } },
});
const sourceStorage = new S3Client({
  endpoint: required('SUPABASE_S3_ENDPOINT'),
  region: 'us-east-1',
  forcePathStyle: true,
  credentials: {
    accessKeyId: required('SUPABASE_S3_ACCESS_KEY'),
    secretAccessKey: required('SUPABASE_S3_SECRET_KEY'),
  },
});
const targetStorage = new S3Client({
  endpoint: required('B2_ENDPOINT'),
  region: required('B2_REGION'),
  credentials: {
    accessKeyId: required('B2_ACCESS_KEY_ID'),
    secretAccessKey: required('B2_SECRET_ACCESS_KEY'),
  },
});

type TableCount = { table_name: string; row_count: bigint };
type ObjectSummary = { count: number; bytes: number };

async function tableCounts(client: PrismaClient): Promise<Map<string, bigint>> {
  const tables = await client.$queryRaw<Array<{ table_name: string }>>`
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ORDER BY table_name
  `;
  const counts = new Map<string, bigint>();
  for (const table of tables) {
    const identifier = `"${table.table_name.replace(/"/g, '""')}"`;
    const rows = await client.$queryRawUnsafe<TableCount[]>(
      `SELECT count(*)::bigint AS row_count FROM "public".${identifier}`,
    );
    counts.set(table.table_name, rows[0]?.row_count ?? 0n);
  }
  return counts;
}

async function objectSummary(
  client: S3Client,
  bucket: string,
  prefix = '',
): Promise<ObjectSummary> {
  let continuationToken: string | undefined;
  let count = 0;
  let bytes = 0;
  do {
    const page = await client.send(
      new ListObjectsV2Command({
        Bucket: bucket,
        Prefix: prefix,
        ContinuationToken: continuationToken,
      }),
    );
    for (const object of page.Contents ?? []) {
      count += 1;
      bytes += object.Size ?? 0;
    }
    continuationToken = page.IsTruncated
      ? page.NextContinuationToken
      : undefined;
  } while (continuationToken);
  return { count, bytes };
}

async function main(): Promise<void> {
  const [sourceTables, targetTables] = await Promise.all([
    tableCounts(sourceDb),
    tableCounts(targetDb),
  ]);
  let tablesMatch = true;
  console.log('TABLE_COUNTS');
  for (const table of [...sourceTables.keys()].sort()) {
    const source = sourceTables.get(table) ?? 0n;
    const target = targetTables.get(table) ?? 0n;
    const match = source === target;
    tablesMatch &&= match;
    console.log(`${table}: source=${source} target=${target} match=${match}`);
  }

  const sourceBucketNames = required('SUPABASE_STORAGE_BUCKETS')
    .split(',')
    .map((bucket) => bucket.trim())
    .filter(Boolean);
  const sourceBucket = (process.env.SUPABASE_S3_BUCKET ?? '').trim();
  const targetBucket = required('B2_BUCKET_NAME');
  let storageMatch = true;
  console.log('STORAGE_COUNTS');
  for (const bucket of sourceBucketNames) {
    const source = await objectSummary(
      sourceStorage,
      bucket || sourceBucket,
    );
    const target = await objectSummary(targetStorage, targetBucket, `${bucket}/`);
    const match = source.count === target.count && source.bytes === target.bytes;
    storageMatch &&= match;
    console.log(
      `${bucket}: source=${source.count}/${source.bytes} ` +
        `target=${target.count}/${target.bytes} match=${match}`,
    );
  }

  if (!tablesMatch || !storageMatch) {
    throw new Error('Migration verification failed; provider cutover is not safe');
  }
  console.log('Migration verification passed');
}

main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await Promise.all([sourceDb.$disconnect(), targetDb.$disconnect()]);
  });
