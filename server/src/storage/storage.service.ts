import { Injectable } from '@nestjs/common';
import {
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';

@Injectable()
export class StorageService {
  private readonly client: S3Client;
  private readonly bucket: string;
  private readonly publicUrl: string;

  constructor(config: ConfigService) {
    const endpoint = config.getOrThrow<string>('B2_ENDPOINT');
    this.bucket = config.getOrThrow<string>('B2_BUCKET_NAME');
    this.publicUrl = config.get<string>('B2_PUBLIC_URL', '').replace(/\/$/, '');
    this.client = new S3Client({
      endpoint,
      region: config.getOrThrow<string>('B2_REGION'),
      credentials: {
        accessKeyId: config.getOrThrow<string>('B2_ACCESS_KEY_ID'),
        secretAccessKey: config.getOrThrow<string>('B2_SECRET_ACCESS_KEY'),
      },
    });
  }

  async uploadFile(
    file: Express.Multer.File,
    folderPath: string,
  ): Promise<{ key: string; url: string }> {
    const folder = folderPath.replace(/^\/+|\/+$/g, '');
    const key = `${folder}/${randomUUID()}-${file.originalname.replace(/[^A-Za-z0-9._-]/g, '_')}`;
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: file.buffer,
        ContentType: file.mimetype,
      }),
    );
    return { key, url: this.publicUrl ? `${this.publicUrl}/${key}` : key };
  }

  getPresignedUploadUrl(key: string, contentType: string): Promise<string> {
    return getSignedUrl(
      this.client,
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        ContentType: contentType,
      }),
      { expiresIn: 900 },
    );
  }

  getPresignedDownloadUrl(key: string): Promise<string> {
    return getSignedUrl(
      this.client,
      new GetObjectCommand({ Bucket: this.bucket, Key: key }),
      { expiresIn: 900 },
    );
  }

  async deleteFile(key: string): Promise<void> {
    await this.client.send(
      new DeleteObjectCommand({ Bucket: this.bucket, Key: key }),
    );
  }
}
