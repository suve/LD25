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
Unit toast;

{$INCLUDE defines.inc}

Interface

Type
	TToastHeader = (
		TH_CONTROLLER_FOUND,
		TH_CONTROLLER_FOUND_MULTIPLE,
		TH_CONTROLLER_LOST,
		TH_BATTERY_LOW,
		TH_BATTERY_CRITICAL
	);

Procedure Show(HeaderID: TToastHeader; Message: AnsiString);
Procedure SetVisibility(NewValue: Boolean);

Procedure Render();


Implementation

{$IFDEF ANDROID}
	{$INCLUDE toast-android.inc}
{$ELSE}
	{$INCLUDE toast-other.inc}
{$ENDIF}

End.
