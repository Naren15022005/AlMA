import { IsString, IsOptional, IsDateString, IsEnum, IsInt, Min, IsBoolean } from 'class-validator';
import { EventCategory } from '@prisma/client';

export class CreateEventDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsDateString()
  startAt: string;

  @IsOptional()
  @IsDateString()
  endAt?: string;

  @IsOptional()
  @IsEnum(EventCategory)
  category?: EventCategory;

  @IsOptional()
  @IsInt()
  @Min(0)
  reminderMinutes?: number;

  @IsOptional()
  @IsBoolean()
  isRecurring?: boolean;
}
