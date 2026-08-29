import { Injectable, ForbiddenException } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../gateway/events.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateThoughtDto } from './dto/create-thought.dto';

@Injectable()
export class ThoughtsService {
  constructor(
    private prisma: PrismaService,
    private gateway: EventsGateway,
    private notifications: NotificationsService,
    @InjectQueue('thoughts') private thoughtsQueue: Queue,
  ) {}

  async findReceived(coupleId: string, userId: string) {
    const couple = await this.prisma.couple.findUnique({ where: { id: coupleId } });
    if (!couple) throw new ForbiddenException();
    const partnerId = couple.user1Id === userId ? couple.user2Id : couple.user1Id;

    return this.prisma.thought.findMany({
      where: { coupleId, senderId: partnerId, isDelivered: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findSent(coupleId: string, userId: string) {
    return this.prisma.thought.findMany({
      where: { coupleId, senderId: userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(coupleId: string, userId: string, dto: CreateThoughtDto) {
    const deliverAt = dto.deliverAt ? new Date(dto.deliverAt) : null;
    const isImmediate = !deliverAt || deliverAt <= new Date();

    const thought = await this.prisma.thought.create({
      data: {
        coupleId,
        senderId: userId,
        content: dto.content,
        tone: dto.tone ?? 'ROMANTIC',
        deliverAt,
        isDelivered: isImmediate,
      },
    });

    if (isImmediate) {
      await this.deliverThought(thought);
    } else {
      const delay = deliverAt!.getTime() - Date.now();
      await this.thoughtsQueue.add(
        'deliver-thought',
        { thoughtId: thought.id },
        { delay, jobId: `thought-${thought.id}` },
      );
    }

    return thought;
  }

  async markRead(coupleId: string, userId: string, thoughtId: string) {
    const thought = await this.prisma.thought.findUnique({ where: { id: thoughtId } });
    if (!thought || thought.coupleId !== coupleId) throw new ForbiddenException();

    const couple = await this.prisma.couple.findUnique({ where: { id: coupleId } });
    const partnerId = couple!.user1Id === userId ? couple!.user2Id : couple!.user1Id;
    if (thought.senderId !== partnerId) throw new ForbiddenException();

    return this.prisma.thought.update({
      where: { id: thoughtId },
      data: { isRead: true, readAt: new Date() },
    });
  }

  async toggleFavorite(coupleId: string, userId: string, thoughtId: string) {
    const thought = await this.prisma.thought.findUnique({ where: { id: thoughtId } });
    if (!thought || thought.coupleId !== coupleId) throw new ForbiddenException();

    return this.prisma.thought.update({
      where: { id: thoughtId },
      data: { isFavorite: !thought.isFavorite },
    });
  }

  async deliverThought(thought: any) {
    await this.prisma.thought.update({ where: { id: thought.id }, data: { isDelivered: true } });

    const couple = await this.prisma.couple.findUnique({ where: { id: thought.coupleId } });
    const recipientId = couple!.user1Id === thought.senderId ? couple!.user2Id : couple!.user1Id;

    this.gateway.emitToUser(recipientId, 'thought_received', thought);
    await this.notifications.sendToUser(recipientId, {
      title: '💌 Nuevo pensamiento',
      body: thought.content.substring(0, 60),
      route: '/thoughts',
      entityId: thought.id,
    });
  }
}
