(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2018 Artur Iwicki
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
Unit Fonts;

{$INCLUDE defines.inc}

Interface
	Uses SDL2, Images;

Type
	PFont = ^TFont;
	TFont = record
		Image: PImage;
		
		StartChar: Char;
		CharW, CharH: sInt;
		SpacingX, SpacingY: sInt;
		Scale: sInt
	end;

	THorizontalAlign = (
		ALIGN_LEFT,
		ALIGN_CENTRE,
		ALIGN_RIGHT
	);
	
	TVerticalAlign = (
		ALIGN_TOP,
		ALIGN_MIDDLE,
		ALIGN_BOTTOM
	);

Function FontFromImage(Const Image:PImage; Const StartChar: Char; Const CharW, CharH: sInt):PFont;
Procedure FreeFont(Const Font:PFont);

Function GetTextWidth(Const Text: AnsiString; Const Font: PFont):sInt;
Function GetTextHeight(Const Text: AnsiString; Const Font: PFont):sInt;
Procedure GetTextSize(Const Text: AnsiString; Const Font: PFont; Out W, H: sInt);

Procedure PrintText(
	Const Text: Array of AnsiString;
	Const Font: PFont;
	Const Xpos, Ypos: sInt;
	Const XAlign: THorizontalAlign; Const YAlign: TVerticalAlign;
	Const Colour: PSDL_Colour
);

Procedure PrintText(
	Const Text: AnsiString;
	Const Font: PFont;
	Const Xpos, Ypos: sInt;
	Const XAlign: THorizontalAlign; Const YAlign: TVerticalAlign;
	Const Colour: PSDL_Colour
);


Implementation

Function GetTextWidth(Const Text: AnsiString; Const Font: PFont):sInt;
Var
	Len, Pixels: sInt;
Begin
	Len := Length(Text);
	
	Pixels := Len * Font^.CharW;
	If(Len > 1) then Pixels += (Len - 1) * Font^.SpacingX;
	
	Result := Pixels * Font^.Scale
End;

Function GetTextHeight(Const Text: AnsiString; Const Font: PFont):sInt;
Begin
	Result := Font^.CharH * Font^.Scale
End;

Procedure GetTextSize(Const Text: AnsiString; Const Font: PFont; Out W, H: sInt);
Begin
	W := GetTextWidth(Text, Font);
	H := GetTextHeight(Text, Font)
End;


Function GetCharRect(Const ch:Char; Const Font:PFont):TSDL_Rect;
Var
	Order, PerRow: sInt;
	X, Y: sInt;
Begin
	PerRow := Font^.Image^.W div Font^.CharW;
	
	Order := Ord(ch) - Ord(Font^.StartChar);
	Y := Order div PerRow;
	X := Order mod PerRow;
	
	Result.X := X * Font^.CharW;
	Result.Y := Y * Font^.CharH;
	Result.W := Font^.CharW;
	Result.H := Font^.CharH
End;

Procedure PrintText(
	Const Text: Array of AnsiString;
	Const Font: PFont;
	Const Xpos, Ypos: sInt;
	Const XAlign: THorizontalAlign; Const YAlign: TVerticalAlign;
	Const Colour: PSDL_Colour
);
Var
	LineW, TotalW, TotalH: sInt;
	CurrentX, CurrentY: sInt;
	Src, Dst: TSDL_Rect;
	Idx, C: sInt;
Begin
	TotalW := 0;
	If(XAlign <> ALIGN_LEFT) then begin
		For Idx:=Low(Text) to High(Text) do begin
			LineW := GetTextWidth(Text[Idx], Font);
			If(LineW > TotalW) then TotalW := LineW;
		end
	end;
	
	CurrentY := Ypos;
	TotalH := 0;
	If(YAlign <> ALIGN_TOP) then begin
		TotalH := Length(Text) * Font^.CharH;
		TotalH += (Length(Text) - 1) * Font^.SpacingY;
		
		TotalH *= Font^.Scale;
		
		If(YAlign = ALIGN_MIDDLE) then
			CurrentY -= TotalH div 2
		else // ALIGN_BOTTOM
			CurrentY -= TotalH;
	end;
	
	For Idx:=Low(Text) to High(Text) do begin
		LineW := GetTextWidth(Text[Idx], Font);
		
		Case(XAlign) of
			ALIGN_LEFT:
				CurrentX := Xpos;
			
			ALIGN_CENTRE:
				CurrentX := Xpos - (LineW div 2);
			
			ALIGN_RIGHT:
				CurrentX := Xpos - LineW;
		end;
		
		Dst.X := CurrentX;
		Dst.Y := CurrentY;
		Dst.W := Font^.CharW * Font^.Scale;
		Dst.H := Font^.CharH * Font^.Scale;
		For C:=1 to Length(Text[Idx]) do begin
			Src := GetCharRect(Text[Idx][C], Font);
			DrawImage(Font^.Image, @Src, @Dst, Colour);
			
			Dst.X += (Font^.CharW + Font^.SpacingX) * Font^.Scale
		end;
		
		CurrentY += (Font^.CharH + Font^.SpacingY) * Font^.Scale
	end
End;

Procedure PrintText(
	Const Text: AnsiString;
	Const Font: PFont;
	Const Xpos, Ypos: sInt;
	Const XAlign: THorizontalAlign; Const YAlign: TVerticalAlign;
	Const Colour: PSDL_Colour
);
Begin
	PrintText([Text], Font, Xpos, Ypos, XAlign, YAlign, Colour)
End;

Function FontFromImage(Const Image:PImage; Const StartChar: Char; Const CharW, CharH: sInt):PFont;
Var
	Fnt: PFont;
Begin
	If(Image = NIL) then Exit(NIL);
	
	New(Fnt);
	If(Fnt = NIL) then Exit(NIL);
	
	Fnt^.Image := Image;
	Fnt^.StartChar := StartChar;
	Fnt^.CharW := CharW;
	Fnt^.CharH := CharH;
	Fnt^.SpacingX := 1;
	Fnt^.SpacingY := 1;
	Fnt^.Scale := 1;
	
	Result := Fnt
End;

Procedure FreeFont(Const Font:PFont);
Begin
	If(Font <> NIL) then Dispose(Font)
End;

End.
