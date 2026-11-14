import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import { User, UserStatus } from '@prisma/client';
import * as argon2 from 'argon2';
import { createHash, randomBytes } from 'node:crypto';
import { PrismaService } from '../prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { AccessTokenPayload, RefreshTokenPayload } from './auth.types';
import { PasswordPolicyService } from './password-policy.service';

const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_MINUTES = 15;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly passwordPolicy: PasswordPolicyService,
  ) {}

  async register(dto: RegisterDto): Promise<{ userId: string }> {
    const email = dto.email.trim().toLowerCase();
    await this.passwordPolicy.assertNotBreached(dto.password);
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('An account already exists');

    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash: await argon2.hash(dto.password, { type: argon2.argon2id }),
      },
    });
    await this.prisma.auditLog.create({
      data: { userId: user.id, action: 'user.registered', resource: 'user' },
    });
    return { userId: user.id };
  }

  async login(dto: LoginDto): Promise<Record<string, string>> {
    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({
      where: { email },
      include: { roles: { include: { role: { include: { permissions: { include: { permission: true } } } } } } },
    });
    if (!user || (user.lockedUntil && user.lockedUntil > new Date())) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const valid = await argon2.verify(user.passwordHash, dto.password);
    if (!valid) {
      const attempts = user.failedAttempts + 1;
      await this.prisma.user.update({
        where: { id: user.id },
        data: {
          failedAttempts: attempts >= MAX_FAILED_ATTEMPTS ? 0 : attempts,
          lockedUntil:
            attempts >= MAX_FAILED_ATTEMPTS
              ? new Date(Date.now() + LOCKOUT_MINUTES * 60_000)
              : null,
        },
      });
      throw new UnauthorizedException('Invalid credentials');
    }
    if (user.status === UserStatus.DISABLED) {
      throw new UnauthorizedException('Account unavailable');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { failedAttempts: 0, lockedUntil: null },
    });
    return this.issueTokens(user);
  }

  async refresh(rawToken: string): Promise<Record<string, string>> {
    let payload: RefreshTokenPayload;
    try {
      payload = await this.jwt.verifyAsync<RefreshTokenPayload>(rawToken, {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const stored = await this.prisma.refreshToken.findUnique({
      where: { id: payload.jti },
      include: { user: { include: { roles: { include: { role: { include: { permissions: { include: { permission: true } } } } } } } } },
    });
    if (!stored || stored.revokedAt || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token revoked');
    }
    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revokedAt: new Date() },
    });
    return this.issueTokens(stored.user);
  }

  async revokeAll(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  private async issueTokens(
    user: User & {
      roles?: Array<{
        role: {
          name: string;
          permissions: Array<{ permission: { name: string } }>;
        };
      }>;
    },
  ): Promise<Record<string, string>> {
    const roles = user.roles?.map(({ role }) => role.name) ?? [];
    const permissions =
      user.roles?.flatMap(({ role }) =>
        role.permissions.map(({ permission }) => permission.name),
      ) ?? [];
    const accessPayload: AccessTokenPayload = {
      sub: user.id,
      email: user.email,
      roles,
      permissions,
      type: 'access',
    };
    const accessTokenTtl = this.config.get<string>(
      'ACCESS_TOKEN_TTL',
      '10m',
    ) as JwtSignOptions['expiresIn'];
    const accessToken = await this.jwt.signAsync(accessPayload, {
      secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
      expiresIn: accessTokenTtl,
    });
    const tokenId = randomBytes(16).toString('hex');
    const refreshPayload: RefreshTokenPayload = {
      sub: user.id,
      jti: tokenId,
      type: 'refresh',
    };
    const refreshToken = await this.jwt.signAsync(refreshPayload, {
      secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      expiresIn: `${this.config.get<number>('REFRESH_TOKEN_TTL_DAYS', 30)}d` as JwtSignOptions['expiresIn'],
    });
    await this.prisma.refreshToken.create({
      data: {
        id: tokenId,
        userId: user.id,
        tokenHash: createHash('sha256').update(refreshToken).digest('hex'),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60_000),
      },
    });
    return { accessToken, refreshToken };
  }
}
