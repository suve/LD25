(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2024 suve (a.k.a. Artur Frenszek Iwicki)
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
Unit Timekeeping; 

{$INCLUDE defines.inc}


Interface

Uses
	SysUtils;

Const
	FPS_LIMIT = 120;
	TICKS_MINIMUM = 1000 div FPS_LIMIT;

// Used mainly during initialization,
// as the game switches to SDL-based timekeeping later.
Function GetTimeStamp(): TTimeStamp;
Function TimestampDiffMillis(Const First, Second: TTimeStamp): sInt;

// Get the current number of ticks.
// This number will stay constant until the next call to AdvanceTime().
Function GetTicks(): uInt;

// Advance the time and report the number of ticks passed.
// This will ensure that at least TICKS_MINIMUM milliseconds have passed since the previous call.
Function AdvanceTime(): uInt;


Implementation

Uses
	SDL2, ctypes;

Var
	Ticks: uInt;

Function AdvanceTime(): uInt;
Var
	NewTicks: uInt;
Begin
	While True do begin
		{$IF SIZEOF(NativeUInt) >= SIZEOF(cuint64)}
			NewTicks := SDL_GetTicks64();
		{$ELSEIF SIZEOF(NativeUInt) >= SIZEOF(cuint32)}
			NewTicks := SDL_GetTicks();
		{$ELSE}
			{$ERROR NativeUInt is smaller than 32 bits}
		{$ENDIF}
		If((NewTicks - Ticks) >= TICKS_MINIMUM) then Break;
		SDL_Delay(1)
	end;
	
	Result := NewTicks - Ticks;
	Ticks := NewTicks
End;

Function GetTicks(): uInt;
Begin
	Result := Ticks
End;

Function GetTimeStamp(): TTimeStamp;
Begin
	Result := DateTimeToTimeStamp(Now())
End;

Function TimestampDiffMillis(Const First, Second: TTimeStamp): sInt;
Var
	Diff: Comp;
Begin
	Diff := TimeStampToMSecs(Second) - TimeStampToMSecs(First);
	{$IFDEF CPUI386}
		(*
		 * On i386, the Comp type cannot be cast to an sInt, resulting in a compilation error.
		 * As a (rather dirty) workaround, force a cast to a floating-point value and then cast back to integer.
		 *)
		Result := Trunc(Extended(Diff))
	{$ELSE}
		Result := sInt(Diff)
	{$ENDIF}
End;

Initialization
	Ticks := 0;

End.
