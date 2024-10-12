(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2024 suve (a.k.a. Artur Frenszek-Iwicki)
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
Unit MathUtils; 

{$INCLUDE defines.inc}


Interface
	uses SDL2, Entities;

Function Hypotenuse(X, Y: Double): Double;
Function Hypotenuse(aX, aY, bX, bY: Double): Double;
Function Hypotenuse(A, B: PEntity): Double;

Procedure GetDist(A,B:PEntity;Out oX,oY,oD:Double);

Function ProjectPoint(OriginX, OriginY: sInt; Distance: uInt; Angle: Double): TSDL_Point;

Function InRange(Num,Min,Max:Int64):Boolean;
Function Random(Min,Max:Int64):Int64; Overload; // The overload prevents shadowing "System.Random()"

Function MinOfTwo(First, Second: uInt): uInt; Inline;
Function MaxOfTwo(First, Second: uInt): uInt; Inline;

// Check if objects overlap
Function Overlap(AX,AY:Double;AW,AH:uInt;BX,BY:Double;BW,BH:uInt):Boolean;
Function Overlap(A,B:PEntity):Boolean;

Function CombineRects(Const First, Second: TSDL_Rect): TSDL_Rect;


Implementation
	uses Math;

Function Hypotenuse(X,Y:Double):Double;
Begin
	Result := Math.Hypot(X, Y)
End;

Function Hypotenuse(aX,aY,bX,bY:Double):Double;
Begin
	Result := Math.Hypot(aX-bX, aY-bY)
End;

Function Hypotenuse(A,B:PEntity):Double;
Begin
	Result := Hypotenuse(A^.X+(A^.W/2),A^.Y+(A^.H/2),B^.X+(B^.W/2),B^.Y+(B^.H/2))
End;

Procedure GetDist(A,B:PEntity;Out oX,oY,oD:Double);
Begin
	oX:=(B^.X+(B^.W/2))-(A^.X+(A^.W/2));
	oY:=(B^.Y+(B^.H/2))-(A^.Y+(A^.H/2));
	oD:=Hypotenuse(oX,oY)
end;

Function ProjectPoint(OriginX, OriginY: sInt; Distance: uInt; Angle: Double): TSDL_Point;
Begin
	Result.X := Trunc(OriginX + 0.5 + (Cos(Angle) * Distance));
	Result.Y := Trunc(OriginY + 0.5 + (Sin(Angle) * Distance))
End;

Function InRange(Num,Min,Max:Int64):Boolean;
Begin
	Result := (Num >= Min) and (Num <= Max)
end;

Function Random(Min,Max:Int64):Int64; Overload;
Begin
	Result := Min + System.Random(Max - Min + 1)
End;

Function MinOfTwo(First, Second: uInt): uInt; Inline;
Begin
	If(First < Second) then
		Result := First
	else
		Result := Second
End;

Function MaxOfTwo(First, Second: uInt): uInt; Inline;
Begin
	If(First > Second) then
		Result := First
	else
		Result := Second
End;

Function Overlap(AX,AY:Double;AW,AH:uInt;BX,BY:Double;BW,BH:uInt):Boolean;
Begin
	If ((AX + AW - 1) < BX) then Exit(False);
	If ((BX + BW - 1) < AX) then Exit(False);
	If ((AY + AH - 1) < BY) then Exit(False);
	If ((BY + BH - 1) < AY) then Exit(False);
	Exit(True)
End;

Function Overlap(A,B:PEntity):Boolean;
Begin
	Result := Overlap(A^.X,A^.Y,A^.W,A^.H,B^.X,B^.Y,B^.W,B^.H)
End;

Function CombineRects(Const First, Second: TSDL_Rect): TSDL_Rect;
Var
	FirstRight, SecondRight: uInt;
	FirstBottom, SecondBottom: uInt;
Begin
	If First.X < Second.X then
		Result.X := First.X
	else
		Result.X := Second.X;
	If First.Y < Second.Y then
		Result.Y := First.Y
	else
		Result.Y := Second.Y;

	(*
	 * To get the actual "end X" / "end Y" of each rectangle, we should
	 * subtract 1 from these values. However, then we'd need to re-add
	 * it later. Omitting it makes calculations easier.
	 *)
	FirstRight := First.X + First.W;
	SecondRight := Second.X + Second.W;
	FirstBottom := First.Y + First.H;
	SecondBottom := Second.Y + Second.H;

	Result.W := MaxOfTwo(FirstRight, SecondRight) - Result.X;
	Result.H := MaxOfTwo(FirstBottom, SecondBottom) - Result.Y
End;

End.
