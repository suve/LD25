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
Unit controllers;

{$INCLUDE defines.inc}

Interface

Uses
	SDL2;

Var
	Controller: PSDL_GameController;

Procedure InitControllers();


Implementation

Uses
	ctypes;

Var
	// TODO: Replace this with some kind of sparse array that can handle
	//       elements being added and removed.
	List: Array[0..255] of PSDL_GameController;

Procedure AddController(Con: PSDL_GameController);
Const
	POWER_TEXT: Array[SDL_JOYSTICK_POWER_UNKNOWN..SDL_JOYSTICK_POWER_WIRED] of AnsiString = (
		'unknown', 'empty', 'low', 'medium', 'full', 'wired'
	);
Var
	Joy: PSDL_Joystick;
	ID: TSDL_JoystickID;
Begin
	Joy := SDL_GameControllerGetJoystick(Con);
	ID := SDL_JoystickInstanceID(Joy);

	List[ID] := Con;
	SDL_Log('Opened game controller #%ld "%s" (%d axes, %d buttons, %d rumble; power: %s)', [
		clong(ID),
		SDL_GameControllerName(Con),
		SDL_JoystickNumAxes(Joy),
		SDL_JoystickNumButtons(Joy),
		SDL_GameControllerHasRumble(Con),
		PChar(POWER_TEXT[SDL_JoystickCurrentPowerLevel(Joy)])
	])
End;

Procedure InitControllers();
Var
	Idx, Count: sInt;
	Con: PSDL_GameController;
Begin
	// Clear out list of connected controllers
	For Idx := Low(List) to High(List) do List[Idx] := NIL;
	// Clear out active controller pointer
	Controller := NIL;

	SDL_Log('Initializing SDL game controller subsystem...', []);
	If(SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) <> 0) then begin
		SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to initialize SDL2 game controller subsystem! Error details: %s', [SDL_GetError()]);
		Exit()
	end;
	SDL_Log('Game controller subsystem initialized successfully.', []);

	Count := SDL_NumJoysticks();
	If(Count < 0) then begin
		SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to get joystick count: %s', [SDL_GetError()]);
		Exit()
	end;

	For Idx := 0 to (Count - 1) do begin
		If(SDL_IsGameController(Idx) <> SDL_TRUE) then Continue;

		Con := SDL_GameControllerOpen(Idx);
		If(Con = NIL) then begin
			SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to open game controller #%d (%s): %s', [
				cint(Idx),
				SDL_GameControllerNameForIndex(Idx),
				SDL_GetError()
			]);
			Continue
		end;
	
		AddController(Con);

		// Set first opened controller as active
		If(Controller = NIL) then Controller := Con
	end
end;

End.
