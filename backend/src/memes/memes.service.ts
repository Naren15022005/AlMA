import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';
import { PrismaService } from '../prisma/prisma.service';
import { EventsGateway } from '../gateway/events.gateway';

const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const MAX_SIZE_BYTES = 5 * 1024 * 1024;

@Injectable()
export class MemesService {
  constructor(
    private prisma: PrismaService,
    private gateway: EventsGateway,
  ) {
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
    });
  }

  async findAll(coupleId: string, cursor?: string) {
    return this.prisma.meme.findMany({
      where: { coupleId },
      include: { reactions: true },
      orderBy: { createdAt: 'desc' },
      take: 20,
      cursor: cursor ? { id: cursor } : undefined,
      skip: cursor ? 1 : 0,
    });
  }

  async upload(coupleId: string, userId: string, file: Express.Multer.File, caption?: string) {
    if (!ALLOWED_MIME.includes(file.mimetype)) throw new BadRequestException('Invalid file type');
    if (file.size > MAX_SIZE_BYTES) throw new BadRequestException('File too large (max 5MB)');

    const result = await new Promise<any>((resolve, reject) => {
      cloudinary.uploader
        .upload_stream({ folder: `alma/memes/${coupleId}` }, (err, res) => {
          if (err) reject(err);
          else resolve(res);
        })
        .end(file.buffer);
    });

    const meme = await this.prisma.meme.create({
      data: { coupleId, uploadedBy: userId, imageUrl: result.secure_url, caption },
      include: { reactions: true },
    });

    this.gateway.emitToCouple(coupleId, 'meme_uploaded', meme);
    return meme;
  }

  async react(coupleId: string, userId: string, memeId: string, emoji: string) {
    const meme = await this.prisma.meme.findUnique({ where: { id: memeId } });
    if (!meme || meme.coupleId !== coupleId) throw new ForbiddenException();

    const existing = await this.prisma.memeReaction.findMany({ where: { memeId } });
    const emojis = [...new Set(existing.map((r) => r.emoji))];
    if (!emojis.includes(emoji) && emojis.length >= 5) {
      throw new BadRequestException('Max 5 different reactions per meme');
    }

    return this.prisma.memeReaction.upsert({
      where: { memeId_userId_emoji: { memeId, userId, emoji } },
      create: { memeId, userId, emoji },
      update: {},
    });
  }

  async removeReaction(userId: string, memeId: string, emoji: string) {
    return this.prisma.memeReaction.deleteMany({ where: { memeId, userId, emoji } });
  }

  async remove(coupleId: string, userId: string, memeId: string) {
    const meme = await this.prisma.meme.findUnique({ where: { id: memeId } });
    if (!meme) throw new NotFoundException();
    if (meme.coupleId !== coupleId || meme.uploadedBy !== userId) throw new ForbiddenException();
    await this.prisma.meme.delete({ where: { id: memeId } });
  }
}
