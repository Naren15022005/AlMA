import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../gateway/events.gateway';
import { CreateEventDto } from './dto/create-event.dto';

@Injectable()
export class ScheduleService {
  constructor(
    private prisma: PrismaService,
    private gateway: EventsGateway,
  ) {}

  async findAll(coupleId: string, from?: string, to?: string) {
    return this.prisma.event.findMany({
      where: {
        coupleId,
        startAt: {
          gte: from ? new Date(from) : undefined,
          lte: to ? new Date(to) : undefined,
        },
      },
      orderBy: { startAt: 'asc' },
    });
  }

  async create(coupleId: string, userId: string, dto: CreateEventDto) {
    const event = await this.prisma.event.create({
      data: {
        coupleId,
        createdById: userId,
        title: dto.title,
        description: dto.description,
        startAt: new Date(dto.startAt),
        endAt: dto.endAt ? new Date(dto.endAt) : null,
        category: dto.category ?? 'OTHER',
        reminderMinutes: dto.reminderMinutes,
        isRecurring: dto.isRecurring ?? false,
      },
    });
    this.gateway.emitToCouple(coupleId, 'schedule_updated', { action: 'created', event });
    return event;
  }

  async update(coupleId: string, eventId: string, dto: Partial<CreateEventDto>) {
    const existing = await this.prisma.event.findUnique({ where: { id: eventId } });
    if (!existing) throw new NotFoundException('Event not found');
    if (existing.coupleId !== coupleId) throw new ForbiddenException();

    const updated = await this.prisma.event.update({
      where: { id: eventId },
      data: {
        ...dto,
        startAt: dto.startAt ? new Date(dto.startAt) : undefined,
        endAt: dto.endAt ? new Date(dto.endAt) : undefined,
      },
    });
    this.gateway.emitToCouple(coupleId, 'schedule_updated', { action: 'updated', event: updated });
    return updated;
  }

  async remove(coupleId: string, eventId: string) {
    const existing = await this.prisma.event.findUnique({ where: { id: eventId } });
    if (!existing) throw new NotFoundException('Event not found');
    if (existing.coupleId !== coupleId) throw new ForbiddenException();

    await this.prisma.event.delete({ where: { id: eventId } });
    this.gateway.emitToCouple(coupleId, 'schedule_updated', { action: 'deleted', eventId });
  }
}
