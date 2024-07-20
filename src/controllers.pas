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

Const
	CONTROLLER_DEAD_ZONE = (SDL_JOYSTICK_AXIS_MAX) div 4;

Type
	TControllerBinding = object
		Axis: TSDL_GameControllerAxis;
		Button: TSDL_GameControllerButton;

		Procedure SetAxis(Value: TSDL_GameControllerAxis);
		Procedure SetButton(Value: TSDL_GameControllerButton);

		Function Serialize(): AnsiString;
		Procedure Deserialize(From: AnsiString);
	end;

Var
	Controller: PSDL_GameController;

Procedure InitControllers();
Procedure HandleDeviceEvent(Ev: PSDL_Event);


Implementation

Uses
	ctypes, SysUtils,
	Toast;

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
	Name: PChar;
Begin
	Joy := SDL_GameControllerGetJoystick(Con);
	ID := SDL_JoystickInstanceID(Joy);

	List[ID] := Con;

	Name := SDL_GameControllerName(Con);
	SDL_Log('Opened game controller #%ld "%s" (%d axes, %d buttons, %d rumble; power: %s)', [
		clong(ID),
		Name,
		SDL_JoystickNumAxes(Joy),
		SDL_JoystickNumButtons(Joy),
		SDL_GameControllerHasRumble(Con),
		PChar(POWER_TEXT[SDL_JoystickCurrentPowerLevel(Joy)])
	]);

	// If there is no active controller, use this one
	If(Controller = NIL) then begin
		Toast.Show('CONTROLLER FOUND', Name);
		Controller := Con
	end
End;

Procedure SwitchActiveController();
Var
	Idx: uInt;
	JoyID: TSDL_JoystickID;
Begin
	Controller := NIL;

	For Idx := Low(List) to High(List) do begin
		If(List[Idx] <> NIL) then begin
			Controller := List[Idx];
			JoyID := SDL_JoystickInstanceID(SDL_GameControllerGetJoystick(Controller));

			SDL_Log('Switched active controller to #%ld "%s"', [
				clong(JoyID),
				SDL_GameControllerName(Controller)
			]);
			Exit
		end
	end;

	SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'No active controllers found!', [])
End;

Procedure RemoveController(Con: PSDL_GameController);
Var
	JoyID: TSDL_JoystickID;
	Name: AnsiString;
Begin
	JoyID := SDL_JoystickInstanceID(SDL_GameControllerGetJoystick(Con));
	Name := SDL_GameControllerName(Con);

	SDL_Log('Closed game controller #%ld "%s"', [clong(JoyID), PChar(Name)]);
	SDL_GameControllerClose(Con);

	List[JoyID] := NIL;
	If(Con = Controller) then begin
		SwitchActiveController();
		If(Controller <> NIL) then
			Toast.Show('CONTROLLER SWITCHED', SDL_GameControllerName(Controller))
		else
			Toast.Show('CONTROLLER LOST', Name)
	end
End;

Procedure HandleDeviceEvent(Ev: PSDL_Event);
Var
	Con: PSDL_GameController;
Begin
	If(Ev^.Type_ = SDL_ControllerDeviceAdded) then begin
		Con := SDL_GameControllerOpen(Ev^.cDevice.Which);
		If(Con <> NIL) then AddController(Con)
	end else
	If(Ev^.Type_ = SDL_ControllerDeviceRemoved) then begin
		Con := List[Ev^.cDevice.Which];
		If(Con <> NIL) then RemoveController(Con)
	end else
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
	
		AddController(Con)
	end
end;

Procedure TControllerBinding.SetAxis(Value: TSDL_GameControllerAxis);
Begin
	Self.Axis := Value;
	Self.Button := SDL_CONTROLLER_BUTTON_INVALID
End;

Procedure TControllerBinding.SetButton(Value: TSDL_GameControllerButton);
Begin
	Self.Axis := SDL_CONTROLLER_AXIS_INVALID;
	Self.Button := Value
End;

Function TControllerBinding.Serialize(): AnsiString;
Var
	AxisValid, ButtonValid: Boolean;
Begin
	AxisValid := (Self.Axis > SDL_CONTROLLER_AXIS_INVALID) and (Self.Axis < SDL_CONTROLLER_AXIS_MAX);
	ButtonValid := (Self.Button > SDL_CONTROLLER_BUTTON_INVALID) and (Self.Button < SDL_CONTROLLER_BUTTON_MAX);
	
	If(Not (AxisValid xor ButtonValid)) then Exit('X');
	
	If(AxisValid) then
		WriteStr(Result, 'ax', Self.Axis)
	else
		WriteStr(Result, 'bt', Self.Button)
End;

Procedure TControllerBinding.Deserialize(From: AnsiString);
Var
	Prefix: AnsiString;
Begin
	// This serves as a very stupid workaround for an issue
	// where the .ini parser makes it quite a pain in the bottom
	// to dinstinguish between a missing value and an empty value.
	If(From = '') then Exit();

	Prefix := Copy(From, 1, 2);
	Delete(From, 1, 2);

	Case Prefix of
		'ax': Self.SetAxis(StrToIntDef(From, SDL_CONTROLLER_AXIS_INVALID));
		'bt': Self.SetButton(StrToIntDef(From, SDL_CONTROLLER_BUTTON_INVALID));
		otherwise begin
			Self.Axis := SDL_CONTROLLER_AXIS_INVALID;
			Self.Button := SDL_CONTROLLER_BUTTON_INVALID
		end
	end;
End;

End.
