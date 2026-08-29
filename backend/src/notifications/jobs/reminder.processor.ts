import { Process, Processor } from '@nestjs/bull';
import { Job } from 'bull';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications.service';

@Processor('reminders')
export class ReminderProcessor {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  @Process('send-reminder')
  async handleReminder(job: Job<{ reminderId: string }>) {
    const reminder = await this.prisma.reminder.findUnique({
      where: { id: job.data.reminderId },
      include: { couple: { include: { members: { select: { id: true, name: true } } } } },
    });

    if (!reminder || reminder.isCompleted) return;

    const creator = reminder.couple.members.find((m) => m.id === reminder.createdBy);
    const partner = reminder.couple.members.find((m) => m.id !== reminder.createdBy);

    const targets: string[] = [];
    if (reminder.targetUser === 'SELF' || reminder.targetUser === 'BOTH') {
      targets.push(reminder.createdBy);
    }
    if ((reminder.targetUser === 'PARTNER' || reminder.targetUser === 'BOTH') && partner) {
      targets.push(partner.id);
    }

    for (const userId of targets) {
      const isSelf = userId === reminder.createdBy;
      await this.notifications.sendToUser(userId, {
        title: isSelf ? '⏰ Recordatorio' : `💑 ${creator?.name} te recuerda`,
        body: reminder.title,
        route: '/reminders',
        entityId: reminder.id,
      });
    }

    if (reminder.recurrence !== 'NONE') {
      // Re-schedule for next occurrence (handled by service on next request if needed)
    }
  }
}
