import { IsString, MaxLength, IsEnum, IsOptional, IsDateString } from 'class-validator';
import { ThoughtTone } from '@prisma/client';

export class CreateThoughtDto {
  @IsString()
  @MaxLength(500)
  content: string;

  @IsOptional()
  @IsEnum(ThoughtTone)
  tone?: ThoughtTone;

  @IsOptional()
  @IsDateString()
  deliverAt?: string;
}
