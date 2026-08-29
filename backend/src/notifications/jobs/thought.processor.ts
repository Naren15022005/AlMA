import { Process, Processor } from '@nestjs/bull';
import { Job } from 'bull';
import { PrismaService } from '../../prisma/prisma.service';
import { ThoughtsService } from '../../thoughts/thoughts.service';

@Processor('thoughts')
export class ThoughtProcessor {
  constructor(
    private prisma: PrismaService,
    private thoughtsService: ThoughtsService,
  ) {}

  @Process('deliver-thought')
  async handleDelivery(job: Job<{ thoughtId: string }>) {
    const thought = await this.prisma.thought.findUnique({ where: { id: job.data.thoughtId } });
    if (!thought || thought.isDelivered) return;
    await this.thoughtsService.deliverThought(thought);
  }
}
