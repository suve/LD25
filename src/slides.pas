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

Procedure FadeIn(Time: uInt);
Var
	FadeColour: TSDL_Color;
Begin
	If Time > FADE_IN_TICKS then Exit();

	FadeColour.R := 0;
	FadeColour.G := 0;
	FadeColour.B := 0;
	FadeColour.A := (255 * (FADE_IN_TICKS - Time)) div FADE_IN_TICKS;
	Shared.DrawRectFilled(NIL, @FadeColour)
End;

Procedure RenderThanksScreen(SlideTime: sInt);
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

	FadeIn(SlideTime);
	Rendering.FinishFrame()
End;

Type
	TStatsTexts = record
		TotalTime: AnsiString;
		BestTime: AnsiString;
		HitsTaken: AnsiString;
		TimesDied: AnsiString;
		KillsMade: AnsiString;
		ShotsFired: AnsiString;
		ShotsHit: AnsiString;
		Accuracy: AnsiString;
	end;

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

Function RenderStatsTexts():TStatsTexts;
Var
	Time, Fired, Hit: uInt;
Begin
	If Stats.TotalTime.Get(@Time) then
		Result.TotalTime := FormatTimeString(Time)
	else
		Result.TotalTime := '???';

	If Stats.BestTime.Get(@Time) then
		Result.BestTime := FormatTimeString(Time)
	else
		Result.BestTime := '???';

	Result.HitsTaken := Stats.HitsTaken.ToString();
	Result.TimesDied := Stats.TimesDied.ToString();
	Result.KillsMade := Stats.KillsMade.ToString();
	Result.ShotsFired := Stats.ShotsFired.ToString();
	Result.ShotsHit := Stats.ShotsHit.ToString();

	If Stats.ShotsFired.Get(@Fired) and Stats.ShotsHit.Get(@Hit) then begin
		If Fired > 0 then
			WriteStr(Result.Accuracy, (Hit * 100) div Fired, '%')
		else
			Result.Accuracy := '-'
	end else
		Result.Accuracy := '???';
End;


Procedure RenderStatsScreen(
	SlideTime: sInt;
	Texts: TStatsTexts;
	BestTimeCheck: TBestTimeCheck
);
Var
	Dst: TSDL_Rect;
	YPos, YStep: uInt;
	OffCenter: uInt;
Begin
	Rendering.BeginFrame();

	Dst.X := 0; Dst.Y := 0;
	Dst.W := TitleGfx^.W; Dst.H := TitleGfx^.H;
	DrawImage(TitleGfx, NIL, @Dst, NIL);

	YPos := TitleGfx^.H + (Font^.CharH * 3 div 2);
	Font^.Scale := 2;
	PrintText('YOUR STATS', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
	YPos += (Font^.SpacingY + Font^.CharH) * Font^.Scale * 2;

	Font^.Scale := 1;
	OffCenter := (RESOL_W + Font^.CharW + Font^.SpacingX * 2) div 2;

	PrintText('TOTAL TIME: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(Texts.TotalTime, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += (Font^.SpacingY + Font^.CharH) * 3 div 2;

	If (BestTimeCheck = BTC_BETTER) or (BestTimeCheck = BTC_FIRST) then begin
		PrintText('! NEW RECORD !', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
	end else begin
		PrintText('BEST: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
		PrintText(Texts.BestTime, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	end;
	YPos += (Font^.SpacingY + Font^.CharH) * 3;
	YStep := (Font^.SpacingY + Font^.CharH) * 9 div 4;

	PrintText('HITS TAKEN: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(Texts.HitsTaken, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	PrintText('TIMES DIED: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(Texts.TimesDied, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	PrintText('SHOTS FIRED: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(Texts.ShotsFired, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	PrintText('SHOTS HIT: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(Texts.ShotsHit, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	PrintText('ACCURACY: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(Texts.Accuracy, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;
	
	PrintText('FOES SLAIN: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(Texts.KillsMade, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	FadeIn(SlideTime);
	Rendering.FinishFrame()
End;

Procedure ShowOutro();
Var
	Idx, Delta, SlideTime: uInt;

	ShowTheStats: Boolean;
	StatsTexts: TStatsTexts;
	BestTimeCheck: TBestTimeCheck;
Begin
	// FIXME: Calling this here really, really stinks.
	//        Should probably do this in main function,
	//        or when exiting the game loop.
	BestTimeCheck := Stats.CheckBestTime();

	For Idx := Low(SlideOut) to High(SlideOut) do
		If Not DisplaySlide(SlideOut[Idx]) then Exit();

	ShowTheStats := False;
	StatsTexts := RenderStatsTexts();
	SlideTime := 0;

	Delta := 0;
	While True do begin
		If Not ShowTheStats then
			RenderThanksScreen(SlideTime)
		else
			RenderStatsScreen(SlideTime, StatsTexts, BestTimeCheck);

		GetDeltaTime(Delta);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If Not ShowTheStats then begin
					ShowTheStats := True;
					SlideTime := 0
				end else Exit()
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then begin
				HandleWindowResizedEvent(@Ev)
			end
		end;
		SlideTime += Delta
	end
End;

End.
