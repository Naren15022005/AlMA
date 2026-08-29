import { Body, Controller, Get, Param, Post, Patch, UseGuards, Request } from '@nestjs/common';
import { JwtGuard } from '../auth/guards/jwt.guard';
import { MinigamesService } from './minigames.service';
import { GameType } from '@prisma/client';

@UseGuards(JwtGuard)
@Controller('minigames')
export class MinigamesController {
  constructor(private minigamesService: MinigamesService) {}

  @Get('sessions')
  getSessions(@Request() req: any) {
    return this.minigamesService.getSessions(req.user.coupleId);
  }

  @Post('sessions')
  createSession(@Request() req: any, @Body('gameType') gameType: GameType) {
    return this.minigamesService.createSession(req.user.coupleId, gameType);
  }

  @Get('truth-or-dare/question')
  getQuestion(@Request() req: any) {
    return this.minigamesService.getRandomQuestion(req.user.coupleId);
  }

  @Post('roulette/spin')
  spinRoulette(@Request() req: any) {
    return this.minigamesService.spinRoulette(req.user.coupleId);
  }

  @Post('sessions/:id/action')
  gameAction(
    @Request() req: any,
    @Param('id') id: string,
    @Body('action') action: string,
    @Body('payload') payload: any,
  ) {
    return this.minigamesService.gameAction(req.user.coupleId, id, req.user.id, action, payload);
  }

  @Patch('sessions/:id/finish')
  finishSession(
    @Request() req: any,
    @Param('id') id: string,
    @Body('winnerId') winnerId?: string,
  ) {
    return this.minigamesService.finishSession(req.user.coupleId, id, winnerId);
  }
}
