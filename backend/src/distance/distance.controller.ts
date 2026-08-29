import { Body, Controller, Get, Post, UseGuards, Request } from '@nestjs/common';
import { JwtGuard } from '../auth/guards/jwt.guard';
import { DistanceService } from './distance.service';
import { UpdateLocationDto } from './dto/update-location.dto';

@UseGuards(JwtGuard)
@Controller('distance')
export class DistanceController {
  constructor(private distanceService: DistanceService) {}

  @Post('update')
  updateLocation(@Request() req: any, @Body() dto: UpdateLocationDto) {
    return this.distanceService.updateLocation(req.user.id, req.user.coupleId, dto.lat, dto.lng);
  }

  @Get()
  getDistance(@Request() req: any) {
    return this.distanceService.getDistance(req.user.coupleId);
  }

  @Get('history')
  getHistory(@Request() req: any) {
    return this.distanceService.getHistory(req.user.id, req.user.coupleId);
  }
}
