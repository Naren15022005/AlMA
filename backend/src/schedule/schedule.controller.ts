import { Body, Controller, Delete, Get, Param, Post, Put, Query, UseGuards, Request } from '@nestjs/common';
import { JwtGuard } from '../auth/guards/jwt.guard';
import { ScheduleService } from './schedule.service';
import { CreateEventDto } from './dto/create-event.dto';

@UseGuards(JwtGuard)
@Controller('schedule')
export class ScheduleController {
  constructor(private scheduleService: ScheduleService) {}

  @Get()
  findAll(@Request() req: any, @Query('from') from?: string, @Query('to') to?: string) {
    return this.scheduleService.findAll(req.user.coupleId, from, to);
  }

  @Post()
  create(@Request() req: any, @Body() dto: CreateEventDto) {
    return this.scheduleService.create(req.user.coupleId, req.user.id, dto);
  }

  @Put(':id')
  update(@Request() req: any, @Param('id') id: string, @Body() dto: Partial<CreateEventDto>) {
    return this.scheduleService.update(req.user.coupleId, id, dto);
  }

  @Delete(':id')
  remove(@Request() req: any, @Param('id') id: string) {
    return this.scheduleService.remove(req.user.coupleId, id);
  }
}
