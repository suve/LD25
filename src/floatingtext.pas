(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2017 Artur Iwicki
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
unit floatingtext; 

{$INCLUDE defines.inc}

interface
	uses Shared, SDL2;

Type
	PFloatTxt = ^TFloatTxt;
	TFloatTxt = Object
		X, Y: sInt;
		Colour: PSDL_Colour;
		Text: AnsiString;

		Constructor Create();
		Destructor Destroy();
	end;

Var
	FloatTxt:Array of PFloatTxt;

Procedure AddFloatTxt(Const X, Y, ColID: sInt; Const Text:AnsiString);
Procedure FlushFloatTxt();

implementation
	uses SysUtils;

Procedure AddFloatTxt(X,Y,ColID:sInt;Text:AnsiString);
Var
	FT: PFloatTxt;
	Idx: sInt;
Begin
	New(FT,Create());
	FT^.X:=X; FT^.Y:=Y;
	FT^.Text:=UpperCase(Text);
	
	If (ColID < 0) then
		FT^.Col:=NIL
	else If (ColID < 8) then
		FT^.Col:=@PaletteColour[ColID]
	else If (ColID = 8) then
		FT^.Col:=@GreyColour
	else
		FT^.Col:=NIL;
	
	Idx := Length(FloatTxt);
	SetLength(FloatTxt, Idx+1);
	FloatTxt[Idx]:=FT
End;

Procedure FlushFloatTxt();
Var
	C:uInt;
Begin
	If (Length(FloatTxt)=0) then Exit;
	
	For C:=Low(FloatTxt) to High(FloatTxt) do
		If (FloatTxt[C]<>NIL) then 
			Dispose(FloatTxt[C],Destroy());
	
	SetLength(FloatTxt,0)
End;

Constructor TFloatTxt.Create();
Begin
	X:=0; Y:=0;
	Colour:=NIL;
	Text:=''
End;

Destructor TFloatTxt.Destroy();
Begin End;

end.

