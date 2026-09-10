import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { CouplesModule } from './couples/couples.module';
import { ScheduleModule } from './schedule/schedule.module';
import { MemesModule } from './memes/memes.module';
import { RemindersModule } from './reminders/reminders.module';
import { DistanceModule } from './distance/distance.module';
import { DiaryModule } from './diary/diary.module';
import { MinigamesModule } from './minigames/minigames.module';
import { ThoughtsModule } from './thoughts/thoughts.module';
import { NotificationsModule } from './notifications/notifications.module';
import { GatewayModule } from './gateway/gateway.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]),
    PrismaModule,
    AuthModule,
    CouplesModule,
    ScheduleModule,
    MemesModule,
    RemindersModule,
    DistanceModule,
    DiaryModule,
    MinigamesModule,
    ThoughtsModule,
    NotificationsModule,
    GatewayModule,
  ],
})
export class AppModule {}
