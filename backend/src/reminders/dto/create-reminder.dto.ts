import { IsString, IsOptional, IsDateString, IsEnum } from 'class-validator';
import { ReminderTarget, Recurrence } from '@prisma/client';

export class CreateReminderDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsDateString()
  scheduledAt: string;

  @IsEnum(ReminderTarget)
  targetUser: ReminderTarget;

  @IsOptional()
  @IsEnum(Recurrence)
  recurrence?: Recurrence;
}
