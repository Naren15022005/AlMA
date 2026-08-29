import { Module, forwardRef } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { NotificationsService } from './notifications.service';
import { ReminderProcessor } from './jobs/reminder.processor';
import { ThoughtProcessor } from './jobs/thought.processor';
import { ThoughtsModule } from '../thoughts/thoughts.module';

@Module({
  imports: [
    BullModule.registerQueue({ name: 'reminders' }),
    BullModule.registerQueue({ name: 'thoughts' }),
    forwardRef(() => ThoughtsModule),
  ],
  providers: [NotificationsService, ReminderProcessor, ThoughtProcessor],
  exports: [NotificationsService],
})
export class NotificationsModule {}
