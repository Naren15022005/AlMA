import { IsString, MaxLength, IsOptional, IsDateString } from 'class-validator';

export class CreateThoughtDto {
  @IsString()
  @MaxLength(500)
  content: string;

  @IsOptional()
  @IsString()
  tone?: string;

  @IsOptional()
  @IsDateString()
  deliverAt?: string;
}
