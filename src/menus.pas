(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2022 suve (a.k.a. Artur Frenszek-Iwicki)
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
Unit menus;

{$INCLUDE defines.inc}

Interface

Uses
	SDL2;

Const
	CHOICE_QUIT = '!';
	CHOICE_BACK = '~';
	CHOICE_NONE = '?';

Type
	PMenu = ^TMenu;
	TMenu = object
		Private Type
			TMenuItem = record
				Key: TSDL_KeyCode;
				Letter: Char;
				Caption: AnsiString;
				Colour: PSDL_Colour;
				Width: uInt;
			end;
		Private
			Items: Array of TMenuItem;
			FontScale: uInt;
			MaxTextWidth: uInt;
			VertPos, VertSpacing: uInt;

			OffsetsAreDirty: Boolean;
			Procedure RecalculateOffsets();
		Public
			Procedure AddItem(Letter: Char; Caption: AnsiString; Colour: PSDL_Colour);
			Procedure SetFontScale(Scale: uInt);
			Procedure SetVerticalOffset(Offset: uInt);

			Procedure Draw();
			Function ProcessEvent(ev: PSDL_Event):Char;
			Function ProcessKeyboardEvent(ev: PSDL_Event):Char;
			Function ProcessMouseEvent(ev: PSDL_Event):Char;

			Constructor Create();
			Destructor Destroy();
	end;

Implementation

Uses
	Assets, Fonts, Rendering, Shared;

Procedure TMenu.RecalculateOffsets();
Var
	TotalVerticalSpace: uInt;
	RowHeight, RowCount: uInt;
Begin
	TotalVerticalSpace := RESOL_H - Self.VertPos;
	RowHeight := Assets.Font^.CharH * Self.FontScale;
	RowCount := Length(Self.Items);

	Self.VertSpacing := (TotalVerticalSpace - (RowHeight * RowCount)) div (RowCount + 1);
	OffsetsAreDirty := False
End;

Procedure TMenu.AddItem(Letter: Char; Caption: AnsiString; Colour: PSDL_Colour);
Var
	Len: uInt;
Begin
	Len := Length(Self.Items);
	SetLength(Self.Items, Len+1);

	Self.Items[Len].Key := SDLK_A + Ord(Letter) - Ord('A');
	Self.Items[Len].Letter := Letter;
	Self.Items[Len].Caption := {$IFNDEF ANDROID} Letter + ' - ' + {$ENDIF} Caption;
	Self.Items[Len].Colour := Colour;
	Self.Items[Len].Width := (Fonts.GetTextWidth(Self.Items[Len].Caption, Assets.Font) * Self.FontScale) div Assets.Font^.Scale;

	If(Self.Items[Len].Width > Self.MaxTextWidth) then Self.MaxTextWidth := Self.Items[Len].Width;
	Self.OffsetsAreDirty := True
End;

Procedure TMenu.SetFontScale(Scale: uInt);
Var
	Idx, Len: sInt;
Begin
	If (Scale = 0) or (Scale = Self.FontScale) then Exit();

	Len := Length(Self.Items);
	For Idx := 0 to (Len - 1) do
		Self.Items[Idx].Width := (Self.Items[Idx].Width div Self.FontScale) * Scale;
	Self.MaxTextWidth := (Self.MaxTextWidth div Self.FontScale) * Scale;

	Self.FontScale := Scale;
	Self.OffsetsAreDirty := True
End;

Procedure TMenu.SetVerticalOffset(Offset: uInt);
Begin
	If (Offset = Self.VertPos) then Exit();

	Self.VertPos := Offset;
	Self.OffsetsAreDirty := True
End;

Procedure TMenu.Draw();
Var
	Idx: uInt;
	XPos, YPos, RowHeight: uInt;
Begin
	If (Self.OffsetsAreDirty) then Self.RecalculateOffsets();

	{$IFNDEF ANDROID}
	XPos := (RESOL_W - Self.MaxTextWidth) div 2;
	{$ENDIF}
	YPos := Self.VertPos + Self.VertSpacing;
	RowHeight := Assets.Font^.CharH * Self.FontScale;

	Font^.Scale := Self.FontScale;
	For Idx := Low(Self.Items) to High(Self.Items) do begin
		{$IFDEF ANDROID}
		XPos := (RESOL_W - Self.Items[Idx].Width) div 2;
		{$ENDIF}

		Fonts.PrintText(Self.Items[Idx].Caption, Assets.Font, XPos, YPos, ALIGN_LEFT, ALIGN_TOP, Self.Items[Idx].Colour);
		YPos += Self.VertSpacing + RowHeight
	end
End;

Function TMenu.ProcessKeyboardEvent(ev: PSDL_Event): Char;
Var
	Idx: sInt;
Begin
	For Idx := Low(Self.Items) to High(Self.Items) do
		If(Ev^.Key.Keysym.Sym = Self.Items[Idx].Key) then Exit(Self.Items[Idx].Letter);

	If (Ev^.Key.Keysym.Sym = SDLK_Escape) or (Ev^.Key.Keysym.Sym = SDLK_AC_Back) then
		Result := CHOICE_BACK
	else
		Result := CHOICE_NONE
End;

Function TMenu.ProcessMouseEvent(ev: PSDL_Event): Char;
Var
	Idx, Len: sInt;
	YPos, RowHeight: uInt;
Begin
	If (Self.OffsetsAreDirty) then Self.RecalculateOffsets();
	Len := Length(Self.Items);

	YPos := Self.VertPos + Self.VertSpacing;
	RowHeight := Assets.Font^.CharH * Assets.Font^.Scale;

	Idx := (Ev^.Button.Y - YPos) div (RowHeight + VertSpacing);
	If (Idx >= 0) and (Idx < Len) then begin
		YPos := Ev^.Button.Y - YPos - (Idx * (RowHeight + VertSpacing));
		If (YPos < RowHeight) then Exit(Self.Items[Idx].Letter)
	end;

	Result := CHOICE_NONE
End;

Function TMenu.ProcessEvent(ev: PSDL_Event): Char;
Begin
	If (Ev^.Type_ = SDL_QuitEv) then Exit(CHOICE_QUIT);
	If (Ev^.Type_ = SDL_KeyDown) then Exit(Self.ProcessKeyboardEvent(ev));
	If (Ev^.Type_ = SDL_MouseButtonDown) then begin
		{$IFDEF ANDROID} TranslateMouseEventCoords(ev); {$ENDIF}
		Exit(Self.ProcessMouseEvent(ev))
	end;

	If (Ev^.Type_ = SDL_WindowEvent) and (Ev^.Window.Event = SDL_WINDOWEVENT_RESIZED) then
		Rendering.HandleWindowResizedEvent(Ev);

	Result := CHOICE_NONE
End;

Constructor TMenu.Create();
Begin
	SetLength(Self.Items, 0);
	Self.FontScale := 1;
	Self.MaxTextWidth := 0;
	Self.VertPos := TitleGfx^.H;
	Self.OffsetsAreDirty := True
End;

Destructor TMenu.Destroy();
Begin
	SetLength(Self.Items, 0)
End;

end.
