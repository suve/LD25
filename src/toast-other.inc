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
Uses
	SysUtils,
	SDL2,
	Assets, Colours, Fonts, Rendering, Timekeeping;

Var
	Visible: Boolean;

	EndsAt: uInt;
	TextTop, TextBottom: AnsiString;

Procedure SetVisibility(NewValue: Boolean);
Begin
	If NewValue <> Visible then begin
		EndsAt := 0;
		Visible := NewValue
	end
End;

Const
	TICKS_SHOW = 200;
	TICKS_LINGER = 1600;
	TICKS_HIDE = 400;
	TICKS_TOTAL = TICKS_SHOW + TICKS_LINGER + TICKS_HIDE;

	MAX_MSG_LENGTH = 35;

Procedure Show(Header, Message: AnsiString);
Var
	TicksNow, TicksLeft: uInt;
Begin
	If(Not Visible) then Exit;

	Message := TrimLeft(Message);
	Message := Copy(Message, 1, MAX_MSG_LENGTH);
	Message := TrimRight(Message);
	Message := UpCase(Message);

	TextTop := Header;
	TextBottom := Message;

	TicksNow := Timekeeping.GetTicks();
	If(TicksNow >= EndsAt) then begin
		// Old toast no longer visible. Show for full duration.
		EndsAt := TicksNow + TICKS_TOTAL
	end else begin
		TicksLeft := EndsAt - TicksNow;
		If(TicksLeft <= TICKS_HIDE) then
			// Old toast is currently in its "slide out" animation.
			// Calculate number of ticks needed to make the animation bounce back nicely.
			EndsAt := TicksNow + TICKS_TOTAL - ((TicksLeft * TICKS_SHOW) div TICKS_HIDE)
		else
		If(TicksLeft <= TICKS_HIDE + TICKS_LINGER) then
			// Old toast is currently lingering.
			// Update the timer so new toast gets the full linger time.
			EndsAt := TicksNow + TICKS_HIDE + TICKS_LINGER
		else
			// Old toast is currently in its "slide in" animation.
			// Do nothing, just reuse the timer.
	end
End;

Procedure Render();
Const
	WIDTH = 160;
	HEIGHT = 20;

	MARGIN_X = 2;
	MARGIN_Y = 2;

	ICON_WIDTH = 20;
	ICON_HEIGHT = 15;
	ICON_MARGIN = 3;

Var
	Rect: TSDL_Rect;
	Ticks: uInt;
Begin
	If(Not Visible) then Exit;

	Ticks := Timekeeping.GetTicks();
	If(Ticks >= EndsAt) then Exit();
	Ticks := EndsAt - Ticks;

	Rect.X := (RESOL_W - WIDTH) div 2;
	Rect.W := WIDTH;

	If(Ticks <= TICKS_HIDE) then
		Rect.Y := ((Ticks * HEIGHT) div TICKS_HIDE) - HEIGHT
	else
	If(Ticks <= TICKS_HIDE + TICKS_LINGER) then
		Rect.Y := 0
	else
		Rect.Y := (((TICKS_TOTAL - Ticks) * HEIGHT) div TICKS_SHOW) - HEIGHT;
	Rect.H := HEIGHT;

	SDL_SetRenderDrawColor(Renderer, 255, 255, 255, 255);
	SDL_RenderFillRect(Renderer, @Rect);

	Rect.X += 1;
	Rect.W -= 2;
	Rect.H -= 1;
	SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
	SDL_RenderFillRect(Renderer, @Rect);

	Font^.Scale := 1;
	PrintText(
		TextTop,
		Font,
		(RESOL_W + ICON_WIDTH + ICON_MARGIN) div 2,
		Rect.Y + MARGIN_Y,
		ALIGN_CENTRE,
		ALIGN_TOP,
		@WhiteColour
	);
	PrintText(
		TextBottom,
		Font,
		(RESOL_W + ICON_WIDTH + ICON_MARGIN) div 2,
		Rect.Y + MARGIN_Y + Font^.CharH + Font^.SpacingY,
		ALIGN_CENTRE,
		ALIGN_TOP,
		@WhiteColour
	);

	Rect.X += MARGIN_X;
	Rect.Y += MARGIN_Y;
	Rect.W := ICON_WIDTH;
	Rect.H := ICON_HEIGHT;
	SDL_RenderCopy(Renderer, GamepadGfx^.Tex, NIL, @Rect)
End;
