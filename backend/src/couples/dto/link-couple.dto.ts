import { IsString, Length } from 'class-validator';

export class LinkCoupleDto {
  @IsString()
  @Length(6, 6)
  partnerCode: string;
}
