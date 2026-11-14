import { IsObject, IsOptional, IsUUID } from 'class-validator';

export class DataDto {
  @IsObject()
  data!: Record<string, unknown>;

  @IsOptional()
  @IsUUID()
  weddingId?: string;
}
