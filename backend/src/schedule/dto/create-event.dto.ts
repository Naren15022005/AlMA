import { IsString, IsOptional, IsDateString, IsInt, Min, IsBoolean } from 'class-validator';

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
  @IsString()
  category?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  reminderMinutes?: number;

  @IsOptional()
  @IsBoolean()
  isRecurring?: boolean;
}
