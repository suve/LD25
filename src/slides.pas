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
	Assets, Fonts, Images, Rendering, Shared, Stats
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
	For Idx := Low(SlideIn) to High(SlideIn) do
		If (Not DisplaySlide(SlideIn[Idx])) then Exit();

	DisplaySlide(TitleGfx)
End;

Const
	FADE_IN_TICKS = 320; // Slightly under one third of a second

Procedure FadeIn(Time: sInt);
Var
	FadeColour: TSDL_Color;
Begin
	If Time < 0 then Exit();

	FadeColour.R := 0;
	FadeColour.G := 0;
	FadeColour.B := 0;
	FadeColour.A := (255 * Time) div FADE_IN_TICKS;
	Shared.DrawRectFilled(NIL, @FadeColour)
End;

Procedure RenderThanksScreen(FadeInTime: sInt);
Var
	YPos: uInt;
	Dst: TSDL_Rect;
Begin
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

	FadeIn(FadeInTime);
	Rendering.FinishFrame()
End;

Procedure RenderStatsScreen(
	FadeInTime: sInt;
	TimeText, DeathsText, HitCountText: AnsiString
);
Const
	STAT_LINES = 3;
Var
	Dst: TSDL_Rect;
	YStep, YPos: uInt;
Begin
	Rendering.BeginFrame();

	Dst.X := 0; Dst.Y := 0;
	Dst.W := TitleGfx^.W; Dst.H := TitleGfx^.H;
	DrawImage(TitleGfx, NIL, @Dst, NIL);

	YStep := (Font^.SpacingY + Font^.CharH) * 3 * STAT_LINES;
	YStep := (RESOL_H - TitleGfx^.H - YStep) div (STAT_LINES + 1);

	YPos := TitleGfx^.H + YStep;
	Font^.Scale := 2;
	PrintText('TOTAL TIME', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
	YPos += (Font^.SpacingY + Font^.CharH) * 5 div 2;

	Font^.Scale := 1;
	PrintText(TimeText, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
	YPos += (Font^.SpacingY + Font^.CharH) * 4;

	Font^.Scale := 2;
	PrintText('HITS TAKEN', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
	YPos += (Font^.SpacingY + Font^.CharH) * 5 div 2;

	Font^.Scale := 1;
	PrintText(HitCountText, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
	YPos += (Font^.SpacingY + Font^.CharH) * 4;

	Font^.Scale := 2;
	PrintText('TIMES DIED', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
	YPos += (Font^.SpacingY + Font^.CharH) * 5 div 2;

	Font^.Scale := 1;
	PrintText(DeathsText, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
	YPos += (Font^.SpacingY + Font^.CharH) * 4;

	FadeIn(FadeInTime);
	Rendering.FinishFrame()
End;

Function FormatTimeString(Time: uInt): AnsiString;
Const
	ONE_SECOND = 1000;
	ONE_MINUTE = 60 * ONE_SECOND;
	ONE_HOUR = 60 * ONE_MINUTE;
	ONE_DAY = 24 * ONE_HOUR;
Var
	OverOneDay: Boolean;
	OverOneHour: Boolean;
Begin
	Result := '';
	OverOneDay := (Time >= ONE_DAY);
	OverOneHour := (Time >= ONE_HOUR);

	If OverOneDay then begin
		Result += Shared.IntToStr(Time div ONE_DAY) + ':';
		Time := Time mod ONE_DAY
	end;
	If (OverOneDay or OverOneHour) then begin
		Result += Shared.IntToStr(Time div ONE_HOUR, 2) + ':';
		Time := Time mod ONE_HOUR
	end;

	Result += Shared.IntToStr(Time div ONE_MINUTE, 2) + ':';
	Time := Time mod ONE_MINUTE;
	Result += Shared.IntToStr(Time div ONE_SECOND, 2);

	If Not OverOneHour then begin
		Time := Time mod ONE_SECOND;
		Result += '.' + Shared.IntToStr(Time, 3)
	end
End;

Procedure ShowOutro();
Var
	Idx, Delta: uInt;
	FadeInTime: sInt;

	Value: uInt;
	TotalTimeText: AnsiString;
	DeathsText, HitCountText: AnsiString;
	ShowTheStats: Boolean;
Begin
	For Idx := Low(SlideOut) to High(SlideOut) do
		If Not DisplaySlide(SlideOut[Idx]) then Exit();

	If Stats.TotalTime.Get(@Value) then
		TotalTimeText := FormatTimeString(Value)
	else
		TotalTimeText := '???';

	If Stats.HitsTaken.Get(@Value) then
		HitCountText := Shared.IntToStr(Value)
	else
		HitCountText := '???';

	If Stats.TimesDied.Get(@Value) then
		DeathsText := Shared.IntToStr(Value)
	else
		DeathsText := '???';

	ShowTheStats := False;
	FadeInTime := FADE_IN_TICKS;

	Delta := 0;
	While True do begin
		If(FadeInTime >= 0) then FadeInTime -= Delta;

		If Not ShowTheStats then
			RenderThanksScreen(FadeInTime)
		else
			RenderStatsScreen(FadeInTime, TotalTimeText, DeathsText, HitCountText);

		GetDeltaTime(Delta);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If Not ShowTheStats then begin
					ShowTheStats := True;
					FadeInTime := FADE_IN_TICKS;
				end else Exit()
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then begin
				HandleWindowResizedEvent(@Ev)
			end
		end
	end
End;

End.
