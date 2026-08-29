import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../gateway/events.gateway';

@Injectable()
export class CouplesService {
  constructor(
    private prisma: PrismaService,
    private gateway: EventsGateway,
  ) {}

  async link(userId: string, partnerCode: string) {
    const me = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!me) throw new NotFoundException('User not found');
    if (me.coupleId) throw new ConflictException('You are already paired');

    const partner = await this.prisma.user.findUnique({ where: { pairCode: partnerCode.toUpperCase() } });
    if (!partner) throw new NotFoundException('Partner code not found');
    if (partner.id === userId) throw new BadRequestException('Cannot pair with yourself');
    if (partner.coupleId) throw new ConflictException('Partner is already paired');

    const couple = await this.prisma.couple.create({
      data: {
        user1Id: userId,
        user2Id: partner.id,
        members: { connect: [{ id: userId }, { id: partner.id }] },
      },
      include: { members: true },
    });

    await this.prisma.user.updateMany({
      where: { id: { in: [userId, partner.id] } },
      data: { coupleId: couple.id },
    });

    this.gateway.emitToCouple(couple.id, 'couple_linked', { coupleId: couple.id });

    return couple;
  }

  async getCouple(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        couple: { include: { members: { select: { id: true, name: true, avatarUrl: true, birthday: true, pairCode: true } } } },
      },
    });
    if (!user?.couple) throw new NotFoundException('No couple found');
    return user.couple;
  }

  async updateAnniversary(coupleId: string, anniversary: string) {
    return this.prisma.couple.update({
      where: { id: coupleId },
      data: { anniversary: new Date(anniversary) },
    });
  }
}
