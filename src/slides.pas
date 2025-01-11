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
	Assets, Colours, Controllers, Fonts, Images, Rendering, Shared, Stats,
	Timekeeping
	{$IFDEF LD25_MOBILE}, TouchControls {$ENDIF}
;

Const
	FADE_IN_TICKS = 240; // Slightly under a quarter of a second

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

Procedure RenderSlide(SlideTime: uInt; Data: Pointer);
Var
	Img: PImage;
	Dst: TSDL_Rect;
Begin
	Img := Data;
	Dst.X := (RESOL_W - Img^.W) div 2;
	Dst.Y := 0;
	Dst.W := Img^.W;
	Dst.H := Img^.H;
	DrawImage(Img, NIL, @Dst, NIL);

	FadeIn(SlideTime)
End;

Type
	PSlideFunc = ^TSlideFunc;
	TSlideFunc = Procedure(SlideTime: uInt; Data: Pointer);

Procedure ShowSlides(Funcs: PSlideFunc; Data: PPointer; Count: uInt);
Type
	TSlideAction = (
		ACT_NONE,
		ACT_PREV,
		ACT_NEXT,
		ACT_QUIT
	);
Var
	Idx, DeltaTime, SlideTime: uInt;
	Action: TSlideAction;

	Procedure OnSlideChanged();
	Begin
		SlideTime := 0;
		{$IFDEF LD25_MOBILE}
			If(Idx > 0) then
				TouchControls.SetVisibility(TCV_SLIDE_BOTH)
			else
				TouchControls.SetVisibility(TCV_SLIDE_RIGHT)
		{$ENDIF}
	End;

Begin
	Idx := 0;
	OnSlideChanged();
	While (Idx < Count) do begin
		Rendering.BeginFrame();
		Funcs[Idx](SlideTime, Data[Idx]);
		Rendering.FinishFrame();

		Action := ACT_NONE;
		DeltaTime := AdvanceTime();
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			{$IFDEF LD25_MOBILE}
			If (Ev.Type_ = SDL_FingerUp) or (Ev.Type_ = SDL_FingerDown) or (Ev.Type_ = SDL_FingerMotion) then begin
				TouchControls.HandleEvent(@Ev)
			end else
			{$ENDIF}
			If (Ev.Type_ = SDL_KeyDown) then Case(Ev.Key.Keysym.Sym) of
				SDLK_ESCAPE, SDLK_AC_BACK:
					Action := ACT_QUIT;
				SDLK_RIGHT, SDLK_RETURN, SDLK_SPACE:
					Action := ACT_NEXT;
				SDLK_LEFT:
					Action := ACT_PREV;
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

		Case Action of
			ACT_PREV: If(Idx > 0) then begin
				Idx -= 1;
				OnSlideChanged()
			end;
			ACT_NEXT: begin
				Idx += 1;
				OnSlideChanged()
			end;
			ACT_QUIT: Idx := Count;
			ACT_NONE: SlideTime += DeltaTime
		end
	end
End;

Procedure ShowIntro();
Var
	Funcs: Array[0..SLIDES_IN] of TSlideFunc;
	Data: Array[0..SLIDES_IN] of Pointer;
	Idx: uInt;
Begin
	For Idx := 0 to (SLIDES_IN - 1) do begin
		Funcs[Idx] := @RenderSlide;
		Data[Idx] := SlideIn[Idx]
	end;

	Funcs[SLIDES_IN] := @RenderSlide;
	Data[SLIDES_IN] := TitleGfx;

	ShowSlides(Funcs, Data, SLIDES_IN + 1)
End;

Procedure RenderThanksScreen(SlideTime: uInt; Data: Pointer);
Var
	YPos: uInt;
	Dst: TSDL_Rect;
Begin
	Dst.X := 0; Dst.Y := 0;
	Dst.W := TitleGfx^.W; Dst.H := TitleGfx^.H;
	DrawImage(TitleGfx, NIL, @Dst, NIL);

	YPos := TitleGfx^.H;
	Font^.Scale := 2;
	PrintText('A GAME BY SUVE', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

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

	FadeIn(SlideTime)
End;

Type
	PPlayerStats = ^TPlayerStats;
	TPlayerStats = record
		TotalTime: AnsiString;
		BestTime: AnsiString;
		HitsTaken: AnsiString;
		TimesDied: AnsiString;
		KillsMade: AnsiString;
		ShotsFired: AnsiString;
		ShotsHit: AnsiString;
		Accuracy: AnsiString;
		Distance: AnsiString;
		BestTimeCheck: TBestTimeCheck;
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

Procedure RenderStatsTexts(Ptr: PPlayerStats);
Var
	Time, Fired, Hit: uInt;
	Distance: Double;
Begin
	If Stats.TotalTime.Get(@Time) then
		Ptr^.TotalTime := FormatTimeString(Time)
	else
		Ptr^.TotalTime := '???';

	If Stats.BestTime.Get(@Time) then
		Ptr^.BestTime := FormatTimeString(Time)
	else
		Ptr^.BestTime := '???';

	Ptr^.HitsTaken := Stats.HitsTaken.ToString();
	Ptr^.TimesDied := Stats.TimesDied.ToString();
	Ptr^.KillsMade := Stats.KillsMade.ToString();
	Ptr^.ShotsFired := Stats.ShotsFired.ToString();
	Ptr^.ShotsHit := Stats.ShotsHit.ToString();

	If Stats.ShotsFired.Get(@Fired) and Stats.ShotsHit.Get(@Hit) then begin
		If Fired > 0 then
			WriteStr(Ptr^.Accuracy, (Hit * 100) div Fired, '%')
		else
			Ptr^.Accuracy := '-'
	end else
		Ptr^.Accuracy := '???';

	If Stats.DistanceTravelled.Get(@Distance) then
		WriteStr(Ptr^.Distance, (Distance / TILE_W):0:1, ' TILES')
	else
		Ptr^.Distance := '???';
End;


Procedure RenderStatsScreen(SlideTime: uInt; Data: Pointer);
Var
	PlaSta: PPlayerStats;
	Dst: TSDL_Rect;
	YPos, YStep: uInt;
	OffCenter: uInt;
Begin
	PlaSta := Data;

	Dst.X := 0; Dst.Y := 0;
	Dst.W := TitleGfx^.W; Dst.H := TitleGfx^.H;
	DrawImage(TitleGfx, NIL, @Dst, NIL);

	YPos := TitleGfx^.H;
	Font^.Scale := 2;
	PrintText('YOUR STATS', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);
	YPos += (Font^.SpacingY + Font^.CharH) * Font^.Scale * 2;

	Font^.Scale := 1;
	OffCenter := (RESOL_W + Font^.CharW + Font^.SpacingX * 2) div 2;

	PrintText('TOTAL TIME: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(PlaSta^.TotalTime, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += (Font^.SpacingY + Font^.CharH) * 3 div 2;

	If (PlaSta^.BestTimeCheck = BTC_BETTER) or (PlaSta^.BestTimeCheck = BTC_FIRST) then begin
		PrintText('! NEW RECORD !', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
	end else begin
		PrintText('BEST: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, @GreyColour);
		PrintText(PlaSta^.BestTime, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	end;
	YPos += (Font^.SpacingY + Font^.CharH) * 3;
	YStep := (Font^.SpacingY + Font^.CharH) * 9 div 4;

	PrintText('DISTANCE TRAVELLED: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, @WhiteColour);
	PrintText(PlaSta^.Distance, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	PrintText('HITS TAKEN: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, @WhiteColour);
	PrintText(PlaSta^.HitsTaken, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	PrintText('TIMES DIED: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(PlaSta^.TimesDied, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	PrintText('SHOTS FIRED: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(PlaSta^.ShotsFired, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	PrintText('SHOTS HIT: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(PlaSta^.ShotsHit, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	PrintText('ACCURACY: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(PlaSta^.Accuracy, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;
	
	PrintText('FOES SLAIN: ', Font, OffCenter, YPos, ALIGN_RIGHT, ALIGN_TOP, NIL);
	PrintText(PlaSta^.KillsMade, Font, OffCenter, YPos, ALIGN_LEFT, ALIGN_TOP, NIL);
	YPos += YStep;

	FadeIn(SlideTime)
End;

Procedure ShowOutro();
Var
	PlayerStats: TPlayerStats;

	Funcs: Array[0..(SLIDES_OUT + 1)] of TSlideFunc;
	Data: Array[0..(SLIDES_OUT + 1)] of Pointer;
	Idx: uInt;
Begin
	// FIXME: Calling this here really, really stinks.
	//        Should probably do this in main function,
	//        or when exiting the game loop.
	PlayerStats.BestTimeCheck := Stats.CheckBestTime();
	RenderStatsTexts(@PlayerStats);

	SanitizeColourOrder();
	For Idx := 0 to 7 do begin
		Funcs[Idx] := @RenderSlide;
		Data[Idx] := SlideOut[ColOrder[Idx]]
	end;
	For Idx := 8 to (SLIDES_OUT - 1) do begin
		Funcs[Idx] := @RenderSlide;
		Data[Idx] := SlideOut[Idx]
	end;

	Funcs[SLIDES_OUT] := @RenderThanksScreen;
	Data[SLIDES_OUT] := NIL;

	Funcs[SLIDES_OUT + 1] := @RenderStatsScreen;
	Data[SLIDES_OUT + 1] := @PlayerStats;

	ShowSlides(Funcs, Data, SLIDES_OUT + 2)
End;

End.
