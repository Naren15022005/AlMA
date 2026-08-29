import { Injectable, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { PrismaService } from '../prisma/prisma.service';

export interface PushPayload {
  title: string;
  body: string;
  route?: string;
  entityId?: string;
}

@Injectable()
export class NotificationsService implements OnModuleInit {
  private initialized = false;

  constructor(private prisma: PrismaService) {}

  onModuleInit() {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

    if (!projectId || !privateKey || !clientEmail) return;

    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({ projectId, privateKey, clientEmail }),
      });
    }
    this.initialized = true;
  }

  async sendToUser(userId: string, payload: PushPayload) {
    if (!this.initialized) return;

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.fcmToken) return;

    try {
      await admin.messaging().send({
        token: user.fcmToken,
        notification: { title: payload.title, body: payload.body },
        data: { route: payload.route ?? '/', entityId: payload.entityId ?? '' },
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    } catch {
      // Token may be stale — clear it
      await this.prisma.user.update({ where: { id: userId }, data: { fcmToken: null } });
    }
  }

  async sendToCouple(coupleId: string, payload: PushPayload, excludeUserId?: string) {
    const couple = await this.prisma.couple.findUnique({
      where: { id: coupleId },
      include: { members: { select: { id: true } } },
    });
    if (!couple) return;

    const targets = couple.members
      .map((m) => m.id)
      .filter((id) => id !== excludeUserId);

    await Promise.all(targets.map((id) => this.sendToUser(id, payload)));
  }
}
