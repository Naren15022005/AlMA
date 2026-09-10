import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
type GameType = 'TRUTH_OR_DARE' | 'ROULETTE' | 'KNOW_ME' | 'STORY';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../gateway/events.gateway';

const TRUTH_OR_DARE_QUESTIONS = [
  { type: 'truth', text: '¿Cuál es tu recuerdo favorito conmigo?' },
  { type: 'truth', text: '¿Qué es lo que más admiras de mí?' },
  { type: 'truth', text: '¿Cuál fue el momento en que te diste cuenta que me amabas?' },
  { type: 'truth', text: '¿Qué sueño quieres cumplir conmigo?' },
  { type: 'truth', text: '¿Qué es lo que más extrañas de mí cuando no estamos juntos?' },
  { type: 'dare', text: 'Envíame una foto haciendo tu mejor cara graciosa' },
  { type: 'dare', text: 'Escríbeme una canción de al menos 4 versos' },
  { type: 'dare', text: 'Cuéntame un secreto que nunca me hayas contado' },
  { type: 'dare', text: 'Imita mi forma de hablar en un audio' },
  { type: 'dare', text: 'Dime tres cosas que amas de mí sin parar de sonreír' },
];

const ROULETTE_OPTIONS = [
  { label: 'Película', emoji: '🎬' },
  { label: 'Restaurante', emoji: '🍕' },
  { label: 'Aire libre', emoji: '🌿' },
  { label: 'Videojuego', emoji: '🎮' },
  { label: 'Cocinar juntos', emoji: '👨‍🍳' },
];

@Injectable()
export class MinigamesService {
  constructor(
    private prisma: PrismaService,
    private gateway: EventsGateway,
  ) {}

  async getSessions(coupleId: string) {
    return this.prisma.gameSession.findMany({
      where: { coupleId },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });
  }

  async createSession(coupleId: string, gameType: string) {
    return this.prisma.gameSession.create({
      data: { coupleId, gameType, status: 'WAITING', data: '{}' },
    });
  }

  async getRandomQuestion(coupleId: string) {
    const used = await this.prisma.gameSession.findMany({
      where: { coupleId, gameType: 'TRUTH_OR_DARE' },
      select: { data: true },
    });
    const usedTexts = new Set(used.map((s: any) => s.data?.questionText).filter(Boolean));
    const available = TRUTH_OR_DARE_QUESTIONS.filter((q) => !usedTexts.has(q.text));
    const pool = available.length > 0 ? available : TRUTH_OR_DARE_QUESTIONS;
    return pool[Math.floor(Math.random() * pool.length)];
  }

  async spinRoulette(coupleId: string) {
    const result = ROULETTE_OPTIONS[Math.floor(Math.random() * ROULETTE_OPTIONS.length)];
    await this.prisma.gameSession.create({
      data: { coupleId, gameType: 'ROULETTE', status: 'FINISHED', data: JSON.stringify(result) },
    });
    this.gateway.emitToCouple(coupleId, 'game:state', { type: 'ROULETTE', result });
    return result;
  }

  async gameAction(coupleId: string, sessionId: string, userId: string, action: string, payload: any) {
    const session = await this.prisma.gameSession.findUnique({ where: { id: sessionId } });
    if (!session || session.coupleId !== coupleId) throw new ForbiddenException();

    const newData = { ...(session.data as any), [action]: { userId, payload, ts: new Date() } };
    const updated = await this.prisma.gameSession.update({
      where: { id: sessionId },
      data: { status: 'IN_PROGRESS', data: newData },
    });

    this.gateway.emitToCouple(coupleId, 'game:state', { sessionId, data: newData });
    return updated;
  }

  async finishSession(coupleId: string, sessionId: string, winnerId?: string) {
    const session = await this.prisma.gameSession.findUnique({ where: { id: sessionId } });
    if (!session || session.coupleId !== coupleId) throw new ForbiddenException();

    const finished = await this.prisma.gameSession.update({
      where: { id: sessionId },
      data: { status: 'FINISHED', winnerId, finishedAt: new Date() },
    });

    this.gateway.emitToCouple(coupleId, 'game:finished', { sessionId, winnerId });
    return finished;
  }

  getStats() {
    return { rouletteOptions: ROULETTE_OPTIONS };
  }
}
