import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateMemeDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  caption?: string;
}
