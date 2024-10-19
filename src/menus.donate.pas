(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2017-2024 suve (a.k.a. Artur Frenszek-Iwicki)
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
Unit Menus.Donate;

{$INCLUDE defines.inc}

Interface

Procedure DonateScreen();


Implementation

Uses
	SDL2,
	Assets, Controllers, Colours, Fonts, Menus, Rendering, Shared, Timekeeping
	{$IFDEF LD25_MOBILE}, TouchControls {$ENDIF};

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

End.
