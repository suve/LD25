(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2022 suve (a.k.a. Artur Frenszek-Iwicki)
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
Unit LineReader;

{$INCLUDE defines.inc}

Interface

Uses
	SDL2;

Type
	PLineReader = ^TLineReader;
	TLineReader = object
		Private
			rw: PSDL_RWops;
			Buffer: AnsiString;
			Finished: Boolean;

			Procedure FillBuffer();
			Constructor Create();
		Public
			Function GetLine(): AnsiString;
			Function IsFinished(): Boolean;

			Destructor Destroy();
	end;

Function NewLineReader(Path: AnsiString): PLineReader;

Implementation

Procedure TLineReader.FillBuffer();
Const
	FILL_STEP = 256;
Var
	buf: Array[0..(FILL_STEP-1)] of Char;
	BytesRead: UInt;
Begin
	If (Self.Finished) then Exit();

	BytesRead := SDL_RWread(Self.rw, PChar(buf), 1, FILL_STEP);
	Self.Buffer += Copy(buf, 1, BytesRead);
	Self.Finished := (BytesRead < FILL_STEP)
End;

Function TLineReader.GetLine(): AnsiString;
Var
	Newline: UInt;
Begin
	Newline := Pos(#10, Self.Buffer);
	If(Newline > 0) then begin
		Result := Copy(Self.Buffer, 1, Newline - 1);
		Delete(Self.Buffer, 1, Newline);
		Exit()
	end;

	If(Not Self.Finished) then begin
		Self.FillBuffer();
		Result := Self.GetLine();
		Exit()
	end;

	Result := Self.Buffer;
	Self.Buffer := ''
End;

Function TLineReader.IsFinished(): Boolean;
Begin
	Result := (Self.Finished) and (Self.Buffer = '')
End;

Constructor TLineReader.Create();
Begin
	Self.Buffer := '';
	Self.Finished := False
End;

Destructor TLineReader.Destroy();
Begin
	SDL_RWclose(Self.rw)
End;

Function NewLineReader(Path: AnsiString): PLineReader;
Var
	rw: PSDL_RWops;
Begin
	rw := SDL_RWfromFile(PChar(Path), PChar('r'));
	If(rw = NIL) then Exit(NIL);

	New(Result, Create());
	Result^.rw := rw
End;

end.
