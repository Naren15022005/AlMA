import { Module } from '@nestjs/common';
import { CouplesService } from './couples.service';
import { CouplesController } from './couples.controller';
import { GatewayModule } from '../gateway/gateway.module';

@Module({
  imports: [GatewayModule],
  providers: [CouplesService],
  controllers: [CouplesController],
  exports: [CouplesService],
})
export class CouplesModule {}
