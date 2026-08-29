import { Module } from '@nestjs/common';
import { MinigamesService } from './minigames.service';
import { MinigamesController } from './minigames.controller';
import { GatewayModule } from '../gateway/gateway.module';

@Module({
  imports: [GatewayModule],
  providers: [MinigamesService],
  controllers: [MinigamesController],
})
export class MinigamesModule {}
