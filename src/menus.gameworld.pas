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
Unit Menus.Gameworld;

{$INCLUDE defines.inc}

Interface

Type
	TGameworldSelectionReason = (
		GWSR_NEW_GAME,
		GWSR_LOAD_GAME
	);

Function GameworldDialog(Const Reason: TGameworldSelectionReason): Char;


Implementation

Uses
	SDL2,
	Assets, Colours, Fonts, Menus, Rendering, Shared, Timekeeping;

Function GameworldDialog(Const Reason: TGameworldSelectionReason): Char;
Const
	WorldName: Array[TGameMode] of AnsiString = (
		'TUTORIAL',
		'CLASSIC'
	);
Var
	Msg: AnsiString;
	OK: Array[TGameMode] of Boolean;
	GM: TGameMode;

	Menu: TMenu;
	Col: PSDL_Colour;
	Choice: Char;
	YPos: uInt;
Begin
	If(Reason = GWSR_LOAD_GAME) then begin
		Msg:='LOAD GAME';
		For GM:=Low(GM) to High(GM) do Ok[GM]:=SaveExists[GM]
	end else begin
		Msg:='NEW GAME';
		For GM:=Low(GM) to High(GM) do Ok[GM]:=True
	end;

	Menu.Create(Length(WorldName));
	Menu.SetFontScale(2);
	For GM := Low(GM) to High(GM) do begin
		If (Ok[GM]) then
			Col := @MenuActiveColour
		else
			Col := @MenuInactiveColour;
		Menu.AddItem(WorldName[GM][1], WorldName[GM], Col)
	end;

	Result := CHOICE_NONE;
	While (Result = CHOICE_NONE) do begin
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2;
		YPos := TitleGfx^.H;
		PrintText(Msg, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		PrintText('SELECT GAMEWORLD', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
		YPos += (Font^.CharH * Font^.Scale);

		Menu.SetVerticalOffset(YPos);
		Menu.Draw();

		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = 'T') then begin
				If (Ok[GM_TUTORIAL]) then Result := 'T'
			end else
			If (Choice = 'C') then begin
				If (Ok[GM_ORIGINAL]) then Result := 'C'
			end else
			If (Choice = CHOICE_QUIT) then begin
				Shutdown := True;
				Result := 'Q'
			end else
			If (Choice = CHOICE_BACK) then Result := 'Q'
		end
	end;
	Menu.Destroy()
End;

End.
