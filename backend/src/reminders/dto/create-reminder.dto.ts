import { IsString, IsOptional, IsDateString } from 'class-validator';

export class CreateReminderDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsDateString()
  scheduledAt: string;

  @IsString()
  targetUser: string;

  @IsOptional()
  @IsString()
  recurrence?: string;
}
