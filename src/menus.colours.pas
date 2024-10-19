(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2018-2024 suve (a.k.a. Artur Frenszek-Iwicki)
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
Unit Menus.Colours;

{$INCLUDE defines.inc}

Interface

Procedure SetColours();


Implementation

Uses
	SysUtils,
	SDL2,
	Assets, Colours, Fonts, Images, Menus, Rendering, Rooms, Timekeeping,
	Shared;

(*
 * TODO:
 * The drawing code is copy-pasted from Game.DrawRoom().
 * Think of a way to reduce duplication.
 *)
Procedure DrawColourPreview(Const Colour: PSDL_Colour; Const PosX, PosY: sInt);
Const
	PreviewW = 8;
	PreviewH = 4;
	PreviewMap: Array[0..(PreviewH-1), 0..(PreviewW-1)] of Char = (
		('X', '-', '-', '-', '=', '-', '-', '+'),
		('X', 'X', ' ', ' ', ' ', ' ', ' ', '|'),
		(':', ' ', ' ', ' ', ' ', ' ', ' ', 'D'),
		('X', 'X', ' ', '<', '-', '>', ' ', '|')
	);
Var
	X, Y: sInt;
	Tile: TTile;
	Src, Dst: TSDL_Rect;
Begin
	// All tiles have the same size, no need to set this in the loop
	Src.W:=TILE_W; Src.H:=TILE_H;
	Dst.W:=TILE_W; Dst.H:=TILE_H;

	Src.X:=0;
	For Y:=0 to (PreviewH-1) do For X:=0 to (PreviewW-1) do begin
		Tile:=TRoom.CharToTile(PreviewMap[Y][X]);
		If (Tile = TILE_NONE) then Continue;

		Dst.X := PosX + (X*TILE_W);
		Dst.Y := PosY + (Y*TILE_H);
		Src.Y := Ord(Tile)*TILE_H;
		DrawImage(TileGfx,@Src,@Dst,Colour)
	end
End;

Procedure SetSingleColour(Const idx: sInt);
Const
	RectWidth = 128;
	RectHeight = 64;
Var
	idxName: AnsiString;
	CurrentCol: TSDL_Colour;

	Menu: TMenu;
	Choice: Char;
	Changed: Boolean;
	Finished: Boolean;

	pc: uInt;
	YPos: sInt;
Begin
	idxName := UpperCase(ColourName[idx]);
	CurrentCol := MapColour[idx];

	Menu.Create();
	Menu.SetFontScale(2);
	Menu.AddItem('R', 'RED:   #'+HexStr(CurrentCol.R, 2), @MenuActiveColour);
	Menu.AddItem('G', 'GREEN: #'+HexStr(CurrentCol.G, 2), @MenuActiveColour);
	Menu.AddItem('B', 'BLUE:  #'+HexStr(CurrentCol.B, 2), @MenuActiveColour);
	Menu.AddItem('D', 'DEFAULT', @MenuActiveColour);

	Finished := False;
	While Not Finished do begin
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2; YPos:=TitleGfx^.H;
		PrintText('COLOUR SETTINGS', Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);

		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		PrintText(idxName, Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);

		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		DrawColourPreview(@CurrentCol, (RESOL_W - RectWidth) div 2, YPos);

		YPos += RectHeight + (Font^.CharH * Font^.Scale) div 2;
		Menu.SetVerticalOffset(YPos);
		Menu.Draw();

		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		Changed := False;
		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = 'R') then begin
				CurrentCol.R := CurrentCol.R + $10;
				Changed := True
			end else
			If (Choice = 'G') then begin
				CurrentCol.G := CurrentCol.G + $10;
				Changed := True
			end else
			If (Choice = 'B') then begin
				CurrentCol.B := CurrentCol.B + $10;
				Changed := True
			end else
			If (Choice = 'D') then begin
				CurrentCol:=DefaultMapColour[idx];
				Changed := True
			end else
			If (Choice = CHOICE_BACK) then begin
				For pc:=0 to 7 do If(CentralPalette[pc] = MapColour[idx]) then CentralPalette[pc] := CurrentCol;
				For pc:=0 to 7 do If(PaletteColour[pc] = MapColour[idx]) then PaletteColour[pc] := CurrentCol;
				MapColour[idx] := CurrentCol;
				Finished := True
			end else
			If (Choice = CHOICE_QUIT) then begin
				Shutdown := True;
				Finished := True
			end
		end;

		If (Changed) then begin
			Menu.EditItem(0, 'RED:   #'+HexStr(CurrentCol.R, 2));
			Menu.EditItem(1, 'GREEN: #'+HexStr(CurrentCol.G, 2));
			Menu.EditItem(2, 'BLUE:  #'+HexStr(CurrentCol.B, 2))
		end
	end;
	Menu.Destroy()
End;

Procedure SetColours();
Var
	Idx: uInt;

	Menu: TMenu;
	Choice: Char;
	Selection: sInt;
	Finished: Boolean;
Begin
	Menu.Create(8);
	Menu.SetFontScale(2);
	For Idx := 0 to 7 do Menu.AddItem(Chr(48 + Idx), UpperCase(ColourName[Idx]), @MenuActiveColour);
	Menu.SetVerticalOffset(TitleGfx^.H + (Font^.CharH * 3));

	Finished := False;
	Repeat
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2;
		PrintText('COLOUR SETTINGS', Font, (RESOL_W div 2), TitleGfx^.H, ALIGN_CENTRE, ALIGN_TOP, NIL);

		Menu.Draw();
		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		Selection := -1;
		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = CHOICE_QUIT) then begin
				Shutdown := True;
				Finished := True
			end else
			If (Choice = CHOICE_BACK) then Finished := True
			else
			If (Choice <> CHOICE_NONE) then Selection := Ord(Choice) - 48
		end;
		If (Selection >= 0) and (Selection <= 7) then SetSingleColour(Selection)
	Until Finished;
	Menu.Destroy()
End;

End.
