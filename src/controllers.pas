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
	ctypes, SDL2;

Type
	TControllerBindingValidity = (
		CBV_INVALID,
		CBV_AXIS,
		CBV_BUTTON
	);

	PControllerBinding = ^TControllerBinding;
	TControllerBinding = object
		Axis: TSDL_GameControllerAxis;
		Negative: Boolean;

		Button: TSDL_GameControllerButton;

		Function AxisTriggered(Value: cint16): Boolean;
		Function IsValid(): TControllerBindingValidity;

		Procedure SetAxis(Value: TSDL_GameControllerAxis; Direction: cint32);
		Procedure SetButton(Value: TSDL_GameControllerButton);
		Procedure Invalidate();

		Function ToPrettyString(): AnsiString;

		Function Serialize(): AnsiString;
		Procedure Deserialize(From: AnsiString);
	end;

	PControllerInfo = ^TControllerInfo;
	TControllerInfo = record
		DeviceID: cint32;
		JoystickID: TSDL_JoystickID;
		Name: AnsiString;
	end;

	PPercentageValue = ^TPercentageValue;
	TPercentageValue = object
		Private
			Raw: cint16;
			Perc: Single;

			Procedure SetRaw(Arg: cint16);
			Procedure SetPerc(Arg: Single);

		Public
			Property Value: cint16
				read Raw write SetRaw;
			Property Percentage: Single
				read Perc write SetPerc;
	end;

Var
	DeadZone: TPercentageValue;
	RumbleEnabled: Boolean;

Procedure InitControllers();
Procedure HandleBatteryEvent(Ev: PSDL_Event);
Procedure HandleDeviceEvent(Ev: PSDL_Event);

Function GetLastUsed(): PSDL_GameController;
Function GetLastUsedID(): TSDL_JoystickID;
Procedure SetLastUsedID(ID: TSDL_JoystickID);
Procedure RumbleLastUsed(LowFreq, HighFreq: cuint16; DurationMs: cuint32);

Procedure EnumerateControllers(Out Count: sInt; Out Info: Array of TControllerInfo);


Implementation

Uses
	SysUtils,
	Toast;

Var
	LastUsedID: TSDL_JoystickID;
	LastUsedCon: PSDL_GameController;

Function GetLastUsed(): PSDL_GameController;
Begin
	Result := LastUsedCon
End;

Function GetLastUsedID(): TSDL_JoystickID;
Begin
	Result := LastUsedID
End;

Procedure SetLastUsedID(ID: TSDL_JoystickID);
Begin
	If(ID = LastUsedID) then Exit;

	LastUsedID := ID;
	LastUsedCon := SDL_GameControllerFromInstanceID(ID)
End;

Procedure RumbleLastUsed(LowFreq, HighFreq: cuint16; DurationMs: cuint32);
Begin
	If(RumbleEnabled) and (LastUsedCon <> NIL) then
		SDL_GameControllerRumble(LastUsedCon, LowFreq, HighFreq, DurationMs)
End;

Procedure AddController(DeviceIndex: cint);
Const
	POWER_TEXT: Array[SDL_JOYSTICK_POWER_UNKNOWN..SDL_JOYSTICK_POWER_WIRED] of AnsiString = (
		'unknown', 'empty', 'low', 'medium', 'full', 'wired'
	);
Var
	Joy: PSDL_Joystick;
	ID: TSDL_JoystickID;

	Con: PSDL_GameController;
	Name: PChar;
Begin
	Con := SDL_GameControllerOpen(DeviceIndex);
	If(Con = NIL) then begin
		SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to open device #%d (%s): %s', [
			cint(DeviceIndex),
			SDL_GameControllerNameForIndex(DeviceIndex),
			SDL_GetError()
		]);
		Exit
	end;

	Joy := SDL_GameControllerGetJoystick(Con);
	ID := SDL_JoystickInstanceID(Joy);

	Name := SDL_GameControllerName(Con);
	SDL_Log('Opened device #%d / controller #%ld "%s" (%d axes, %d buttons, %d rumble; power: %s)', [
		cint(DeviceIndex),
		clong(ID),
		Name,
		SDL_JoystickNumAxes(Joy),
		SDL_JoystickNumButtons(Joy),
		SDL_GameControllerHasRumble(Con),
		PChar(POWER_TEXT[SDL_JoystickCurrentPowerLevel(Joy)])
	]);
	Toast.Show(TH_CONTROLLER_FOUND, Name)
End;

Procedure RemoveController(JoyID: TSDL_JoystickID);
Var
	Con: PSDL_GameController;
	Name: AnsiString;
Begin
	If(LastUsedID = JoyID) then begin
		LastUsedID := -1;
		LastUsedCon := NIL
	end;

	Con := SDL_GameControllerFromInstanceID(JoyID);
	If(Con = NIL) then begin
		SDL_LogWarn(
			SDL_LOG_CATEGORY_APPLICATION,
			'SDL says it removed controller #%ld, but no such controller exists',
			[clong(JoyID)]
		);
		Exit
	end;

	Name := SDL_GameControllerName(Con);
	SDL_GameControllerClose(Con);

	SDL_Log('Closed controller #%ld "%s"', [clong(JoyID), PChar(Name)]);
	Toast.Show(TH_CONTROLLER_LOST, Name)
End;

Procedure HandleBatteryEvent(Ev: PSDL_Event);
Var
	Con: PSDL_GameController;
	Header: TToastHeader;
Begin
	Case Ev^.jBattery.Level of
		SDL_JOYSTICK_POWER_LOW:
			Header := TH_BATTERY_LOW;
		SDL_JOYSTICK_POWER_EMPTY:
			Header := TH_BATTERY_CRITICAL;
		otherwise
			Exit
	end;
	
	Con := SDL_GameControllerFromInstanceID(Ev^.jBattery.Which);
	If(Con = NIL) then Exit;

	Toast.Show(Header, SDL_GameControllerName(Con))
End;

Procedure HandleDeviceEvent(Ev: PSDL_Event);
Var
	Con: PSDL_GameController;
Begin
	If(Ev^.Type_ = SDL_ControllerDeviceAdded) then
		AddController(Ev^.cDevice.Which)
	else
	If(Ev^.Type_ = SDL_ControllerDeviceRemoved) then
		RemoveController(Ev^.cDevice.Which)
	else
End;

Procedure InitControllers();
Var
	Idx, Count: sInt;
Begin
	LastUsedID := -1;
	LastUsedCon := NIL;

	SDL_Log('Initializing SDL2 game controller subsystem...', []);
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

	For Idx := 0 to (Count - 1) do
		If(SDL_IsGameController(Idx) = SDL_TRUE) then
			AddController(Idx)
end;

Procedure EnumerateControllers(Out Count: sInt; Out Info: Array of TControllerInfo);
Var
	DevCount, DevIdx: cint32;
	JoyName: PChar;
Begin
	Count := 0;
	If(Length(Info) = 0) then Exit;

	DevCount := SDL_NumJoysticks();
	If(DevCount < 0) then begin
		Count := -1;
		Exit
	end;

	For DevIdx := 0 to (DevCount-1) do begin
		If(SDL_IsGameController(DevIdx) <> SDL_TRUE) then Continue;

		Info[Count].DeviceID := DevIdx;
		Info[Count].JoystickID := SDL_JoystickGetDeviceInstanceID(DevIdx);

		JoyName := SDL_JoystickNameForIndex(DevIdx);
		If(JoyName <> NIL) then
			Info[Count].Name := JoyName
		else
			Info[Count].Name := 'Unknown device';

		Count += 1;
		If(Count >= Length(Info)) then Break
	end
End;

Procedure TPercentageValue.SetRaw(Arg: cint16);
Begin
	If(Arg < 0) then Arg := 0;

	Self.Raw := Arg;
	Self.Perc := Self.Raw / $7FFF
End;

Procedure TPercentageValue.SetPerc(Arg: Single);
Begin
	If(Arg < 0.0) then
		Arg := 0.0
	else if(Arg > 1.0) then
		Arg := 1.0;

	Self.Perc := Arg;
	Self.Raw := Trunc($7FFF * Self.Perc)
End;

Function TControllerBinding.AxisTriggered(Value: cint16): Boolean;
Begin
	If(Not Self.Negative) then
		Result := Value > (+DeadZone.Value)
	else
		Result := Value < (-DeadZone.Value)
End;

Procedure TControllerBinding.SetAxis(Value: TSDL_GameControllerAxis; Direction: cint32);
Begin
	Self.Axis := Value;
	Self.Negative := (Direction < 0);

	Self.Button := SDL_CONTROLLER_BUTTON_INVALID
End;

Procedure TControllerBinding.SetButton(Value: TSDL_GameControllerButton);
Begin
	Self.Axis := SDL_CONTROLLER_AXIS_INVALID;
	Self.Negative := False;

	Self.Button := Value
End;

Procedure TControllerBinding.Invalidate();
Begin
	Self.SetButton(SDL_CONTROLLER_BUTTON_INVALID)
End;

Function TControllerBinding.IsValid(): TControllerBindingValidity;
Begin
	If(Self.Axis > SDL_CONTROLLER_AXIS_INVALID) and (Self.Axis < SDL_CONTROLLER_AXIS_MAX)
	then
		Result := CBV_AXIS
	else
	If(Self.Button > SDL_CONTROLLER_BUTTON_INVALID) and (Self.Button < SDL_CONTROLLER_BUTTON_MAX)
	then
		Result := CBV_BUTTON
	else
		Result := CBV_INVALID
End;

Function TControllerBinding.ToPrettyString(): AnsiString;
Var
	ThumbBitmask: uInt;
Begin
	Case Self.IsValid() of
		CBV_AXIS: begin
			If(Self.Axis <= SDL_CONTROLLER_AXIS_RIGHTY) then begin
				ThumbBitmask := 0;
				// Axis direction
				If(Self.Negative) then ThumbBitmask += $01;
				// Horizontal (0) or vertical (1) axis
				If((Self.Axis mod 2) = 1) then ThumbBitmask += $02;
				// Left (0) or right (1) axis
				If((Self.Axis div 2) = 1) then ThumbBitmask += $04;

				Case ThumbBitmask of
					0: Result := 'LEFT STICK/RIGHT';
					1: Result := 'LEFT STICK/LEFT';
					2: Result := 'LEFT STICK/DOWN';
					3: Result := 'LEFT STICK/UP';
					4: Result := 'RIGHT STICK/RIGHT';
					5: Result := 'RIGHT STICK/LEFT';
					6: Result := 'RIGHT STICK/DOWN';
					7: Result := 'RIGHT STICK/UP';
				end
			end else
			If(Self.Axis = SDL_CONTROLLER_AXIS_TRIGGERLEFT) then
				Result := 'LEFT TRIGGER'
			else
				Result := 'RIGHT TRIGGER'
		end;

		CBV_BUTTON:
			Result := UpCase(SDL_GameControllerGetStringForButton(Self.Button)) + ' BUTTON';

		CBV_INVALID:
			Result := '(UNASSIGNED)'
	end
End;

Function TControllerBinding.Serialize(): AnsiString;
Const
	AXIS_PREFIX: Array[Boolean] of ShortString = ('ap', 'an');
Begin
	Case Self.IsValid() of
		CBV_AXIS:
			WriteStr(Result, AXIS_PREFIX[Self.Negative], Self.Axis);

		CBV_BUTTON:
			WriteStr(Result, 'bt', Self.Button);

		CBV_INVALID:
			Result := 'X'
	end
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
		'ap': Self.SetAxis(StrToIntDef(From, SDL_CONTROLLER_AXIS_INVALID), +1);
		'an': Self.SetAxis(StrToIntDef(From, SDL_CONTROLLER_AXIS_INVALID), -1);
		'bt': Self.SetButton(StrToIntDef(From, SDL_CONTROLLER_BUTTON_INVALID));
		otherwise begin
			Self.Axis := SDL_CONTROLLER_AXIS_INVALID;
			Self.Button := SDL_CONTROLLER_BUTTON_INVALID
		end
	end;
End;

End.
