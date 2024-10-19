(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2024 suve (a.k.a. Artur Frenszek-Iwicki)
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
{$IFNDEF ANDROID}
	program ld25;
{$ELSE}
	library ld25;
{$ENDIF}

{$INCLUDE defines.inc}

uses
	SysUtils, Math, ctypes,
	SDL2, SDL2_image, SDL2_mixer,
	Assets, Colours, ConfigFiles, Controllers, FloatingText, Fonts, Game,
	Images, Objects, MathUtils, Menus, Rendering, Rooms, Shared, Slides, Stats,
	Timekeeping, Toast
	{$IFDEF LD25_MOBILE}, TouchControls {$ENDIF}
;


Var
	MenuChoice:Char;

Procedure PrintMenuText(Const Text:AnsiString; Const X, Y:sInt; Const AlignX: THorizontalAlign; Const Colour: PSDL_Colour; Out Rect: TSDL_Rect);
Var
	W, H: sInt;
Begin
	PrintText(Text, Assets.Font, X, Y, AlignX, ALIGN_TOP, Colour);
	
	Fonts.GetTextSize(Text, Assets.Font, W, H);
	Rect.W := W; Rect.H := H;
	
	Rect.Y := Y;
	Case (AlignX) of
		ALIGN_LEFT:   Rect.X := X;
		ALIGN_CENTRE: Rect.X := X - (Rect.W div 2);
		ALIGN_RIGHT:  Rect.X := X - Rect.W;
	end
End;

Function MouseInRect(Const Rect: TSDL_Rect):Boolean;
Begin
	Result := Overlap(Rect.X, Rect.Y, Rect.W, Rect.H, Ev.Button.X, Ev.Button.Y, 1, 1)
End;

Procedure LoadUpdate(Name:AnsiString;Perc:Double);
Const
	STARTX = RESOL_W div 32; SIZEX = RESOL_W - (STARTX*2);
	SIZEY = RESOL_H div 32; STARTY = RESOL_H - (SIZEY*3);
Var
	Rect:TSDL_Rect; Col:TSDL_Colour;
Begin 
	If(TitleGfx = NIL) or (Font = NIL) then Exit();
	
	Rendering.BeginFrame();
	DrawTitle();
	
	Font^.Scale := 2;
	PrintText(UpperCase(Name),Font,(RESOL_W div 2),STARTY-(Font^.CharW*2),ALIGN_CENTRE,ALIGN_MIDDLE,NIL);
	
	With Rect do begin X:=STARTX; Y:=STARTY; W:=SIZEX; H:=SIZEY end;
	DrawRectFilled(@Rect, @WhiteColour);
	
	Col.R := 64+Random(128);
	Col.G := 64+Random(128);
	Col.B := 64+Random(128);
	Col.A := 255;
	Rect.W := Trunc(SIZEX*Perc);
	DrawRectFilled(@Rect, @Col);
	
	Rendering.FinishFrame()
End;

{$IFNDEF LD25_MOBILE}
Procedure BindKeys();
Const
	KeyName : Array[TPlayerKey] of AnsiString = (
		'MOVE UP','MOVE RIGHT','MOVE DOWN','MOVE LEFT','SHOOT LEFT','SHOOT RIGHT',
		'PAUSE','VOLUME DOWN','VOLUME UP'
	);
	BLINK_PERIOD = 575;
	COLLISION_DURATION = 1200;
Var
	NewBind: Array[TPlayerKey] of TSDL_Keycode;
	History: Array[TPlayerKey] of AnsiString;

	K, Idx: TPlayerKey;
	Colour: TSDL_Colour;
	RowHeight, YPos: uInt;

	CollisionIdx: TPlayerKey;
	CollisionTicks: sInt;

	Bound: Boolean;
	dt, BlinkTicks: uInt;
Begin
	For Idx := Low(TPlayerKey) to High(TPlayerKey) do
		History[Idx] := UpCase(SDL_GetKeyName(KeyBind[Idx]));

	BlinkTicks := 0;
	CollisionTicks := 0;
	Bound:=False;
	K:=Low(TPlayerKey);
	While True do begin
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2;
		PrintText('SET KEY BINDINGS',Font,(RESOL_W div 2),TitleGfx^.H,ALIGN_CENTRE,ALIGN_TOP,NIL);

		RowHeight := (Font^.CharH + Font^.SpacingY) * Font^.Scale;
		YPos := TitleGfx^.H + RowHeight;
		YPos += (RESOL_H - YPos - (Length(KeyName) * RowHeight)) div 2;
		For Idx := Low(TPlayerKey) to High(TPlayerKey) do begin
			// Select base colour
			If Idx <> K then
				Colour := GreyColour
			else
				Colour := WhiteColour;

			// Change the colour to a red tint if we have a collision
			If (CollisionTicks > 0) and ((Idx = CollisionIdx) or (Idx = K)) then begin
				Colour.G := (Colour.G * (COLLISION_DURATION - CollisionTicks)) div COLLISION_DURATION;
				Colour.B := (Colour.B * (COLLISION_DURATION - CollisionTicks)) div COLLISION_DURATION
			end;

			PrintText(KeyName[Idx] + ': ', Font, (RESOL_W div 2), YPos, ALIGN_RIGHT, ALIGN_TOP, @Colour);

			If (Idx <> K) or (((BlinkTicks div BLINK_PERIOD) mod 2) = 0) then
				PrintText(History[Idx], Font, (RESOL_W div 2), YPos, ALIGN_LEFT, ALIGN_TOP, NIL);

			YPos += RowHeight
		end;
		
		Rendering.FinishFrame();

		dt := AdvanceTime();

		BlinkTicks += dt;
		If (CollisionTicks > 0) then CollisionTicks -= dt;

		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit() 
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If ((Ev.Key.Keysym.Sym = SDLK_Escape) or (Ev.Key.Keysym.Sym = SDLK_AC_BACK)) then
					Exit()
				else begin
					NewBind[K]:=Ev.Key.Keysym.Sym;
					Bound:=True
				end
			end else
			If (Ev.Type_ = SDL_ControllerDeviceAdded) or (Ev.Type_ = SDL_ControllerDeviceRemoved) then begin
				Controllers.HandleDeviceEvent(@Ev)
			end else
			If (Ev.Type_ = SDL_JoyBatteryUpdated) then begin
				Controllers.HandleBatteryEvent(@Ev)
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end;

		If Not Bound then Continue;
		Bound := False;

		// Always assign new name and reset blink timer,
		// even if we reject the proposed keybinding due to a collision.
		History[K]:=UpCase(SDL_GetKeyName(NewBind[K]));
		BlinkTicks := 0;

		// If we have a candidate keybind, check for collisions
		CollisionTicks := 0;
		Idx := Low(TPlayerKey);
		While Idx < K do begin
			If NewBind[Idx] = NewBind[K] then begin
				CollisionIdx := Idx;
				CollisionTicks := COLLISION_DURATION;
				PlaySfx(SFX_EXTRA+3);
				Break
			end;
			Inc(Idx)
		end;
		If CollisionTicks > 0 then Continue;

		// Last keybind? Bail out
		If (K = High(TPlayerKey)) then Break;

		// Otherwise, move over to next keybind
		Inc(K)
	end;
	For K:=Low(TPlayerKey) to High(TPlayerKey) do KeyBind[K]:=NewBind[K]
End;
{$ELSE} // LD25_MOBILE is defined
Procedure TweakOptions();
Const
	VOLUME_BTN_SIZE = 16;

	VOLUME_BAR_CHUNK = 32;
	VOLUME_BAR_GAP = 4;
	VOLUME_BAR_WIDTH = (VOL_LEVEL_MAX * VOLUME_BAR_CHUNK) + ((VOL_LEVEL_MAX - 2) * VOLUME_BAR_GAP) + VOLUME_BTN_SIZE;

	VOLUME_DOWN_XPOS = (RESOL_W - VOLUME_BAR_WIDTH - VOLUME_BTN_SIZE) div 2;
	VOLUME_UP_XPOS = (RESOL_W + VOLUME_BAR_WIDTH + VOLUME_BTN_SIZE) div 2;

	WHEEL_SIZE = 60;
	SHOOT_BTN_SIZE = 16;
	TOUCHY_MARGIN = 36;
Var
	Finished, SaveChanges: Boolean;

	Volume: TVolLevel;
	VolumeText: AnsiString;
	VolumeChanged: Boolean;

	BarChunk: Array[1..VOL_LEVEL_MAX] of TSDL_Rect;
	VolDown, VolUp, VolMute: TSDL_Rect;
	VolDownColour, VolUpColour: PSDL_Colour;

	TouchControlsSwap, TouchControlsSwapChanged: Boolean;
	WheelRect, ShootLeftBtn, ShootRightBtn: TSDL_Rect;
	MovementWheel: Array[0..8] of TSDL_Point;
	SwapButton: TSDL_Rect;

	Idx: uInt;
	FreeSpace, YPos: sInt;

{ Subproc }
	Procedure OnVolumeChanged();
	Begin
		If(Volume = 0) then VolDownColour := @MenuInactiveColour else VolDownColour := @MenuActiveColour;
		If(Volume = VOL_LEVEL_MAX) then VolUpColour := @MenuInactiveColour else VolUpColour := @MenuActiveColour;
		VolumeText := IntToStr(Volume)
	End;

	Procedure OnTouchControlsSwapChanged();
	Var
		pt: sInt;
	Begin
		If(Not TouchControlsSwap) then begin
			WheelRect.X := SwapButton.X - TOUCHY_MARGIN - (WHEEL_SIZE div 2);
			ShootLeftBtn.X := SwapButton.X + SwapButton.W + TOUCHY_MARGIN - (SHOOT_BTN_SIZE div 2)
		end else begin
			ShootLeftBtn.X := SwapButton.X - TOUCHY_MARGIN - (SHOOT_BTN_SIZE div 2);
			WheelRect.X := SwapButton.X + SwapButton.W + TOUCHY_MARGIN - (WHEEL_SIZE div 2)
		end;
		ShootRightBtn.X := ShootLeftBtn.X;

		For pt := 0 to 7 do begin
			MovementWheel[pt] := ProjectPoint(
				WheelRect.X + (WHEEL_SIZE div 2),
				WheelRect.Y + (WHEEL_SIZE div 2),
				WHEEL_SIZE div 2,
				0 - (Pi / 2) - (Pi / 8) + (Pi * pt / 4)
			)
		end;
		MovementWheel[8] := MovementWheel[0]
	End;
Begin
	(*
	 * Pre-calculate positions for some UI elements.
	 * Would be great if we could do this at compile time.
	 *)
	FreeSpace := RESOL_H - TitleGfx^.H - WHEEL_SIZE - ((Font^.CharH + Font^.SpacingY) * 7);
	YPos := TitleGfx^.H + ((Font^.CharH + Font^.SpacingY) * 4) + (FreeSpace div 3);
	For Idx := 1 to VOL_LEVEL_MAX do
		With BarChunk[Idx] do begin
			X := ((RESOL_W - VOLUME_BAR_WIDTH) div 2) + ((Idx - 1) * (VOLUME_BAR_CHUNK + VOLUME_BAR_GAP));
			If(Idx > (VOL_LEVEL_MAX div 2)) then X += VOLUME_BTN_SIZE - VOLUME_BAR_GAP;

			Y := YPos;
			W := VOLUME_BAR_CHUNK;
			H := Font^.CharH
		end;
	With VolDown do begin
		X := VOLUME_DOWN_XPOS - (VOLUME_BTN_SIZE div 2);
		Y := YPos;
		W := VOLUME_BTN_SIZE;
		H := Font^.CharH
	end;
	With VolUp do begin
		X := VOLUME_UP_XPOS - (VOLUME_BTN_SIZE div 2);
		Y := YPos;
		W := VOLUME_BTN_SIZE;
		H := Font^.CharH
	end;
	With VolMute do begin
		X := (RESOL_W - VOLUME_BTN_SIZE) div 2;
		Y := YPos;
		W := VOLUME_BTN_SIZE;
		H := Font^.CharH
	end;
	(*
	 * Position the UI elements for touch controls.
	 * The X coordinate is set by OnTouchControlsSwapChanged().
	 *)
	With WheelRect do begin
		Y := RESOL_H - WHEEL_SIZE - (FreeSpace div 3);
		W := WHEEL_SIZE;
		H := WHEEL_SIZE
	end;
	With ShootLeftBtn do begin
		Y := WheelRect.Y + ((WHEEL_SIZE - SHOOT_BTN_SIZE - SHOOT_BTN_SIZE) div 3);
		W := SHOOT_BTN_SIZE;
		H := SHOOT_BTN_SIZE
	end;
	With ShootRightBtn do begin
		Y := ShootLeftBtn.Y + SHOOT_BTN_SIZE + ((WHEEL_SIZE - SHOOT_BTN_SIZE - SHOOT_BTN_SIZE) div 3);
		W := SHOOT_BTN_SIZE;
		H := SHOOT_BTN_SIZE
	end;

	Font^.Scale := 2;
	With SwapButton do begin
		W := GetTextWidth('SWAP', Font);
		H := GetTextHeight('SWAP', Font);
		X := (RESOL_W - W) div 2;
		Y := WheelRect.Y + ((WHEEL_SIZE - H) div 2)
	end;

	(* Get current settings and store in helper vars. *)
	Volume := GetVol();
	TouchControlsSwap := Rendering.SwapTouchControls;
	OnVolumeChanged();
	OnTouchControlsSwapChanged();

	Finished := False;
	SaveChanges := False;
	Repeat
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2;
		PrintText('GAME OPTIONS', Font, (RESOL_W div 2), TitleGfx^.H, ALIGN_CENTRE, ALIGN_TOP, NIL);

		(*
		 * "Sound" has 5 letters, and "volume" has 6. This makes the space between
		 * the words not align with the volume level text, which looks off - despite
		 * both texts being aligned to the centre of the screen!
		 * Hence, an extra space is added at the start of the text.
		 *)
		YPos := VolMute.Y - ((Font^.CharH + Font^.SpacingY) * Font^.Scale);
		PrintText(' SOUND VOLUME', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);

		Font^.Scale := 1;
		PrintText(VolumeText, Font, (RESOL_W div 2), VolMute.Y, ALIGN_CENTRE, ALIGN_TOP, NIL);
		(*
		 * TODO: Think of some way to make it more obvious that these are touchable.
		 *)
		PrintText('-', Font, VOLUME_DOWN_XPOS, VolDown.Y, ALIGN_CENTRE, ALIGN_TOP, VolDownColour);
		PrintText('+', Font, VOLUME_UP_XPOS, VolUp.Y, ALIGN_CENTRE, ALIGN_TOP, VolUpColour);

		For Idx := 1 to VOL_LEVEL_MAX do
			If(Volume >= Idx) then
				DrawRectFilled(@BarChunk[Idx], @WhiteColour)
			else
				DrawRectFilled(@BarChunk[Idx], @GreyColour);

		Font^.Scale := 2;
		YPos := WheelRect.Y - ((Font^.CharH + Font^.SpacingY) * Font^.Scale);
		PrintText('TOUCH CONTROLS', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		SDL_SetRenderDrawColor(Renderer, 191, 191, 191, 255);
		SDL_RenderDrawLines(Renderer, MovementWheel, 9);
		SDL_RenderDrawRect(Renderer, @ShootLeftBtn);
		SDL_RenderDrawRect(Renderer, @ShootRightBtn);

		PrintText('<', Font, ShootLeftBtn.X + (SHOOT_BTN_SIZE div 2), ShootLeftBtn.Y + (SHOOT_BTN_SIZE div 2), ALIGN_CENTRE, ALIGN_MIDDLE, @GreyColour);
		PrintText('>', Font, ShootRightBtn.X + (SHOOT_BTN_SIZE div 2), ShootRightBtn.Y + (SHOOT_BTN_SIZE div 2), ALIGN_CENTRE, ALIGN_MIDDLE, @GreyColour);
		Font^.Scale := 1;
		PrintText(['MOVEMENT', 'WHEEL'], Font, WheelRect.X + (WHEEL_SIZE div 2), WheelRect.Y + (WHEEL_SIZE div 2), ALIGN_CENTRE, ALIGN_MIDDLE, @GreyColour);

		Font^.Scale := 2;
		PrintText('SWAP', Font, SwapButton.X, SwapButton.Y, ALIGN_LEFT, ALIGN_TOP, @MenuActiveColour);

		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		VolumeChanged := False;
		TouchControlsSwapChanged := False;
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Finished := True
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If ((Ev.Key.Keysym.Sym = SDLK_Escape) or (Ev.Key.Keysym.Sym = SDLK_AC_BACK)) then begin
					Finished := True; SaveChanges := True
				end
			end else
			If (Ev.Type_ = SDL_MouseButtonDown) then begin
				TranslateMouseEventCoords(@Ev);
				If MouseInRect(SwapButton) then begin
					TouchControlsSwap := (Not TouchControlsSwap);
					TouchControlsSwapChanged := True
				end else
				If MouseInRect(VolDown) then begin
					If(Volume > 0) then begin
						Volume -= 1; VolumeChanged := True
					end
				end else
				If MouseInRect(VolUp) then begin
					If(Volume < VOL_LEVEL_MAX) then begin
						Volume += 1; VolumeChanged := True
					end
				end else
				If MouseInRect(VolMute) then begin
					Volume := 0; VolumeChanged := True
				end else
				For Idx := 1 to VOL_LEVEL_MAX do
					If MouseInRect(BarChunk[Idx]) then begin
						Volume := TVolLevel(Idx);
						VolumeChanged := True;
						Break
					end
			end else
			If (Ev.Type_ = SDL_FingerUp) or (Ev.Type_ = SDL_FingerDown) or (Ev.Type_ = SDL_FingerMotion) then begin
				TouchControls.HandleEvent(@Ev)
			end else
			If (Ev.Type_ = SDL_ControllerDeviceAdded) or (Ev.Type_ = SDL_ControllerDeviceRemoved) then begin
				Controllers.HandleDeviceEvent(@Ev)
			end else
			If (Ev.Type_ = SDL_JoyBatteryUpdated) then begin
				Controllers.HandleBatteryEvent(@Ev)
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end;

		If (VolumeChanged) then OnVolumeChanged();
		If (TouchControlsSwapChanged) then OnTouchControlsSwapChanged()
	Until Finished;

	If(SaveChanges) then begin
		SetVol(Volume);

		Rendering.SwapTouchControls := TouchControlsSwap;
		// Call the resize handler to trigger touch controls positioning code
		Rendering.HandleWindowResizedEvent(NIL);
	end
End;
{$ENDIF}

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
	Var
		Con: PSDL_GameController;
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

	RumbleStr: Array[Boolean] of AnsiString = ('DISABLED', 'ENABLED');
Var
	Idx, YPos: uInt;
	DeadRect, RumbleRect, LeftRect, RightRect: TSDL_Rect;
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

	While True do begin
		Rendering.BeginFrame();
		DrawTitle();

		YPos := TitleGfx^.H;
		Font^.Scale := 2;
		PrintText('GAMEPAD SETTINGS',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP, @WhiteColour);

		Font^.Scale := 1;
		YPos += (5 * (Font^.CharH + Font^.SpacingY)) div 2;
		DeadRect.Y := YPos;
		PrintText('D - DEAD ZONE', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @MenuActiveColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		PrintText(DeadZoneStr, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		YPos += (4 * (Font^.CharH + Font^.SpacingY)) div 2;
		RumbleRect.Y := YPos;
		PrintText('V - VIBRATION', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @MenuActiveColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		PrintText(RumbleStr[Controllers.RumbleEnabled], Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		YPos += (4 * (Font^.CharH + Font^.SpacingY)) div 2;
		LeftRect.Y := YPos;
		PrintText('L - SHOOT LEFT', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, AssignTextColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		If(AssignToBind = @PadShootLeft) then begin
			If(((GetTicks() div BLINK_PERIOD) mod 2) = 0) then
				PrintText('???', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);
		end else
			PrintText(LeftStr, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		YPos += (4 * (Font^.CharH + Font^.SpacingY)) div 2;
		RightRect.Y := YPos;
		PrintText('R - SHOOT RIGHT', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, AssignTextColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		If(AssignToBind = @PadShootRight) then begin
			If(((GetTicks() div BLINK_PERIOD) mod 2) = 0) then
				PrintText('???', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);
		end else
			PrintText(RightStr, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

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
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end;
	end;
End;

(*
 * TODO:
 * The drawing code is copy-pasted from Game.DrawRoom().
 * Think of a way to reduce duplication.
 *)
Procedure DrawColourPreview(Const Colour: PSDL_Colour; Const PosX, PosY: sInt);
Const
	PreviewW = 8;
	PreviewH = 4;
	PreviewMap: Array[0..(PreviewH-1), 0..(PreviewW-1)] of Char = (
		('X', '-', '-', '-', '=', '-', '-', '+'),
		('X', 'X', ' ', ' ', ' ', ' ', ' ', '|'),
		(':', ' ', ' ', ' ', ' ', ' ', ' ', 'D'),
		('X', 'X', ' ', '<', '-', '>', ' ', '|')
	);
Var
	X, Y: sInt;
	Tile: TTile;
	Src, Dst: TSDL_Rect;
Begin
	// All tiles have the same size, no need to set this in the loop 
	Src.W:=TILE_W; Src.H:=TILE_H; 
	Dst.W:=TILE_W; Dst.H:=TILE_H;
	
	Src.X:=0;
	For Y:=0 to (PreviewH-1) do For X:=0 to (PreviewW-1) do begin
		Tile:=TRoom.CharToTile(PreviewMap[Y][X]);
		If (Tile = TILE_NONE) then Continue;
		
		Dst.X := PosX + (X*TILE_W);
		Dst.Y := PosY + (Y*TILE_H);
		Src.Y := Ord(Tile)*TILE_H;
		DrawImage(TileGfx,@Src,@Dst,Colour)
	end
End;

Procedure SetSingleColour(Const idx: sInt);
Const
	RectWidth = 128;
	RectHeight = 64;
Var
	idxName: AnsiString;
	CurrentCol: TSDL_Colour;
	
	Menu: TMenu;
	Choice: Char;
	Changed: Boolean;
	Finished: Boolean;

	pc: uInt;
	YPos: sInt;
Begin
	idxName := UpperCase(ColourName[idx]);
	CurrentCol := MapColour[idx];

	Menu.Create();
	Menu.SetFontScale(2);
	Menu.AddItem('R', 'RED:   #'+HexStr(CurrentCol.R, 2), @MenuActiveColour);
	Menu.AddItem('G', 'GREEN: #'+HexStr(CurrentCol.G, 2), @MenuActiveColour);
	Menu.AddItem('B', 'BLUE:  #'+HexStr(CurrentCol.B, 2), @MenuActiveColour);
	Menu.AddItem('D', 'DEFAULT', @MenuActiveColour);

	Finished := False;
	While Not Finished do begin
		Rendering.BeginFrame();
		DrawTitle();
		
		Font^.Scale := 2; YPos:=TitleGfx^.H;
		PrintText('COLOUR SETTINGS', Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);
		
		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		PrintText(idxName, Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);
		
		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		DrawColourPreview(@CurrentCol, (RESOL_W - RectWidth) div 2, YPos);
		
		YPos += RectHeight + (Font^.CharH * Font^.Scale) div 2;
		Menu.SetVerticalOffset(YPos);
		Menu.Draw();
		
		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		Changed := False;
		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = 'R') then begin
				CurrentCol.R := CurrentCol.R + $10;
				Changed := True
			end else
			If (Choice = 'G') then begin
				CurrentCol.G := CurrentCol.G + $10;
				Changed := True
			end else
			If (Choice = 'B') then begin
				CurrentCol.B := CurrentCol.B + $10;
				Changed := True
			end else
			If (Choice = 'D') then begin
				CurrentCol:=DefaultMapColour[idx];
				Changed := True
			end else
			If (Choice = CHOICE_BACK) then begin
				For pc:=0 to 7 do If(CentralPalette[pc] = MapColour[idx]) then CentralPalette[pc] := CurrentCol;
				For pc:=0 to 7 do If(PaletteColour[pc] = MapColour[idx]) then PaletteColour[pc] := CurrentCol;
				MapColour[idx] := CurrentCol;
				Finished := True
			end else
			If (Choice = CHOICE_QUIT) then begin
				Shutdown := True;
				Finished := True
			end
		end;

		If (Changed) then begin
			Menu.EditItem(0, 'RED:   #'+HexStr(CurrentCol.R, 2));
			Menu.EditItem(1, 'GREEN: #'+HexStr(CurrentCol.G, 2));
			Menu.EditItem(2, 'BLUE:  #'+HexStr(CurrentCol.B, 2))
		end
	end;
	Menu.Destroy()
End;

Procedure SetColours();
Var
	Idx: uInt;

	Menu: TMenu;
	Choice: Char;
	Selection: sInt;
	Finished: Boolean;
Begin
	Menu.Create(8);
	Menu.SetFontScale(2);
	For Idx := 0 to 7 do Menu.AddItem(Chr(48 + Idx), UpperCase(ColourName[Idx]), @MenuActiveColour);
	Menu.SetVerticalOffset(TitleGfx^.H + (Font^.CharH * 3));

	Finished := False;
	Repeat
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2;
		PrintText('COLOUR SETTINGS', Font, (RESOL_W div 2), TitleGfx^.H, ALIGN_CENTRE, ALIGN_TOP, NIL);

		Menu.Draw();
		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		Selection := -1;
		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = CHOICE_QUIT) then begin
				Shutdown := True;
				Finished := True
			end else
			If (Choice = CHOICE_BACK) then Finished := True
			else
			If (Choice <> CHOICE_NONE) then Selection := Ord(Choice) - 48
		end;
		If (Selection >= 0) and (Selection <= 7) then SetSingleColour(Selection)
	Until Finished;
	Menu.Destroy()
End;

{$IFDEF LD25_DONATE}
Procedure DonateScreen();
Const
	GitHubText    = {$IFNDEF LD25_MOBILE} 'G - ' + {$ENDIF} 'GITHUB SPONSORS';
	LiberapayText = {$IFNDEF LD25_MOBILE} 'L - ' + {$ENDIF} 'LIBERAPAY';
	Alignment = {$IFNDEF LD25_MOBILE} ALIGN_LEFT {$ELSE} ALIGN_CENTRE {$ENDIF};

	GitHubLink = 'GITHUB.COM/SPONSORS/SUVE';
	GitHubURL: PChar = 'https://github.com/sponsors/suve';

	LiberapayLink = 'LIBERAPAY.COM/SUVE';
	LiberapayURL: PChar = 'https://liberapay.com/suve';
Var
	XPos, YPos: sInt;
	{$IFNDEF LD25_MOBILE} Offset: uInt; {$ENDIF}
	GitHubRect, LiberaPayRect: TSDL_Rect;
	BackToMenu: Boolean;
Begin
	Font^.Scale := 2;
	{$IFNDEF LD25_MOBILE}
		XPos := (Length(GitHubText) * Font^.CharW) + ((Length(GitHubText) - 1) * Font^.SpacingX);
		XPos := (RESOL_W - (XPos * Font^.Scale)) div 2;
		Offset := 4 * (Font^.CharW + Font^.SpacingX) * Font^.Scale;
	{$ELSE}
		XPos := RESOL_W div 2;
	{$ENDIF}

	BackToMenu := False;
	Repeat
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2;
		YPos:=TitleGfx^.H;
		PrintText('IF YOU LIKE THE GAME', Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);
		YPos += Font^.CharH * 3;
		PrintText('YOU CAN DONATE VIA:', Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);

		YPos += Font^.CharH * 6;
		PrintMenuText(GitHubText, XPos, YPos, Alignment, @MenuActiveColour, GitHubRect);

		YPos += Font^.CharH * 7;
		PrintMenuText(LiberapayText, XPos, YPos, Alignment, @MenuActiveColour, LiberaPayRect);

		YPos += Font^.CharH * 7;
		PrintText('THANKS!', Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP, @WhiteColour);

		Font^.Scale := 1;
		YPos := GitHubRect.Y + GitHubRect.H + (Font^.CharH div 2);
		{$IFNDEF LD25_MOBILE}
			PrintText(GitHubLink, Font, GitHubRect.X + Offset, YPos, ALIGN_LEFT, ALIGN_TOP, @MenuActiveColour);
		{$ELSE}
			PrintText(GitHubLink, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @MenuActiveColour);
		{$ENDIF}
		YPos := LiberaPayRect.Y + LiberaPayRect.H + (Font^.CharH div 2);
		{$IFNDEF LD25_MOBILE}
			PrintText(LiberapayLink, Font, LiberaPayRect.X + Offset, YPos, ALIGN_LEFT, ALIGN_TOP, @MenuActiveColour);
		{$ELSE}
			PrintText(LiberapayLink, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @MenuActiveColour);
		{$ENDIF}

		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		GitHubRect.H += (Font^.CharH * 3) div 2;
		LiberaPayRect.H += (Font^.CharH * 3) div 2;

		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; BackToMenu := True
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If ((Ev.Key.Keysym.Sym = SDLK_Escape) or (Ev.Key.Keysym.Sym = SDLK_AC_BACK)) then
					BackToMenu := True
				else
				If (Ev.Key.Keysym.Sym = SDLK_G) then begin
					SDL_OpenUrl(GitHubURL);
					BackToMenu := True
				end else
				If (Ev.Key.Keysym.Sym = SDLK_L) then begin
					SDL_OpenUrl(LiberapayURL);
					BackToMenu := True
				end
			end else
			If (Ev.Type_ = SDL_MouseButtonDown) then begin
				{$IFDEF LD25_MOBILE} TranslateMouseEventCoords(@Ev); {$ENDIF}
				If(MouseInRect(GitHubRect)) then begin
					SDL_OpenUrl(GitHubURL);
					BackToMenu := True
				end else
				If(MouseInRect(LiberaPayRect)) then begin
					SDL_OpenUrl(LiberaPayURL);
					BackToMenu := True
				end
			end else
			{$IFDEF LD25_MOBILE}
			If (Ev.Type_ = SDL_FingerUp) or (Ev.Type_ = SDL_FingerDown) or (Ev.Type_ = SDL_FingerMotion) then begin
				TouchControls.HandleEvent(@Ev)
			end else
			{$ENDIF}
			If (Ev.Type_ = SDL_ControllerDeviceAdded) or (Ev.Type_ = SDL_ControllerDeviceRemoved) then begin
				Controllers.HandleDeviceEvent(@Ev)
			end else
			If (Ev.Type_ = SDL_JoyBatteryUpdated) then begin
				Controllers.HandleBatteryEvent(@Ev)
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end;
	until BackToMenu
End;
{$ENDIF}

Function GameworldDialog(Const Load:Boolean):Char;
Const
	WorldName: Array[TGameMode] of AnsiString = (
		'TUTORIAL',
		'CLASSIC'
	);
Var
	Msg: AnsiString;
	OK: Array[TGameMode] of Boolean;
	GM: TGameMode;

	Menu: TMenu;
	Col: PSDL_Colour;
	Choice: Char;
	YPos: uInt;
Begin
	If Load then begin
		Msg:='LOAD GAME';
		For GM:=Low(GM) to High(GM) do Ok[GM]:=SaveExists[GM]
	end else begin
		Msg:='NEW GAME';
		For GM:=Low(GM) to High(GM) do Ok[GM]:=True
	end;

	Menu.Create(Length(WorldName));
	Menu.SetFontScale(2);
	For GM := Low(GM) to High(GM) do begin
		If (Ok[GM]) then
			Col := @MenuActiveColour
		else
			Col := @MenuInactiveColour;
		Menu.AddItem(WorldName[GM][1], WorldName[GM], Col)
	end;

	Result := '?';
	While (Result = '?') do begin
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2;
		YPos := TitleGfx^.H;
		PrintText(Msg, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		PrintText('SELECT GAMEWORLD', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
		YPos += (Font^.CharH * Font^.Scale);

		Menu.SetVerticalOffset(YPos);
		Menu.Draw();

		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = 'T') then begin
				If (Ok[GM_TUTORIAL]) then Result := 'T'
			end else
			If (Choice = 'C') then begin
				If (Ok[GM_ORIGINAL]) then Result := 'C'
			end else
			If (Choice = CHOICE_QUIT) then begin
				Shutdown := True;
				Result := 'Q'
			end else
			If (Choice = CHOICE_BACK) then Result := 'Q'
		end
	end;
	Menu.Destroy()
End;

Function MainMenu():Char;
Var
	GM: TGameMode;
	IHasSaves: Boolean;
	ContinueColour: PSDL_Colour;
	LoadColour: PSDL_Colour;

	Menu: TMenu;
	Choice: Char;
Begin
	If (GameOn) then
		ContinueColour := @MenuActiveColour
	else
		ContinueColour := @MenuInactiveColour;

	IHasSaves := False;
	For GM:=Low(GM) to High(GM) do If (SaveExists[GM]) then begin
		IHasSaves:=True;
		Break
	end;
	If (IHasSaves) then
		LoadColour := @MenuActiveColour
	else
		LoadColour := @MenuInactiveColour;

	Menu.Create(9);
	Menu.SetFontScale(2);
	Menu.AddItem('I', 'INTRODUCTION', @MenuActiveColour);
	Menu.AddItem('C', 'CONTINUE', ContinueColour);
	Menu.AddItem('N', 'NEW GAME', @MenuActiveColour);
	Menu.AddItem('L', 'LOAD GAME', LoadColour);
	{$IFNDEF LD25_MOBILE}
		Menu.AddItem('B', 'BIND KEYS', @MenuActiveColour);
	{$ELSE}
		Menu.AddItem('O', 'CHANGE OPTIONS', @MenuActiveColour);
	{$ENDIF}
	Menu.AddItem('P', 'GAMEPAD SETTINGS', @MenuActiveColour);
	Menu.AddItem('S', 'SET COLOURS', @MenuActiveColour);
	{$IFDEF LD25_DONATE}
		Menu.AddItem('D', 'DONATE', @MenuActiveColour);
	{$ENDIF}
	Menu.AddItem('Q', 'QUIT', @MenuActiveColour);

	{$IFDEF LD25_MOBILE}
		TouchControls.SetVisibility(TCV_ONLY_BACK);
	{$ENDIF}

	Result := '?';
	While (Result = '?') do begin
		Rendering.BeginFrame();
		DrawTitle();
		Menu.Draw();
		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = CHOICE_QUIT) or (Choice = CHOICE_BACK) then begin
				Shutdown := True;
				Result := 'Q'
			end else
			If (Choice = 'C') then begin
				If (GameOn) then Result := 'C'
			end else
			If (Choice = 'L') then begin
				If (IHasSaves) then Result := 'L'
			end else
			If (Choice <> CHOICE_NONE) then Result := Choice
		end
	end;
	Menu.Destroy()
End;

Procedure LoadConfig();
Begin
	(*
	 * Start by setting everything to default values, just in case
	 * the user manually edited the config file and some fields are now missing.
	 *)
	Configfiles.DefaultSettings();

	If (IHasIni(INIVER_2_0)) then begin
		SDL_Log('Loading configuration file...', []);
		If (LoadIni(INIVER_2_0)) then begin
			SDL_Log('Configuration file loaded successfully.', []);
			Exit()
		end else
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, 'Failed to load configuration file!', [])
	end else
		SDL_Log('Configuration file not found.', []);

	{$IFDEF LD25_COMPAT_V1}
		If (IHasIni(INIVER_1_0)) then begin
			SDL_Log('Loading legacy v1.x configuration file...', []);
			If (LoadIni(INIVER_1_0)) then begin
				SDL_Log('Legacy configuration file loaded successfully.', []);
				Exit()
			end else
				SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, 'Failed to load legacy configuration file!', [])
		end else
			SDL_Log('Legacy v1.x configuration file not found.', []);
	{$ENDIF}

	SDL_Log('Using default settings.', []);
	Configfiles.DefaultSettings()
End;

Function OpenWindow(): Boolean;
Var
	Title: AnsiString;
Begin
	Title := GAMENAME + ' v.' + GAMEVERS;
	{$IFDEF ANDROID}
		(*
		 * On Android, pass 0x0 as the window size. This makes SDL open a window covering the entire screen.
		 * Set the RESIZABLE flag to allow for rotations, split-screen, et cetera.
		 * Do not set FULLSCREEN, as that disables system navigation buttons.
		 *)
		Window := SDL_CreateWindow(PChar(Title), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 0, 0, SDL_WINDOW_RESIZABLE);
	{$ELSE}
		(*
		 * On desktop platforms, open a window based on the values read beforehand from the config file.
		 *)
		If (Not Wnd_F) then
			Window := SDL_CreateWindow(PChar(Title), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, Wnd_W, Wnd_H, SDL_WINDOW_RESIZABLE)
		else
			Window := SDL_CreateWindow(PChar(Title), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, RESOL_W, RESOL_H, SDL_WINDOW_FULLSCREEN_DESKTOP or SDL_WINDOW_RESIZABLE);
	{$ENDIF}
	If (Window = NIL) then Exit(False);

	(*
	 * Trigger the resize event handler to force recalculating the window size and aspect ratio.
	 *)
	HandleWindowResizedEvent(NIL);

	SDL_SetWindowMinimumSize(Window, RESOL_W, RESOL_H);
	Exit(True)
End;

Procedure FatalError(fmt: AnsiString; args: Array of Const);
Const
	MsgBoxTitle = GAMENAME + ' v.' + GAMEVERS + ': Error';
Var
	ErrorStr: AnsiString;
Begin
	ErrorStr := SysUtils.Format(fmt, args);
	SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, '%s', [PChar(ErrorStr)]);
	SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, PChar(MsgBoxTitle), PChar(ErrorStr), Window);
	Halt(1)
End;

Function InitSDL2(): Boolean;
Begin
	(*
	 * Configure the behaviour of the SDL2 library.
	 * Some of the values we set here are the same as the default ones,
	 * but it is always better to be explicit.
	 *)
	SDL_SetHint(SDL_HINT_APP_NAME, GAMENAME);

	SDL_SetHint(SDL_HINT_VIDEO_ALLOW_SCREENSAVER, '1');
	SDL_SetHint(SDL_HINT_SCREENSAVER_INHIBIT_ACTIVITY_NAME, 'Playing a game');

	SDL_SetHint(SDL_HINT_RENDER_BATCHING, '1');
	SDL_SetHint(SDL_HINT_RENDER_LOGICAL_SIZE_MODE, 'letterbox');
	SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'nearest');

	SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, '0');
	SDL_SetHint(SDL_HINT_QUIT_ON_LAST_WINDOW_CLOSE, '1');
	SDL_SetHint(SDL_HINT_WINDOWS_NO_CLOSE_ON_ALT_F4, '0');

	SDL_SetHint(SDL_HINT_ANDROID_TRAP_BACK_BUTTON, '1');
	SDL_SetHint(SDL_HINT_MOUSE_TOUCH_EVENTS, '0');
	SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS, '1');

	Result := SDL_Init(SDL_INIT_VIDEO or SDL_INIT_EVENTS or SDL_INIT_TIMER) = 0
End;

Procedure Startup();
Var
	StartTime: TTimeStamp;
	GM: TGameMode;
	OldMask, NewMask: TFPUExceptionMask;
	Assload: Assets.TLoadingResult;

	ControllerCount: sInt;
	ControllerNames: Array[0..4] of AnsiString;
Begin
	StartTime:=GetTimeStamp(); Randomize();

	// Reset some global vars to known values
	Shutdown:=False;
	GameOn:=False;
	NoSound:=False;

	ConfigFiles.SetPaths();
	{$IFDEF LD25_COMPAT_V1}
	ConfigFiles.CopyOldSavegames();
	{$ENDIF}

	LoadConfig();
	For GM:=Low(GM) to High(GM) do SaveExists[GM]:=IHasGame(GM);

	// Disable Floating Poing Exception checking while initializing the video stack.
	// See: https://github.com/PascalGameDevelopment/SDL2-for-Pascal/issues/56
	OldMask := Math.GetExceptionMask();
	NewMask := OldMask;
	Include(NewMask, exInvalidOp);
	Include(NewMask, exZeroDivide);
	Math.SetExceptionMask(NewMask);

	SDL_Log('Initializing SDL2...', []);
	If (Not InitSDL2()) then
		FatalError('Failed to initialize SDL2! Error details: %s', [SDL_GetError()])
	else
		SDL_Log('SDL2 initialized successfully.', []);

	SDL_Log('Initializing SDL2_image... ', []);
	if(IMG_Init(IMG_INIT_PNG) <> IMG_INIT_PNG) then
		FatalError('Failed to initialize SDL2_image! Error details: %s', [IMG_GetError()])
	else
		SDL_Log('SDL2_image initialized successfully.', []);

	SDL_Log('Initializing SDL2 audio subsystem...', []);
	If (SDL_InitSubSystem(SDL_Init_Audio)<>0) then begin
		SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to initialize SDL2 audio subsystem! Error details: %s', [SDL_GetError()]);
		NoSound:=True
	end else
		SDL_Log('SDL2 audio subsystem initialized successfully.', []);

	If (Not NoSound) then begin
		SDL_Log('Initializing SDL2_mixer...', []);
		If((Mix_Init(MIX_INIT_OGG) and MIX_INIT_OGG) = 0) then begin
			SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to initialize SDL2_mixer! Error details: %s', [Mix_GetError()]);
			NoSound:=True
		end else
		If (Mix_OpenAudio(AUDIO_FREQ, AUDIO_TYPE, AUDIO_CHAN, AUDIO_CSIZ)<>0) then begin
			SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to initialize SDL2_mixer! Error details: %s', [Mix_GetError()]);
			NoSound:=True
		end else begin
			Mix_AllocateChannels(SFXCHANNELS);
			SDL_Log('SDL2_mixer initialized successfully.', [])
		end
	end else
		SDL_Log('Failed to initialize SDL2 audio - skipping SDL2_mixer init.', []);

	(*
	 * Do not show controller toasts while loading.
	 * On desktop, this will save us from a segfault due to missing font.
	 * On Android, this will prevent us from showing the "found device" toast
	 * twice. (First during init and then after init is finished.)
	 *)
	Toast.SetVisibility(False);
	InitControllers();

	SDL_Log('Opening window...', []);
	If (Not OpenWindow()) then begin
		FatalError('Failed to open window! Error details: %s', [SDL_GetError()])
	end else begin
		SDL_Log('Window opened successfully. (%s)', [PChar(Rendering.GetWindowInfo())]);
		LoadAndSetWindowIcon()
	end;

	SDL_Log('Creating renderer...', []);
	Renderer := SDL_CreateRenderer(Window, -1, SDL_RENDERER_TARGETTEXTURE);
	if(Renderer = NIL) then begin
		FatalError('Failed to create renderer! Error details: %s', [SDL_GetError()])
	end else begin
		SDL_Log('Renderer created successfully. (%s)', [PChar(Rendering.GetRendererInfo())]);
		SDL_RenderSetLogicalSize(Renderer, RESOL_W, RESOL_H)
	end;

	// Restore the old mask after we disabled FPE checks.
	Math.SetExceptionMask(OldMask);

	SDL_Log('Creating render target texture...', []);
	Display := SDL_CreateTexture(Renderer, SDL_GetWindowPixelFormat(Window), SDL_TEXTUREACCESS_TARGET, RESOL_W, RESOL_H);
	if(Display = NIL) then
		FatalError('Failed to create render target texture! Error details: %s', [SDL_GetError()])
	else
		SDL_Log('Render target texture created successfully.', []);

	{$IF DEFINED(LD25_MOBILE)}
		// Make sure the game does not try to render touch controls while assets
		// are still being loaded (touch-controls.png is quite far down the list)
		TouchControls.SetVisibility(TCV_NONE);
	{$ENDIF}

	SDL_Log('Loading assets...', []);
	RegisterAllAssets();
	Assload := LoadAssets(@LoadUpdate);
	If(Assload.Status <> ALS_OK) then begin
		If(Assload.Status = ALS_FAILED) then
			FatalError('Failed to load file: %s (%s)', [Assload.FileName, Assload.ErrStr])
		else
			FatalError('Failed to load assets: %s', [Assload.ErrStr])
	end else
		SDL_Log('All assets loaded successfully.', []);

	// Init buffers with some default sizes
	PlayerBullets.Create(16);
	EnemyBullets.Create(16);
	Gibs.Create(GIBS_PIECES_TOTAL * 4);
	Mobs.Create(8);
	Hero:=NIL;

	(*
	 * Toast duration is not tied to the "real" number of ticks as reported by SDL,
	 * but rather to the cached value found in the Timekeeping unit.
	 * Advancing the timer here ensures that the toast is shown for the full
	 * intended duration, not affected by the startup time.
	 *)
	Timekeeping.AdvanceTime();

	// This is not the best way to do this, as the user could potentially have
	// more controllers than the length of the array, but - eh, good enough.
	GetControllerNames(ControllerCount, ControllerNames);
	Toast.SetVisibility(True);
	If(ControllerCount > 0) then
		If(ControllerCount > 1) then
			Toast.Show(TH_CONTROLLER_FOUND_MULTIPLE, IntToStr(ControllerCount) + ' devices')
		else
			Toast.Show(TH_CONTROLLER_FOUND, ControllerNames[0]);

	SDL_Log('All done! Initialization finished in %ld ms.', [clong(TimeStampDiffMillis(StartTime, GetTimeStamp()))])
End;

Procedure NewGame(Const GM:TGameMode);
Begin
	If(GM <> GameMode) then SaveCurrentGame();

	GameMode:=GM;
	DestroyEntities(True); ResetGamestate();
	New(Hero,Create()); ChangeRoom(RespRoom[GM].X,RespRoom[GM].Y);
	Stats.ZeroSaveStats();
	GameOn:=True
End;

Function GameloadRequest(Const GM:TGameMode):Boolean;
Begin
	If(GM <> GameMode) then SaveCurrentGame();

	SDL_Log('Loading game...', []);
	Result := LoadGame(GM);
	If(Result) then
		SDL_Log('Game loaded successfully.', [])
	else
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, 'Failed to load the game!', [])
End;

Procedure QuitProg();
Var
	StartTime: TTimeStamp;
Begin
	StartTime := GetTimeStamp();
	SDL_HideWindow(Window);

	SaveCurrentGame();

	SDL_Log('Saving configuration file...', []);
	If (SaveIni()) then
		SDL_Log('Configuration file saved successfully.', [])
	else
		SDL_Log('Failed to save configuration file!', []);

	DestroyEntities();

	SDL_Log('Freeing assets...', []);
		Assets.FreeAssets();
	SDL_Log('Assets freed.', []);

	SDL_Log('Closing SDL2_mixer...', []);
		Mix_CloseAudio();
		Mix_Quit();
	SDL_Log('SDL2_mixer closed.', []);

	SDL_Log('Closing SDL2_image...', []);
		IMG_Quit();
	SDL_Log('SDL2_image closed.', []);

	SDL_Log('Closing SDL2...', []);
		SDL_DestroyTexture(Display);
		SDL_DestroyRenderer(Renderer);
		SDL_DestroyWindow(Window);
		SDL_Quit();
	SDL_Log('SDL2 closed.', []);

	SDL_Log('Finalization finished in %ld ms.', [clong(TimeStampDiffMillis(StartTime, GetTimeStamp()))]);
	SDL_Log('Thanks for playing and have a nice day!', [])
End;

(*
 * On Android, we're building the game as a library, not as an executable.
 * Stick the code in an "ld25main" function and export it.
 * Use cdecl for compatibility with C wrapper code.
 *)
{$IFDEF ANDROID}
Function ld25main(argc: cint; argv: Pointer): cint; cdecl;
{$ENDIF}

begin
	SDL_Log(GAMENAME + ' v.' + GAMEVERS + ' by ' + GAMEAUTH, []);
	{$IFDEF LD25_DEBUG}
		SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_DEBUG);
	{$ENDIF}

	Startup();
	Repeat
		MenuChoice:=MainMenu();
		Case MenuChoice of
			'I': ShowIntro();
			'C': PlayGame();
			'N': begin
				MenuChoice:=GameworldDialog(False);
				Case MenuChoice of
					'T': begin NewGame(GM_TUTORIAL); PlayGame() end;
					'C': begin NewGame(GM_ORIGINAL); PlayGame() end;
				end;
				MenuChoice:='N'
			end;
			'L': begin
				MenuChoice:=GameworldDialog(True);
				Case MenuChoice of
					'T': If(GameloadRequest(GM_TUTORIAL)) then PlayGame();
					'C': If(GameloadRequest(GM_ORIGINAL)) then PlayGame();
				end;
				MenuChoice:='L'
			end;
			'S': SetColours();
			'P': ConfigureGamepad();
			{$IFDEF LD25_MOBILE}
				'O': TweakOptions();
			{$ELSE}
				'B': BindKeys();
			{$ENDIF}
			{$IFDEF LD25_DONATE}
				'D': DonateScreen();
			{$ENDIF}
		end;
		If (GameOn) and (GameMode <> GM_TUTORIAL) and (Given >= 8) then begin
			GameOn:=False; ShowOutro()
		end;
	Until (MenuChoice = 'Q') or (Shutdown);
	QuitProg();
{$IFDEF ANDROID}
	Result := 0
end;

exports	ld25main;
{$ENDIF}

end.
