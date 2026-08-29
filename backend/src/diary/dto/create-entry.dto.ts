import { IsString, IsOptional, IsBoolean, IsDateString } from 'class-validator';

export class CreateDiaryEntryDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsString()
  content: string;

  @IsString()
  mood: string;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsBoolean()
  isPrivate?: boolean;

  @IsOptional()
  @IsDateString()
  entryDate?: string;
}
