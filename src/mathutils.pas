(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2022 suve (a.k.a. Artur Frenszek Iwicki)
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
	uses Entities;

// Some functions for calculating distances
Function  Hypotenuse(X,Y:Double):Double;
Function  Hypotenuse(aX,aY,bX,bY:Double):Double;
Function  Hypotenuse(A,B:PEntity):Double;
Procedure GetDist(A,B:PEntity;Out oX,oY,oD:Double);

// Sign function (probably is implemented in math or sysutils, but I'm too lazy to check)
Function Sgn(Wat:Double):sInt;
Function InRange(Num,Min,Max:Int64):Boolean;
Function Random(Min,Max:Int64):Int64; Overload; // The overload prevents shadowing "System.Random()"

// Check if objects overlap
Function Overlap(AX,AY:Double;AW,AH:uInt;BX,BY:Double;BW,BH:uInt):Boolean;
Function Overlap(A,B:PEntity):Boolean;


Implementation

Function Hypotenuse(X,Y:Double):Double;
Begin
	Result := Sqrt(Sqr(X)+Sqr(Y))
End;

Function Hypotenuse(aX,aY,bX,bY:Double):Double;
Begin
	Result := Sqrt(Sqr(aX-bX)+Sqr(aY-bY))
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

Function Sgn(Wat:Double):sInt;
Begin
	If (Wat>0) then
		Exit(+1)
	else If (Wat<0) then
		Exit(-1)
	else
		Exit(0)
End;

Function InRange(Num,Min,Max:Int64):Boolean;
Begin
	Result := (Num>=Min) and (Num<=Max)
end;

Function Random(Min,Max:Int64):Int64; Overload;
Begin
	Exit(Min + System.Random(Max-Min+1))
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
	Overlap(A^.X,A^.Y,A^.W,A^.H,B^.X,B^.Y,B^.W,B^.H)
End;

End.
