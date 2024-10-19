(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2022-2024 suve (a.k.a. Artur Frenszek-Iwicki)
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
Unit Menus.Options;

{$INCLUDE defines.inc}

Interface

Procedure TweakOptions();


Implementation

Uses
	SDL2,
	Assets, Colours, Controllers, Fonts, MathUtils, Menus, Rendering, Shared,
	Timekeeping, TouchControls;

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

End.
