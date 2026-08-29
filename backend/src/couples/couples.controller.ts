import { Body, Controller, Get, Post, UseGuards, Request } from '@nestjs/common';
import { JwtGuard } from '../auth/guards/jwt.guard';
import { CouplesService } from './couples.service';
import { LinkCoupleDto } from './dto/link-couple.dto';

@UseGuards(JwtGuard)
@Controller('couples')
export class CouplesController {
  constructor(private couplesService: CouplesService) {}

  @Post('link')
  link(@Request() req: any, @Body() dto: LinkCoupleDto) {
    return this.couplesService.link(req.user.id, dto.partnerCode);
  }

  @Get('me')
  getCouple(@Request() req: any) {
    return this.couplesService.getCouple(req.user.id);
  }

  @Post('anniversary')
  updateAnniversary(@Request() req: any, @Body('anniversary') anniversary: string) {
    return this.couplesService.updateAnniversary(req.user.coupleId, anniversary);
  }
}
