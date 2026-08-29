import {
  Body, Controller, Delete, Get, Param, Post, Query,
  UploadedFile, UseGuards, UseInterceptors, Request,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { JwtGuard } from '../auth/guards/jwt.guard';
import { MemesService } from './memes.service';

@UseGuards(JwtGuard)
@Controller('memes')
export class MemesController {
  constructor(private memesService: MemesService) {}

  @Get()
  findAll(@Request() req: any, @Query('cursor') cursor?: string) {
    return this.memesService.findAll(req.user.coupleId, cursor);
  }

  @Post()
  @UseInterceptors(FileInterceptor('file', { storage: memoryStorage() }))
  upload(
    @Request() req: any,
    @UploadedFile() file: Express.Multer.File,
    @Body('caption') caption?: string,
  ) {
    return this.memesService.upload(req.user.coupleId, req.user.id, file, caption);
  }

  @Post(':id/reactions')
  react(@Request() req: any, @Param('id') id: string, @Body('emoji') emoji: string) {
    return this.memesService.react(req.user.coupleId, req.user.id, id, emoji);
  }

  @Delete(':id/reactions/:emoji')
  removeReaction(@Request() req: any, @Param('id') id: string, @Param('emoji') emoji: string) {
    return this.memesService.removeReaction(req.user.id, id, emoji);
  }

  @Delete(':id')
  remove(@Request() req: any, @Param('id') id: string) {
    return this.memesService.remove(req.user.coupleId, req.user.id, id);
  }
}
