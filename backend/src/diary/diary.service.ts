import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../gateway/events.gateway';
import { CreateDiaryEntryDto } from './dto/create-entry.dto';

@Injectable()
export class DiaryService {
  constructor(
    private prisma: PrismaService,
    private gateway: EventsGateway,
  ) {}

  async findAll(coupleId: string, userId: string) {
    return this.prisma.diaryEntry.findMany({
      where: {
        coupleId,
        OR: [{ isPrivate: false }, { authorId: userId }],
      },
      orderBy: { entryDate: 'desc' },
    });
  }

  async findOne(coupleId: string, userId: string, entryId: string) {
    const entry = await this.prisma.diaryEntry.findUnique({ where: { id: entryId } });
    if (!entry || entry.coupleId !== coupleId) throw new NotFoundException();
    if (entry.isPrivate && entry.authorId !== userId) throw new ForbiddenException();
    return entry;
  }

  async create(coupleId: string, userId: string, dto: CreateDiaryEntryDto) {
    return this.prisma.diaryEntry.create({
      data: {
        coupleId,
        authorId: userId,
        title: dto.title,
        content: dto.content,
        mood: dto.mood,
        imageUrl: dto.imageUrl,
        isPrivate: dto.isPrivate ?? false,
        entryDate: dto.entryDate ? new Date(dto.entryDate) : new Date(),
      },
    });
  }

  async update(coupleId: string, userId: string, entryId: string, dto: Partial<CreateDiaryEntryDto>) {
    const entry = await this.prisma.diaryEntry.findUnique({ where: { id: entryId } });
    if (!entry || entry.coupleId !== coupleId) throw new NotFoundException();
    if (entry.authorId !== userId) throw new ForbiddenException();

    return this.prisma.diaryEntry.update({
      where: { id: entryId },
      data: {
        ...dto,
        entryDate: dto.entryDate ? new Date(dto.entryDate) : undefined,
      },
    });
  }

  async react(coupleId: string, userId: string, entryId: string) {
    const entry = await this.prisma.diaryEntry.findUnique({ where: { id: entryId } });
    if (!entry || entry.coupleId !== coupleId) throw new ForbiddenException();
    if (entry.authorId === userId) throw new ForbiddenException('Cannot react to own entry');

    const updated = await this.prisma.diaryEntry.update({
      where: { id: entryId },
      data: { partnerReacted: true },
    });

    this.gateway.emitToUser(entry.authorId, 'diary_reacted', { entryId });
    return updated;
  }

  async remove(coupleId: string, userId: string, entryId: string) {
    const entry = await this.prisma.diaryEntry.findUnique({ where: { id: entryId } });
    if (!entry || entry.coupleId !== coupleId) throw new NotFoundException();
    if (entry.authorId !== userId) throw new ForbiddenException();
    await this.prisma.diaryEntry.delete({ where: { id: entryId } });
  }
}
