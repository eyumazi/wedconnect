import {
  Body,
  Controller,
  Delete,
  Param,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { IsString, Matches } from 'class-validator';
import { StorageService } from './storage.service';

class PresignedUploadDto {
  @IsString()
  @Matches(/^[A-Za-z0-9._/-]+$/)
  key!: string;

  @IsString()
  contentType!: string;
}

@Controller('storage')
export class StorageController {
  constructor(private readonly storage: StorageService) {}

  @Post('upload/:folder')
  @UseInterceptors(FileInterceptor('file'))
  upload(
    @UploadedFile() file: Express.Multer.File,
    @Param('folder') folder: string,
  ) {
    if (!file) throw new Error('A file is required');
    return this.storage.uploadFile(file, folder);
  }

  @Post('presigned-upload')
  presignedUpload(@Body() dto: PresignedUploadDto) {
    return this.storage
      .getPresignedUploadUrl(dto.key, dto.contentType)
      .then((url) => ({ url, key: dto.key }));
  }

  @Post('presigned-download/:key(*)')
  presignedDownload(@Param('key') key: string) {
    return this.storage
      .getPresignedDownloadUrl(key)
      .then((url) => ({ url, key }));
  }

  @Delete(':key(*)')
  async delete(@Param('key') key: string): Promise<{ deleted: true }> {
    await this.storage.deleteFile(key);
    return { deleted: true };
  }
}
