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

Procedure InitControllers();
Const
	POWER_TEXT: Array[SDL_JOYSTICK_POWER_UNKNOWN..SDL_JOYSTICK_POWER_WIRED] of AnsiString = (
		'unknown', 'empty', 'low', 'medium', 'full', 'wired'
	);
Var
	Idx, Count: sInt;
	Joy: PSDL_Joystick;
Begin
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

		Controller := SDL_GameControllerOpen(Idx);
		If(Controller = NIL) then begin
			SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to open game controller #%d (%s): %s', [
				cint(Idx),
				SDL_GameControllerNameForIndex(Idx),
				SDL_GetError()
			]);
			Continue
		end;

		Joy := SDL_GameControllerGetJoystick(Controller);
		SDL_Log('Opened game controller #%d "%s" (%d axes, %d buttons, %d rumble; power: %s)', [
			cint(Idx),
			SDL_GameControllerName(Controller),
			SDL_JoystickNumAxes(Joy),
			SDL_JoystickNumButtons(Joy),
			SDL_GameControllerHasRumble(Controller),
			PChar(POWER_TEXT[SDL_JoystickCurrentPowerLevel(Joy)])
		]);
	
		// Bail out with first controller we find
		Exit
	end
end;

End.
