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
Unit toast;

{$INCLUDE defines.inc}

Interface

Procedure Show(Header, Message: AnsiString);
Procedure SetVisibility(NewValue: Boolean);

Procedure Update(dt: uInt);
Procedure Render();


Implementation

Uses
	SysUtils,
	SDL2, ctypes,
	Assets, Colours, Fonts, Rendering;

Var
	Visible: Boolean;
	Ticks: sInt;
	TextTop, TextBottom: AnsiString;

Procedure SetVisibility(NewValue: Boolean);
Begin
	If NewValue <> Visible then begin
		Ticks := 0;
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
	TopWidth, BottomWidth: uInt;
Begin
	If(Not Visible) then Exit;

	Message := TrimLeft(Message);
	Message := Copy(Message, 1, MAX_MSG_LENGTH);
	Message := TrimRight(Message);
	Message := UpCase(Message);

	TextTop := Header;
	TextBottom := Message;

	If(Ticks <= 0) then begin
		Ticks := TICKS_TOTAL
	end else
	If(Ticks <= TICKS_HIDE) then begin
		Ticks := TICKS_TOTAL - ((Ticks * TICKS_SHOW) div TICKS_HIDE)
	end else
	If(Ticks <= TICKS_HIDE + TICKS_LINGER) then begin
		Ticks := TICKS_HIDE + TICKS_LINGER
	end
End;

Procedure Update(dt: uInt);
Begin
	If(Ticks > 0) then Ticks -= dt
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
Begin
	If((Not Visible) or (Ticks <= 0)) then Exit;

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

End.
