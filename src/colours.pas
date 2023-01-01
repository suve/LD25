(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2023 suve (a.k.a. Artur Frenszek-Iwicki)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License, version 3,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
Unit Colours;

{$INCLUDE defines.inc}

Interface
Uses SDL2;

Const
	WhiteColour: TSDL_Colour = (R: 255; G: 255; B: 255; A: 255);
	GreyColour: TSDL_Colour = (R: 128; G: 128; B: 128; A: 255);
	BlackColour: TSDL_Colour = (R: 0; G: 0; B: 0; A: 255);
	LimeColour: TSDL_Colour = (R: 0; G: 255; B: 0; A: 255);
	RedColour: TSDL_Colour = (R: 255; G: 0; B: 0; A: 255);
	YellowColour: TSDL_Colour = (R: 127; G: 127; B: 0; A: 255);

	ColourName : Array[0..7] of AnsiString = (
		'black', 'navy', 'green', 'blue', 'red', 'purple', 'yellow', 'white'
	);

	UIcolour: Array[0..7] of TSDL_Colour = (
		(R: $58; G: $58; B: $58; A: $FF),
		(R: $00; G: $00; B: $FF; A: $FF),
		(R: $00; G: $FF; B: $00; A: $FF),
		(R: $00; G: $FF; B: $FF; A: $FF),
		(R: $DD; G: $00; B: $00; A: $FF),
		(R: $FF; G: $00; B: $FF; A: $FF),
		(R: $FF; G: $FF; B: $00; A: $FF),
		(R: $FF; G: $FF; B: $FF; A: $FF)
	);

	DefaultMapColour: Array[0..7] of TSDL_Colour = (
		(R: $32; G: $32; B: $32; A: $FF),
		(R: $10; G: $18; B: $6A; A: $FF),
		(R: $29; G: $9C; B: $00; A: $FF),
		(R: $00; G: $9A; B: $9A; A: $FF),
		(R: $7A; G: $08; B: $18; A: $FF),
		(R: $94; G: $18; B: $8B; A: $FF),
		(R: $FF; G: $DE; B: $5A; A: $FF),
		(R: $DA; G: $DA; B: $DA; A: $FF)
	);

Var
	MapColour: Array[0..7] of TSDL_Colour;

Operator = (A, B: TSDL_Colour):Boolean;

Function ColourToStr(Const Colour:TSDL_Colour):AnsiString;

Function RGBToColour(RGB: LongWord):TSDL_Colour;
Function StrToColour(Str: AnsiString):TSDL_Colour;

Procedure ResetMapColoursToDefault();


Implementation
Uses
	StrUtils;

Operator = (A, B: TSDL_Colour):Boolean;
Begin
	Result := (A.R = B.R) and (A.G = B.G) and (A.B = B.B) and (A.A = B.A)
End;

Function ColourToStr(Const Colour:TSDL_Colour):AnsiString;
Begin
	Result := '#' + HexStr(Colour.R, 2) + HexStr(Colour.G, 2) + HexStr(Colour.B, 2)
End;

Function RGBToColour(RGB: LongWord):TSDL_Colour;
Begin
	Result.B := RGB mod 256;
	RGB := RGB div 256;
	Result.G := RGB mod 256;
	RGB := RGB div 256;
	Result.R := RGB mod 256;

	Result.A := 255
End;

Function StrToColour(Str: AnsiString):TSDL_Colour;
Var
	rstr, gstr, bstr: AnsiString;
Begin
	Str:=LowerCase(Str);
	If(Str[1] = '#') then Delete(Str, 1, 1);

	rstr := Copy(Str, 1, 2);
	gstr := Copy(Str, 3, 2);
	bstr := Copy(Str, 5, 2);

	Result.R := Hex2Dec(rstr);
	Result.G := Hex2Dec(gstr);
	Result.B := Hex2Dec(bstr);
	Result.A := $FF
End;

Procedure ResetMapColoursToDefault();
Var
	C: sInt;
Begin
	For C:=Low(MapColour) to High(MapColour) do MapColour[C]:=DefaultMapColour[C]
End;

End.
