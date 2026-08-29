import { Body, Controller, Delete, Get, Param, Post, Put, Patch, UseGuards, Request } from '@nestjs/common';
import { JwtGuard } from '../auth/guards/jwt.guard';
import { DiaryService } from './diary.service';
import { CreateDiaryEntryDto } from './dto/create-entry.dto';

@UseGuards(JwtGuard)
@Controller('diary')
export class DiaryController {
  constructor(private diaryService: DiaryService) {}

  @Get()
  findAll(@Request() req: any) {
    return this.diaryService.findAll(req.user.coupleId, req.user.id);
  }

  @Get(':id')
  findOne(@Request() req: any, @Param('id') id: string) {
    return this.diaryService.findOne(req.user.coupleId, req.user.id, id);
  }

  @Post()
  create(@Request() req: any, @Body() dto: CreateDiaryEntryDto) {
    return this.diaryService.create(req.user.coupleId, req.user.id, dto);
  }

  @Put(':id')
  update(@Request() req: any, @Param('id') id: string, @Body() dto: Partial<CreateDiaryEntryDto>) {
    return this.diaryService.update(req.user.coupleId, req.user.id, id, dto);
  }

  @Patch(':id/react')
  react(@Request() req: any, @Param('id') id: string) {
    return this.diaryService.react(req.user.coupleId, req.user.id, id);
  }

  @Delete(':id')
  remove(@Request() req: any, @Param('id') id: string) {
    return this.diaryService.remove(req.user.coupleId, req.user.id, id);
  }
}
