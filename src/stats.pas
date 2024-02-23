(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2024 suve (a.k.a. Artur Frenszek Iwicki)
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
Unit Stats;

{$INCLUDE defines.inc}

Interface

Type
	Generic TOptional<Thing> = object
		Private
			Value: Thing;
			IsSet: Boolean;
		Public
			Type ThingPtr = ^Thing;

			Function Get(Ptr: ThingPtr):Boolean;
			Procedure Modify(Delta: Thing);

			Function ToString():AnsiString;

			Procedure SetTo(NewValue: Thing);
			Procedure Unset();
	end;

	TOptionalUInt = specialize TOptional<uInt>;
	POptionalUInt = ^TOptionalUInt;

Var
	TotalTime: TOptionalUInt;
	TimesDied: TOptionalUInt;
	HitsTaken: TOptionalUInt;
	ShotsFired: TOptionalUInt;
	ShotsHit: TOptionalUInt;

Procedure ZeroAll();
Procedure UnsetAll();


Implementation

Function TOptional.Get(Ptr: ThingPtr):Boolean;
Begin
	If (Ptr <> Nil) and (Self.IsSet) then Ptr^ := Self.Value;
	Result := Self.IsSet
End;

Function TOptional.ToString():AnsiString;
Begin
	If Self.IsSet then
		WriteStr(Result, Self.Value)
	else
		WriteStr(Result, '???')
End;

Procedure TOptional.Modify(Delta: Thing);
Begin
	If Self.IsSet then Self.Value += Delta
End;

Procedure TOptional.SetTo(NewValue: Thing);
Begin
	Self.Value := NewValue;
	Self.IsSet := True
End;

Procedure TOptional.Unset();
Begin
	Self.IsSet := False
End;

Procedure ZeroAll();
Begin
	TotalTime.SetTo(0);
	TimesDied.SetTo(0);
	HitsTaken.SetTo(0);
	ShotsFired.SetTo(0);
	ShotsHit.SetTo(0);
End;

Procedure UnsetAll();
Begin
	TotalTime.Unset();
	TimesDied.Unset();
	HitsTaken.Unset();
	ShotsFired.Unset();
	ShotsHit.Unset();
End;

End.

