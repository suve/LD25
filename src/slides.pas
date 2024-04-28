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
Unit Slides;

{$INCLUDE defines.inc}

Interface

Procedure ShowIntro();
Procedure ShowOutro();

Implementation

Uses
	SysUtils,
	SDL2,
	Assets, Fonts, Images, Rendering, Shared
	{$IFDEF LD25_MOBILE}, TouchControls {$ENDIF}
;

Function DisplaySlide(Const Img:PImage):Boolean;
Var
	Q:sInt; dt:uInt;
	Dst: TSDL_Rect;
Begin
	Q:=0;
	While (Q = 0) do begin
		Rendering.BeginFrame();
		Dst.X := (RESOL_W - Img^.W) div 2;
		Dst.Y := 0;
		Dst.W := Img^.W;
		Dst.H := Img^.H;
		DrawImage(Img,NIL,@Dst,NIL);
		Rendering.FinishFrame();

		GetDeltaTime(dt);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit(False)
			end else
			{$IFDEF LD25_MOBILE}
			If (Ev.Type_ = SDL_FingerDown) then Q:=1 else
			{$ENDIF}
			If (Ev.Type_ = SDL_KeyDown) then begin
				If (Ev.Key.Keysym.Sym = SDLK_ESCAPE) or (Ev.Key.Keysym.Sym = SDLK_AC_BACK) then
					Q:=-1
				else
					Q:=1
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end
	end;
	Exit(Q >= 0)
End;

Procedure ShowIntro();
Var
	Idx: uInt;
Begin
	{$IFDEF LD25_MOBILE}
		TouchControls.SetVisibility(TCV_NONE);
	{$ENDIF}

	For Idx := Low(SlideIn) to High(SlideIn) do
		If (Not DisplaySlide(SlideIn[Idx])) then Exit();

	DisplaySlide(TitleGfx)
End;

Procedure ShowOutro();
Const
	FADE_IN_TICKS = 500; // Half a second
Var
	Idx, YPos, Delta: uInt;
	Dst: TSDL_Rect;

	FadeInTime: sInt;
	FadeColour: TSDL_Color;
Begin
	{$IFDEF LD25_MOBILE}
		TouchControls.SetVisibility(TCV_NONE);
	{$ENDIF}

	For Idx := Low(SlideOut) to High(SlideOut) do
		If Not DisplaySlide(SlideOut[Idx]) then Exit();

	FadeInTime := FADE_IN_TICKS;
	FadeColour.R := 0;
	FadeColour.G := 0;
	FadeColour.B := 0;

	Delta := 0;
	While True do begin
		Rendering.BeginFrame();

		Dst.X := 0; Dst.Y := 0;
		Dst.W := TitleGfx^.W; Dst.H := TitleGfx^.H;
		DrawImage(TitleGfx, NIL, @Dst, NIL);

		YPos := TitleGfx^.H;
		Font^.Scale := 2;
		PrintText('A GAME BY SUVE', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);

		YPos += (Font^.SpacingY + Font^.CharH) * Font^.Scale * 5 div 2;
		PrintText('A LUDUM DARE 25 GAME', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);

		YPos += (Font^.SpacingY + Font^.CharH) * Font^.Scale;
		Font^.Scale := 1;
		PrintText('ORIGINALLY MADE IN 48 HOURS IN DECEMBER 2012', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);

		YPos += (Font^.SpacingY + Font^.CharH) * Font^.Scale * 3;
		Font^.Scale := 2;
		PrintText('BIG THANKS TO:', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);

		YPos += (Font^.SpacingY + Font^.CharH) * Font^.Scale * 2;
		PrintText('DANIEL REMAR', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);

		YPos += (Font^.SpacingY + Font^.CharH) * Font^.Scale;
		Font^.Scale := 1;
		PrintText('FOR HERO CORE, WHICH THIS GAME WAS BASED UPON',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE, ALIGN_TOP, NIL);

		Font^.Scale := 2;
		YPos += (Font^.SpacingY + Font^.CharH) * (Font^.Scale + 1);
		PrintText('DEXTERO',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE, ALIGN_TOP, NIL);

		YPos += (Font^.SpacingY + Font^.CharH) * Font^.Scale;
		Font^.Scale := 1;
		PrintText(
			['FOR INTRODUCING ME TO LUDUM DARE','AND CHEERING ME UP DURING THE COMPO'],
			Font,
			(RESOL_W div 2), YPos,
			ALIGN_CENTRE, ALIGN_TOP, NIL
		);

		If(FadeInTime >= 0) then begin
			FadeInTime -= Delta;
			If(FadeInTime >= 0) then begin
				FadeColour.A := (255 * FadeInTime) div FADE_IN_TICKS;
				Shared.DrawRectFilled(NIL, @FadeColour)
			end
		end;

		Rendering.FinishFrame();
		GetDeltaTime(Delta);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			If (Ev.Type_ = SDL_KeyDown) then Exit() else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then begin
				HandleWindowResizedEvent(@Ev)
			end
		end
	end
End;

End.
