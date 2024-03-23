(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2024 suve (a.k.a. Artur Frenszek-Iwicki)
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
Unit Buffers;

{$INCLUDE defines.inc}

Interface

Type
	Generic GenericBuffer<Thing> = object
		Public
			Type TCallback = Procedure(Th: Thing);
		Private
			Data: Array of Thing;
			Count, Capacity: uInt;
			StepSize: uInt;

			Function GetValue(Index: uInt): Thing;
			Procedure SetValue(Index: uInt; Value: Thing);

		Public
			Procedure Append(Value: Thing);
			Procedure Compact();
			Procedure Flush();
			Procedure Flush(Callback: TCallback);

			Function GetCount(): uInt;
			Function GetCapacity(): uInt;

			Property Items[i: uInt]: Thing
				read GetValue write SetValue; Default;

			Constructor Create(ResizeStep: uInt);
			Destructor Destroy();
	end;

Implementation

Function GenericBuffer.GetValue(Index: uInt): Thing;
Begin
	Result := Self.Data[Index]
End;

Procedure GenericBuffer.SetValue(Index: uInt; Value: Thing);
Begin
	Self.Data[Index] := Value
End;

Procedure GenericBuffer.Append(Value: Thing);
Var
	Idx: uInt;
Begin
	If (Self.Count = Self.Capacity) then begin
		Self.Capacity += Self.StepSize;
		SetLength(Self.Data, Self.Capacity);

		For Idx := (Self.Count + 1) to (Self.Capacity - 1) do
			Self.Data[Idx] := NIL
	end;

	Self.Data[Self.Count] := Value;
	Self.Count += 1
End;

Procedure GenericBuffer.Compact();
Var
	Iter, Dest: uInt;
Begin
	If (Self.Count = 0) then Exit;

	Dest := 0;
	For Iter := 0 to (Self.Count - 1) do begin
		If (Self.Data[Iter] <> NIL) then begin
			Self.Data[Dest] := Self.Data[Iter];
			Dest += 1
		end
	end;
	Self.Count := Dest;

	For Iter := Self.Count to (Self.Capacity - 1) do
		Self.Data[Iter] := NIL
End;

Procedure GenericBuffer.Flush();
Var
	Idx: uInt;
Begin
	If (Self.Count = 0) then Exit;

	For Idx := 0 to (Self.Count - 1) do
		Self.Data[Idx] := NIL;

	Self.Count := 0
End;

Procedure GenericBuffer.Flush(Callback: TCallback);
Var
	Idx: uInt;
Begin
	If (Self.Count = 0) then Exit;

	For Idx := 0 to (Self.Count - 1) do
		If Self.Data[Idx] <> NIL then begin
			Callback(Self.Data[Idx]);
			Self.Data[Idx] := NIL;
		end;

	Self.Count := 0
End;

Function GenericBuffer.GetCount(): uInt;
Begin
	Result := Self.Count
End;

Function GenericBuffer.GetCapacity(): uInt;
Begin
	Result := Self.Capacity
End;

Constructor GenericBuffer.Create(ResizeStep: uInt);
Begin
	Self.StepSize := ResizeStep;

	SetLength(Self.Data, 0);
	Self.Capacity := 0;
	Self.Count := 0
End;

Destructor GenericBuffer.Destroy();
Begin
	SetLength(Self.Data, 0)
End;

end.
