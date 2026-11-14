import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { createHash } from 'node:crypto';

@Injectable()
export class PasswordPolicyService {
  async assertNotBreached(password: string): Promise<void> {
    const hash = createHash('sha1').update(password).digest('hex').toUpperCase();
    try {
      const response = await fetch(
        `https://api.pwnedpasswords.com/range/${hash.slice(0, 5)}`,
        { headers: { 'Add-Padding': 'true', 'User-Agent': 'WedConnect/1.0' } },
      );
      if (!response.ok) {
        throw new Error(`Password breach service returned ${response.status}`);
      }
      const suffix = hash.slice(5);
      const matches = (await response.text())
        .split(/\r?\n/)
        .some((line) => line.split(':')[0]?.trim() === suffix);
      if (matches) {
        throw new BadRequestException('Choose a password not found in breach data');
      }
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new ServiceUnavailableException('Password security check unavailable');
    }
  }
}
