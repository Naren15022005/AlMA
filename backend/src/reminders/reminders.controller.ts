import { Body, Controller, Delete, Get, Param, Post, Patch, UseGuards, Request } from '@nestjs/common';
import { JwtGuard } from '../auth/guards/jwt.guard';
import { RemindersService } from './reminders.service';
import { CreateReminderDto } from './dto/create-reminder.dto';

@UseGuards(JwtGuard)
@Controller('reminders')
export class RemindersController {
  constructor(private remindersService: RemindersService) {}

  @Get()
  findAll(@Request() req: any) {
    return this.remindersService.findAll(req.user.coupleId);
  }

  @Post()
  create(@Request() req: any, @Body() dto: CreateReminderDto) {
    return this.remindersService.create(req.user.coupleId, req.user.id, dto);
  }

  @Patch(':id/complete')
  complete(@Request() req: any, @Param('id') id: string) {
    return this.remindersService.complete(req.user.coupleId, id);
  }

  @Delete(':id')
  remove(@Request() req: any, @Param('id') id: string) {
    return this.remindersService.remove(req.user.coupleId, id);
  }
}
