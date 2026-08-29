import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { RemindersService } from './reminders.service';
import { RemindersController } from './reminders.controller';
import { GatewayModule } from '../gateway/gateway.module';

@Module({
  imports: [
    BullModule.registerQueue({ name: 'reminders' }),
    GatewayModule,
  ],
  providers: [RemindersService],
  controllers: [RemindersController],
})
export class RemindersModule {}
