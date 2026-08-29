import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { ThoughtsService } from './thoughts.service';
import { ThoughtsController } from './thoughts.controller';
import { GatewayModule } from '../gateway/gateway.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    BullModule.registerQueue({ name: 'thoughts' }),
    GatewayModule,
    NotificationsModule,
  ],
  providers: [ThoughtsService],
  controllers: [ThoughtsController],
  exports: [ThoughtsService],
})
export class ThoughtsModule {}
