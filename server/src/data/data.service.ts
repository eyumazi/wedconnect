import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma.service';

type DataRecord = Record<string, unknown> & {
  id: string;
  created_at: Date;
  updated_at: Date;
};

const asJson = (value: Record<string, unknown>): Prisma.InputJsonObject =>
  value as Prisma.InputJsonObject;

const serialize = (record: {
  id: string;
  data: Prisma.JsonValue;
  createdAt: Date;
  updatedAt: Date;
}): DataRecord => ({
  ...(record.data as Record<string, unknown>),
  id: record.id,
  created_at: record.createdAt,
  updated_at: record.updatedAt,
});

@Injectable()
export class DataService {
  constructor(private readonly prisma: PrismaService) {}

  async profiles(userId: string): Promise<DataRecord[]> {
    const profile = await this.prisma.profile.findUnique({ where: { userId } });
    return profile
      ? [
          {
            id: profile.id,
            user_id: profile.userId,
            first_name: profile.firstName,
            last_name: profile.lastName,
            photo_url: profile.photoUrl,
            created_at: profile.createdAt,
            updated_at: profile.updatedAt,
          },
        ]
      : [];
  }

  async upsertProfile(userId: string, data: Record<string, unknown>) {
    const profile = await this.prisma.profile.upsert({
      where: { userId },
      create: {
        userId,
        firstName: typeof data.first_name === 'string' ? data.first_name : null,
        lastName: typeof data.last_name === 'string' ? data.last_name : null,
        photoUrl: typeof data.photo_url === 'string' ? data.photo_url : null,
      },
      update: {
        firstName: typeof data.first_name === 'string' ? data.first_name : undefined,
        lastName: typeof data.last_name === 'string' ? data.last_name : undefined,
        photoUrl: typeof data.photo_url === 'string' ? data.photo_url : undefined,
      },
    });
    return profile;
  }

  async weddings(userId: string): Promise<DataRecord[]> {
    const rows = await this.prisma.wedding.findMany({ where: { userId } });
    return rows.map(serialize);
  }

  async createWedding(userId: string, data: Record<string, unknown>) {
    return serialize(
      await this.prisma.wedding.create({ data: { userId, data: asJson(data) } }),
    );
  }

  async guests(userId: string, weddingId: string): Promise<DataRecord[]> {
    await this.assertWeddingOwner(userId, weddingId);
    const rows = await this.prisma.guest.findMany({ where: { weddingId } });
    return rows.map(serialize);
  }

  async createGuest(userId: string, weddingId: string, data: Record<string, unknown>) {
    await this.assertWeddingOwner(userId, weddingId);
    return serialize(
      await this.prisma.guest.create({
        data: { weddingId, data: asJson(data) },
      }),
    );
  }

  async memories(userId: string, weddingId: string): Promise<DataRecord[]> {
    await this.assertWeddingOwner(userId, weddingId);
    const rows = await this.prisma.memory.findMany({ where: { weddingId } });
    return rows.map(serialize);
  }

  async createMemory(userId: string, weddingId: string, data: Record<string, unknown>) {
    await this.assertWeddingOwner(userId, weddingId);
    return serialize(
      await this.prisma.memory.create({
        data: { weddingId, data: asJson(data) },
      }),
    );
  }

  async deleteMemory(userId: string, weddingId: string, id: string): Promise<void> {
    await this.assertWeddingOwner(userId, weddingId);
    const deleted = await this.prisma.memory.deleteMany({
      where: { id, weddingId },
    });
    if (!deleted.count) throw new NotFoundException('Memory not found');
  }

  async wishes(userId: string, weddingId: string): Promise<DataRecord[]> {
    await this.assertWeddingOwner(userId, weddingId);
    const rows = await this.prisma.signBoardWish.findMany({ where: { weddingId } });
    return rows.map(serialize);
  }

  async createWish(userId: string, weddingId: string, data: Record<string, unknown>) {
    await this.assertWeddingOwner(userId, weddingId);
    return serialize(
      await this.prisma.signBoardWish.create({
        data: { weddingId, data: asJson(data) },
      }),
    );
  }

  async deleteWish(userId: string, weddingId: string, id: string): Promise<void> {
    await this.assertWeddingOwner(userId, weddingId);
    const deleted = await this.prisma.signBoardWish.deleteMany({
      where: { id, weddingId },
    });
    if (!deleted.count) throw new NotFoundException('Wish not found');
  }

  private async assertWeddingOwner(userId: string, weddingId: string): Promise<void> {
    const wedding = await this.prisma.wedding.findFirst({
      where: { id: weddingId, userId },
      select: { id: true },
    });
    if (!wedding) throw new ForbiddenException('Wedding access denied');
  }
}
