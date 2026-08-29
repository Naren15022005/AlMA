import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../gateway/events.gateway';

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

@Injectable()
export class DistanceService {
  constructor(
    private prisma: PrismaService,
    private gateway: EventsGateway,
  ) {}

  async updateLocation(userId: string, coupleId: string, lat: number, lng: number) {
    const location = await this.prisma.location.create({
      data: { userId, coupleId, latitude: lat, longitude: lng },
    });

    this.gateway.emitToCouple(coupleId, 'location_updated', {
      userId,
      lat,
      lng,
      ts: location.recordedAt,
    });

    return location;
  }

  async getDistance(coupleId: string) {
    const couple = await this.prisma.couple.findUnique({
      where: { id: coupleId },
      include: { members: { select: { id: true } } },
    });
    if (!couple) return null;

    const [user1Id, user2Id] = couple.members.map((m) => m.id);

    const [loc1, loc2] = await Promise.all([
      this.prisma.location.findFirst({ where: { userId: user1Id, coupleId }, orderBy: { recordedAt: 'desc' } }),
      this.prisma.location.findFirst({ where: { userId: user2Id, coupleId }, orderBy: { recordedAt: 'desc' } }),
    ]);

    if (!loc1 || !loc2) return { distanceKm: null, locations: { user1: loc1, user2: loc2 } };

    const distanceKm = haversineKm(loc1.latitude, loc1.longitude, loc2.latitude, loc2.longitude);
    return { distanceKm: Math.round(distanceKm), locations: { user1: loc1, user2: loc2 } };
  }

  async getHistory(userId: string, coupleId: string) {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    return this.prisma.location.findMany({
      where: { userId, coupleId, recordedAt: { gte: sevenDaysAgo } },
      orderBy: { recordedAt: 'desc' },
      take: 100,
    });
  }
}
