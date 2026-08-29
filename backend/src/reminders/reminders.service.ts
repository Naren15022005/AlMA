import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../gateway/events.gateway';
import { CreateReminderDto } from './dto/create-reminder.dto';

@Injectable()
export class RemindersService {
  constructor(
    private prisma: PrismaService,
    private gateway: EventsGateway,
    @InjectQueue('reminders') private remindersQueue: Queue,
  ) {}

  async findAll(coupleId: string) {
    return this.prisma.reminder.findMany({
      where: { coupleId },
      orderBy: { scheduledAt: 'asc' },
    });
  }

  async create(coupleId: string, userId: string, dto: CreateReminderDto) {
    const reminder = await this.prisma.reminder.create({
      data: {
        coupleId,
        createdBy: userId,
        title: dto.title,
        description: dto.description,
        scheduledAt: new Date(dto.scheduledAt),
        targetUser: dto.targetUser,
        recurrence: dto.recurrence ?? 'NONE',
      },
    });

    await this.scheduleJob(reminder);

    this.gateway.emitToCouple(coupleId, 'reminder_created', reminder);
    return reminder;
  }

  async complete(coupleId: string, reminderId: string) {
    const r = await this.prisma.reminder.findUnique({ where: { id: reminderId } });
    if (!r || r.coupleId !== coupleId) throw new ForbiddenException();

    return this.prisma.reminder.update({
      where: { id: reminderId },
      data: { isCompleted: true, completedAt: new Date() },
    });
  }

  async remove(coupleId: string, reminderId: string) {
    const r = await this.prisma.reminder.findUnique({ where: { id: reminderId } });
    if (!r) throw new NotFoundException();
    if (r.coupleId !== coupleId) throw new ForbiddenException();

    await this.remindersQueue.removeJobs(`reminder-${reminderId}`);
    await this.prisma.reminder.delete({ where: { id: reminderId } });
  }

  private async scheduleJob(reminder: any) {
    const delay = reminder.scheduledAt.getTime() - Date.now();
    if (delay <= 0) return;

    await this.remindersQueue.add(
      'send-reminder',
      { reminderId: reminder.id },
      { delay, jobId: `reminder-${reminder.id}` },
    );
  }
}
