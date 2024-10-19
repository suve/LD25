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
Unit Menus.Keybinds;

{$INCLUDE defines.inc}

Interface

Procedure BindKeys();


Implementation

Uses
	SDL2,
	Assets, Colours, Controllers, Fonts, Menus, Rendering, Timekeeping, Shared;

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

End.
