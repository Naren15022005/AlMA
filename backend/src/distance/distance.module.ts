import { Module } from '@nestjs/common';
import { DistanceService } from './distance.service';
import { DistanceController } from './distance.controller';
import { GatewayModule } from '../gateway/gateway.module';

@Module({
  imports: [GatewayModule],
  providers: [DistanceService],
  controllers: [DistanceController],
})
export class DistanceModule {}
