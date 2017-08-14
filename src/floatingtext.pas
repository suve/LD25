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
   uses Shared, Sour;

Type PFloatTxt = ^TFloatTxt;
     TFloatTxt = Object
     X, Y : sInt;
     Col : Sour.PColour;
     Text : AnsiString;

     Constructor Create();
     Destructor Destroy();
     end;

Var FloatTxt:Array of PFloatTxt;

Procedure AddFloatTxt(X,Y,ColID:sInt;Text:AnsiString);
Procedure FlushFloatTxt();

implementation
   uses SysUtils;

Procedure AddFloatTxt(X,Y,ColID:sInt;Text:AnsiString);
   Var FT:PFloatTxt;
   begin
   SetLength(FloatTxt,Length(FloatTxt)+1);
   New(FT,Create());
   FT^.X:=X; FT^.Y:=Y; FT^.Text:=UpperCase(Text);
   If (ColID < 0) then FT^.Col:=NIL else
   If (ColID < 8) then FT^.Col:=@PaletteColour[ColID] else
   If (ColID = 8) then FT^.Col:=@GreyColour {else}
                  else FT^.Col:=NIL;
   FloatTxt[High(FloatTxt)]:=FT
   end;

Procedure FlushFloatTxt();
   Var C:uInt;
   begin
   If (Length(FloatTxt)=0) then Exit;
   For C:=Low(FloatTxt) to High(FloatTxt) do
       If (FloatTxt[C]<>NIL) then Dispose(FloatTxt[C],Destroy());
   SetLength(FloatTxt,0)
   end;

Constructor TFloatTxt.Create();
   begin
   X:=0; Y:=0; Col:=NIL;
   Text:=''
   end;

Destructor TFloatTxt.Destroy();
   begin end;

end.

