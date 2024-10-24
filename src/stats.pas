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

			Procedure Increase(Delta: Thing);
			Procedure Decrease(Delta: Thing);

			Function ToString():AnsiString;

			Procedure SetTo(NewValue: Thing);
			Procedure Unset();
	end;

	TOptionalUInt = specialize TOptional<uInt>;
	POptionalUInt = ^TOptionalUInt;

	TOptionalFloat = specialize TOptional<Double>;
	POptionalFloat = ^TOptionalFloat;

	TBestTimeCheck = (
		BTC_NOTIME, // Cannot determine (TotalTime was unset)
		BTC_FIRST,  // First time playing (BestTime was unset)
		BTC_WORSE,  // Slower than best time
		BTC_BETTER  // Best time beaten!
	);

Var
	// Game-wide stats
	BestTime: TOptionalUInt;

	// Save-specific stats
	TotalTime: TOptionalUInt;
	TimesDied: TOptionalUInt;
	HitsTaken: TOptionalUInt;
	KillsMade: TOptionalUInt;
	ShotsFired: TOptionalUInt;
	ShotsHit: TOptionalUInt;
	DistanceTravelled: TOptionalFloat;

Function CheckBestTime():TBestTimeCheck;

Procedure ZeroSaveStats();
Procedure UnsetSaveStats();
Procedure UnsetGlobalStats();


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

Procedure TOptional.Increase(Delta: Thing);
Begin
	If Self.IsSet then Self.Value += Delta
End;

Procedure TOptional.Decrease(Delta: Thing);
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

Procedure ZeroSaveStats();
Begin
	TotalTime.SetTo(0);
	TimesDied.SetTo(0);
	HitsTaken.SetTo(0);
	KillsMade.SetTo(0);
	ShotsFired.SetTo(0);
	ShotsHit.SetTo(0);
	DistanceTravelled.SetTo(0.0);
End;

Procedure UnsetSaveStats();
Begin
	TotalTime.Unset();
	TimesDied.Unset();
	HitsTaken.Unset();
	KillsMade.Unset();
	ShotsFired.Unset();
	ShotsHit.Unset();
	DistanceTravelled.Unset();
End;

Procedure UnsetGlobalStats();
Begin
	BestTime.Unset();
End;

Function CheckBestTime(): TBestTimeCheck;
Begin
	If Not TotalTime.IsSet then Exit(BTC_NOTIME);

	If Not BestTime.IsSet then begin
		BestTime.SetTo(TotalTime.Value);
		Exit(BTC_FIRST)
	end;

	If TotalTime.Value < BestTime.Value then begin
		BestTime.SetTo(TotalTime.Value);
		Result := BTC_BETTER
	end else
		Result := BTC_WORSE
End;

End.

