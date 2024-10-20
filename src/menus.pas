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
			Count: sInt;

			FontScale: uInt;
			MaxTextWidth: uInt;
			VertPos, VertSpacing: uInt;

			OffsetsAreDirty: Boolean;
			Procedure RecalculateOffsets();
			Procedure SetItemCaption(Index: sInt; Caption: AnsiString);
		Public
			Function AddItem(Letter: Char; Caption: AnsiString; Colour: PSDL_Colour): sInt;
			Function EditItem(Index: sInt; NewCaption: AnsiString): Boolean;

			Procedure SetFontScale(Scale: uInt);
			Procedure SetVerticalOffset(Offset: uInt);

			Procedure Draw();
			Function ProcessEvent(ev: PSDL_Event):Char;
			Function ProcessKeyboardEvent(ev: PSDL_Event):Char;
			Function ProcessMouseEvent(ev: PSDL_Event):Char;

			Constructor Create();
			Constructor Create(Capacity: uInt);
			Destructor Destroy();
	end;

Procedure DrawTitle();

// FIXME: This should take the event as a parameter,
//        instead of implicitly using Shared.Ev
Function MouseInRect(Const Rect: TSDL_Rect):Boolean; Inline;


Implementation

Uses
	Assets, Colours, Controllers, Fonts, Images, MathUtils, Rendering, Shared
	{$IFDEF LD25_MOBILE}, TouchControls {$ENDIF}
;

Procedure TMenu.RecalculateOffsets();
Var
	TotalVerticalSpace: uInt;
	RowHeight: uInt;
Begin
	TotalVerticalSpace := RESOL_H - Self.VertPos;
	RowHeight := Assets.Font^.CharH * Self.FontScale;

	Self.VertSpacing := (TotalVerticalSpace - (RowHeight * Self.Count)) div (Self.Count + 1);
	OffsetsAreDirty := False
End;

Procedure TMenu.SetItemCaption(Index: sInt; Caption: AnsiString);
Begin
	Self.Items[Index].Caption := {$IFNDEF LD25_MOBILE} Self.Items[Index].Letter + ' - ' + {$ENDIF} Caption;
	Self.Items[Index].Width := (Fonts.GetTextWidth(Self.Items[Index].Caption, Assets.Font) * Self.FontScale) div Assets.Font^.Scale
End;

Function TMenu.AddItem(Letter: Char; Caption: AnsiString; Colour: PSDL_Colour): sInt;
Begin
	Result := Self.Count;
	If (Self.Count = Length(Self.Items)) then SetLength(Self.Items, Self.Count+1);

	// Quite a dirty hack, but eh, good enough
	If (Ord(Letter) >= Ord('A')) then
		Self.Items[Self.Count].Key := SDLK_A + Ord(Letter) - Ord('A')
	else
		Self.Items[Self.Count].Key := SDLK_0 + Ord(Letter) - Ord('0');

	Self.Items[Self.Count].Letter := Letter;
	Self.Items[Self.Count].Colour := Colour;
	SetItemCaption(Self.Count, Caption);

	If(Self.Items[Self.Count].Width > Self.MaxTextWidth) then Self.MaxTextWidth := Self.Items[Self.Count].Width;
	Self.OffsetsAreDirty := True;
	Self.Count += 1
End;

Function TMenu.EditItem(Index: sInt; NewCaption: AnsiString): Boolean;
Var
	OldWidth: uInt;
Begin
	If (Index < 0) or (Index >= Self.Count) then Exit(False);

	OldWidth := Self.Items[Index].Width;
	SetItemCaption(Index, NewCaption);

	// If this was the longest caption, we need to update the MaxTextWidth field.
	If (OldWidth = Self.MaxTextWidth) then begin
		If (Self.Items[Index].Width >= OldWidth) then begin
			// New caption is longer - just overwrite the old value
			Self.MaxTextWidth := Self.Items[Index].Width
		end else begin
			// New caption is shorter - need to determine which existing caption is now the longest
			Self.MaxTextWidth := 0;
			For Index := 0 to (Self.Count - 1) do
				If (Self.Items[Index].Width > Self.MaxTextWidth) then
					Self.MaxTextWidth := Self.Items[Index].Width
		end
	end;
	Result := True
End;

Procedure TMenu.SetFontScale(Scale: uInt);
Var
	Idx: sInt;
Begin
	If (Scale = 0) or (Scale = Self.FontScale) then Exit();

	For Idx := 0 to (Self.Count - 1) do
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
	Idx: sInt;
	XPos, YPos, RowHeight: uInt;
Begin
	If (Self.OffsetsAreDirty) then Self.RecalculateOffsets();

	{$IFNDEF LD25_MOBILE}
	XPos := (RESOL_W - Self.MaxTextWidth) div 2;
	{$ENDIF}
	YPos := Self.VertPos + Self.VertSpacing;
	RowHeight := Assets.Font^.CharH * Self.FontScale;

	Font^.Scale := Self.FontScale;
	For Idx := 0 to (Self.Count - 1) do begin
		{$IFDEF LD25_MOBILE}
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
	For Idx := 0 to (Self.Count - 1) do
		If(Ev^.Key.Keysym.Sym = Self.Items[Idx].Key) then Exit(Self.Items[Idx].Letter);

	If (Ev^.Key.Keysym.Sym = SDLK_Escape) or (Ev^.Key.Keysym.Sym = SDLK_AC_Back) then
		Result := CHOICE_BACK
	else
		Result := CHOICE_NONE
End;

Function TMenu.ProcessMouseEvent(ev: PSDL_Event): Char;
Var
	Idx: sInt;
	YPos, RowHeight: uInt;
Begin
	If (Self.OffsetsAreDirty) then Self.RecalculateOffsets();

	YPos := Self.VertPos + Self.VertSpacing;
	RowHeight := Assets.Font^.CharH * Self.FontScale;

	Idx := (Ev^.Button.Y - YPos) div (RowHeight + VertSpacing);
	If (Idx >= 0) and (Idx < Self.Count) then begin
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
		{$IFDEF LD25_MOBILE} TranslateMouseEventCoords(ev); {$ENDIF}
		Exit(Self.ProcessMouseEvent(ev))
	end;

	{$IFDEF LD25_MOBILE}
	If (Ev^.Type_ = SDL_FingerUp) or (Ev^.Type_ = SDL_FingerDown) or (Ev^.Type_ = SDL_FingerMotion) then begin
		TouchControls.HandleEvent(Ev)
	end else
	{$ENDIF}
	If (Ev^.Type_ = SDL_ControllerDeviceAdded) or (Ev^.Type_ = SDL_ControllerDeviceRemoved) then begin
		Controllers.HandleDeviceEvent(Ev)
	end else
	If (Ev^.Type_ = SDL_JoyBatteryUpdated) then begin
		Controllers.HandleBatteryEvent(Ev)
	end else
	If (Ev^.Type_ = SDL_WindowEvent) and (Ev^.Window.Event = SDL_WINDOWEVENT_RESIZED) then
		Rendering.HandleWindowResizedEvent(Ev);

	Result := CHOICE_NONE
End;

Constructor TMenu.Create();
Begin
	Self.Create(0)
end;

Constructor TMenu.Create(Capacity: uInt);
Begin
	SetLength(Self.Items, Capacity);
	Self.Count := 0;
	Self.FontScale := 1;
	Self.MaxTextWidth := 0;
	Self.VertPos := TitleGfx^.H;
	Self.OffsetsAreDirty := True
End;

Destructor TMenu.Destroy();
Begin
	SetLength(Self.Items, 0)
End;

Procedure DrawTitle();
Const
	VersionText = 'V.' + GAMEVERS
		{$IFDEF LD25_DEBUG} + ' // DEBUG @ ' + {$INCLUDE %DATE%} + ', ' + {$INCLUDE %TIME%}{$ENDIF}
	;
Var
	Dst: TSDL_Rect;
Begin
	Dst.X := 0; Dst.Y := 0;
	Dst.W := TitleGfx^.W; Dst.H := TitleGfx^.H;
	DrawImage(TitleGfx, NIL, @Dst, NIL);

	Font^.Scale := 1;
	PrintText(VersionText, Assets.Font, (RESOL_W div 2), 82, ALIGN_CENTRE, ALIGN_MIDDLE, @WhiteColour)
End;

Function MouseInRect(Const Rect: TSDL_Rect):Boolean; Inline;
Begin
	Result := Overlap(Rect.X, Rect.Y, Rect.W, Rect.H, Ev.Button.X, Ev.Button.Y, 1, 1)
End;

end.
