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
Unit Menus.Gamepad;

{$INCLUDE defines.inc}

Interface

Procedure ConfigureGamepad();


Implementation

Uses
	SDL2,
	Assets, Colours, Controllers, Fonts, Menus, Rendering, Shared, Timekeeping
	{$IFDEF LD25_MOBILE}, TouchControls {$ENDIF};

Procedure ConfigureGamepad();
Const
	DEAD_ZONE_MIN = 0;
	DEAD_ZONE_MAX = 75;
	DEAD_ZONE_STEP = 5;

	MAX_NAMES = 4;
Var
	ControllerCount: sInt;
	ControllerNames: Array[0..(MAX_NAMES - 1)] of AnsiString;

	AssignToBind: PControllerBinding;
	AssignTextColour: PSDL_Colour;
	DeadZoneStr, LeftStr, RightStr: AnsiString;

	Procedure ChangeDeadZone();
	Var
		Percentage: uInt;
	Begin
		Percentage := Trunc(DeadZone.Percentage * 100);
		Percentage := Percentage - (Percentage mod DEAD_ZONE_STEP);
		Percentage := Percentage + DEAD_ZONE_STEP;
		If(Percentage > DEAD_ZONE_MAX) then Percentage := DEAD_ZONE_MIN;

		Controllers.DeadZone.Percentage := Percentage / 100;
		WriteStr(DeadZoneStr, Percentage, '%')
	End;

	Procedure ToggleRumble();
	Begin
		Controllers.RumbleEnabled := Not Controllers.RumbleEnabled;
		Controllers.RumbleLastUsed($3FFF, $AAAA, 480)
	End;

	Procedure MaybeAssignAxis(Ev: PSDL_Event);
	Begin
		If(AssignToBind = NIL) then Exit;

		// Left thumbstick is hard-coded for movement
		If(Ev^.cAxis.Axis = SDL_CONTROLLER_AXIS_LEFTX) or (Ev^.cAxis.Axis = SDL_CONTROLLER_AXIS_LEFTY) then Exit;

		// Respect the dead zone setting when assigning
		If(Ev^.cAxis.Value > -Controllers.DeadZone.Value) and (Ev^.cAxis.Value < +Controllers.DeadZone.Value) then Exit;

		AssignToBind^.SetAxis(Ev^.cAxis.Axis, Ev^.cAxis.Value);
		LeftStr := PadShootLeft.ToPrettyString();
		RightStr := PadShootRight.ToPrettyString();
		AssignToBind := NIL
	End;

	Procedure MaybeAssignButton(Ev: PSDL_Event);
	Begin
		If(AssignToBind = NIL) then Exit;

		AssignToBind^.SetButton(Ev^.cButton.Button);

		LeftStr := PadShootLeft.ToPrettyString();
		RightStr := PadShootRight.ToPrettyString();
		AssignToBind := NIL
	End;

	Procedure UpdateControllerList();
	Var
		NameIdx: sInt;
	Begin
		GetControllerNames(ControllerCount, ControllerNames);

		If(ControllerCount > 0) then begin
			For NameIdx := 0 to (ControllerCount - 1) do
				ControllerNames[NameIdx] := UpCase(ControllerNames[NameIdx]);
			AssignTextColour := @MenuActiveColour
		end else begin
			AssignTextColour := @MenuInactiveColour;
			AssignToBind := NIL
		end
	End;

Const
	BLINK_PERIOD = 575;

	PAD_WIDTH = RESOL_W div 4;
	HORIZ_OFFSET = (RESOL_W * 7) div 40;

	PAD_X = (RESOL_W div 2) - HORIZ_OFFSET - (PAD_WIDTH div 2);
	SETTINGS_X = (RESOL_W div 2) + HORIZ_OFFSET;

	RumbleStr: Array[Boolean] of AnsiString = ('DISABLED', 'ENABLED');
Var
	Idx, YPos: uInt;
	DeadRect, RumbleRect, LeftRect, RightRect: TSDL_Rect;
	PadRect: TSDL_Rect;
Begin
	AssignToBind := NIL;

	LeftStr := PadShootLeft.ToPrettyString();
	RightStr := PadShootRight.ToPrettyString();
	WriteStr(DeadZoneStr, Trunc(DeadZone.Percentage * 100), '%');
	UpdateControllerList();

	DeadRect.X := (RESOL_W div 4);
	DeadRect.W := (RESOL_W div 2);
	DeadRect.H := (Font^.CharH * 2) + ((3 * (Font^.CharH + Font^.SpacingY)) div 2);
	RumbleRect := DeadRect;
	LeftRect := DeadRect;
	RightRect := DeadRect;

	PadRect.X := PAD_X;
	PadRect.W := PAD_WIDTH;
	PadRect.H := (GamepadGfx^.H * GamepadGfx^.W) div PAD_WIDTH;

	While True do begin
		Rendering.BeginFrame();
		DrawTitle();

		YPos := TitleGfx^.H;
		Font^.Scale := 2;
		PrintText('GAMEPAD SETTINGS',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP, @WhiteColour);

		Font^.Scale := 1;
		YPos += (5 * (Font^.CharH + Font^.SpacingY)) div 2;
		DeadRect.Y := YPos;
		PrintText('D - DEAD ZONE', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @MenuActiveColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		PrintText(DeadZoneStr, Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		YPos += (4 * (Font^.CharH + Font^.SpacingY)) div 2;
		RumbleRect.Y := YPos;
		PrintText('V - VIBRATION', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @MenuActiveColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		PrintText(RumbleStr[Controllers.RumbleEnabled], Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		YPos += (4 * (Font^.CharH + Font^.SpacingY)) div 2;
		LeftRect.Y := YPos;
		PrintText('L - SHOOT LEFT', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, AssignTextColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		If(AssignToBind = @PadShootLeft) then begin
			If(((GetTicks() div BLINK_PERIOD) mod 2) = 0) then
				PrintText('???', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);
		end else
			PrintText(LeftStr, Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		YPos += (4 * (Font^.CharH + Font^.SpacingY)) div 2;
		RightRect.Y := YPos;
		PrintText('R - SHOOT RIGHT', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, AssignTextColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		If(AssignToBind = @PadShootRight) then begin
			If(((GetTicks() div BLINK_PERIOD) mod 2) = 0) then
				PrintText('???', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);
		end else
			PrintText(RightStr, Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		Font^.Scale := 2;
		YPos += (5 * (Font^.CharH + Font^.SpacingY)) div 2;
		PrintText('ACTIVE CONTROLLERS',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP, @WhiteColour);

		Font^.Scale := 1;
		YPos += (5 * (Font^.CharH + Font^.SpacingY)) div 2;
		If(ControllerCount > 0) then begin
			For Idx := 0 to (ControllerCount - 1) do begin
				PrintText(ControllerNames[Idx], Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @GreyColour);
				YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2
			end
		end else begin
			PrintText('(NONE)', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @GreyColour)
		end;

		PadRect.Y := ((DeadRect.Y + RightRect.Y + RightRect.H) div 2) - (PadRect.H div 2);
		SDL_RenderCopy(Renderer, GamepadGfx^.Tex, NIL, @PadRect);

		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If ((Ev.Key.Keysym.Sym = SDLK_Escape) or (Ev.Key.Keysym.Sym = SDLK_AC_BACK)) then begin
					If(AssignToBind <> NIL) then
						AssignToBind := NIL
					else
						Exit()
				end else
				If (Ev.Key.Keysym.Sym = SDLK_D) then begin
					ChangeDeadZone()
				end else
				If (Ev.Key.Keysym.Sym = SDLK_V) then begin
					ToggleRumble()
				end else
				If (Ev.Key.Keysym.Sym = SDLK_L) then begin
					If(ControllerCount > 0) then AssignToBind := @PadShootLeft
				end else
				If (Ev.Key.Keysym.Sym = SDLK_R) then begin
					If(ControllerCount > 0) then AssignToBind := @PadShootRight
				end else
			end else
			If (Ev.Type_ = SDL_MouseButtonDown) then begin
				{$IFDEF LD25_MOBILE} TranslateMouseEventCoords(@Ev); {$ENDIF}
				If(MouseInRect(DeadRect)) then begin
					ChangeDeadZone()
				end else
				If(MouseInRect(RumbleRect)) then begin
					ToggleRumble()
				end else
				If(MouseInRect(LeftRect)) then begin
					If(ControllerCount > 0) then AssignToBind := @PadShootLeft
				end else
				If(MouseInRect(RightRect)) then begin
					If(ControllerCount > 0) then AssignToBind := @PadShootRight
				end else
			end else
			If (Ev.Type_ = SDL_ControllerAxisMotion) then begin
				Controllers.SetLastUsedID(Ev.cAxis.Which);
				MaybeAssignAxis(@Ev)
			end else
			If (Ev.Type_ = SDL_ControllerButtonUp) then begin
				Controllers.SetLastUsedID(Ev.cButton.Which);
				MaybeAssignButton(@Ev)
			end else
			If (Ev.Type_ = SDL_ControllerDeviceAdded) or (Ev.Type_ = SDL_ControllerDeviceRemoved) then begin
				Controllers.HandleDeviceEvent(@Ev);
				UpdateControllerList();
			end else
			If (Ev.Type_ = SDL_JoyBatteryUpdated) then begin
				Controllers.HandleBatteryEvent(@Ev)
			end else
			{$IFDEF LD25_MOBILE}
			If (Ev.Type_ = SDL_FingerUp) or (Ev.Type_ = SDL_FingerDown) or (Ev.Type_ = SDL_FingerMotion) then begin
				TouchControls.HandleEvent(@Ev)
			end else
			{$ENDIF}
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end;
	end;
End;

End.
