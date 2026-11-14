import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { AccessTokenPayload } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DataDto } from './dto/data.dto';
import { DataService } from './data.service';

type AuthenticatedRequest = Request & { user: AccessTokenPayload };

@Controller()
@UseGuards(JwtAuthGuard)
export class DataController {
  constructor(private readonly data: DataService) {}

  @Get('profiles')
  profiles(@Req() req: AuthenticatedRequest) {
    return this.data.profiles(req.user.sub);
  }

  @Post('profiles')
  profile(@Req() req: AuthenticatedRequest, @Body() dto: DataDto) {
    return this.data.upsertProfile(req.user.sub, dto.data);
  }

  @Get('weddings')
  weddings(@Req() req: AuthenticatedRequest) {
    return this.data.weddings(req.user.sub);
  }

  @Post('weddings')
  wedding(@Req() req: AuthenticatedRequest, @Body() dto: DataDto) {
    return this.data.createWedding(req.user.sub, dto.data);
  }

  @Get('guests')
  guests(@Req() req: AuthenticatedRequest, @Query('weddingId') weddingId: string) {
    return this.data.guests(req.user.sub, weddingId);
  }

  @Post('guests')
  guest(@Req() req: AuthenticatedRequest, @Body() dto: DataDto) {
    return this.data.createGuest(req.user.sub, dto.weddingId!, dto.data);
  }

  @Get('memories')
  memories(@Req() req: AuthenticatedRequest, @Query('weddingId') weddingId: string) {
    return this.data.memories(req.user.sub, weddingId);
  }

  @Post('memories')
  memory(@Req() req: AuthenticatedRequest, @Body() dto: DataDto) {
    return this.data.createMemory(req.user.sub, dto.weddingId!, dto.data);
  }

  @Delete('memories/:id')
  async deleteMemory(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Query('weddingId') weddingId: string,
  ) {
    await this.data.deleteMemory(req.user.sub, weddingId, id);
    return { deleted: true };
  }

  @Get('sign-board-wishes')
  wishes(@Req() req: AuthenticatedRequest, @Query('weddingId') weddingId: string) {
    return this.data.wishes(req.user.sub, weddingId);
  }

  @Post('sign-board-wishes')
  wish(@Req() req: AuthenticatedRequest, @Body() dto: DataDto) {
    return this.data.createWish(req.user.sub, dto.weddingId!, dto.data);
  }

  @Delete('sign-board-wishes/:id')
  async deleteWish(
    @Req() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Query('weddingId') weddingId: string,
  ) {
    await this.data.deleteWish(req.user.sub, weddingId, id);
    return { deleted: true };
  }
}
