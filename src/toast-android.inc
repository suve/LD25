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
Uses
	SDL2, ctypes;

Const
	Headers: Array[TToastHeader] of AnsiString = (
		'Controller found',
		'Controllers found',
		'Controller lost',
		'Battery low',
		'Battery critical'
	);

Var
	Visible: Boolean;

Procedure SetVisibility(NewValue: Boolean);
Begin
	Visible := NewValue
End;

Procedure Show(HeaderID: TToastHeader; Message: AnsiString);
Const
	DURATION_SHORT = 0;
	DURATION_LONG = 1;
Begin
	If Not Visible then Exit;

	Message := Headers[HeaderID] + ':' + #10 + Message;
	SDL_AndroidShowToast(PChar(Message), DURATION_LONG, -1, -1, -1)
End;

Procedure Render();
Begin
	// This is a no-op on Android
End;
