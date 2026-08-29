import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  async onModuleInit() {
    let retries = 10;
    while (retries > 0) {
      try {
        await this.$connect();
        this.logger.log('Database connected');
        return;
      } catch (err) {
        retries--;
        this.logger.warn(`DB not ready, retrying... (${retries} left)`);
        await new Promise(r => setTimeout(r, 3000));
      }
    }
    throw new Error('Could not connect to database after retries');
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
