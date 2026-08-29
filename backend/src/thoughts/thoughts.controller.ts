import { Body, Controller, Get, Param, Patch, Post, UseGuards, Request } from '@nestjs/common';
import { JwtGuard } from '../auth/guards/jwt.guard';
import { ThoughtsService } from './thoughts.service';
import { CreateThoughtDto } from './dto/create-thought.dto';

@UseGuards(JwtGuard)
@Controller('thoughts')
export class ThoughtsController {
  constructor(private thoughtsService: ThoughtsService) {}

  @Get('received')
  findReceived(@Request() req: any) {
    return this.thoughtsService.findReceived(req.user.coupleId, req.user.id);
  }

  @Get('sent')
  findSent(@Request() req: any) {
    return this.thoughtsService.findSent(req.user.coupleId, req.user.id);
  }

  @Post()
  create(@Request() req: any, @Body() dto: CreateThoughtDto) {
    return this.thoughtsService.create(req.user.coupleId, req.user.id, dto);
  }

  @Patch(':id/read')
  markRead(@Request() req: any, @Param('id') id: string) {
    return this.thoughtsService.markRead(req.user.coupleId, req.user.id, id);
  }

  @Patch(':id/favorite')
  toggleFavorite(@Request() req: any, @Param('id') id: string) {
    return this.thoughtsService.toggleFavorite(req.user.coupleId, req.user.id, id);
  }
}
