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
Unit Menus.Main;

{$INCLUDE defines.inc}

Interface

Function MainMenu():Char;


Implementation

Uses
	SDL2,
	Colours, ConfigFiles, Menus, Rendering, Shared, Timekeeping
	{$IFDEF LD25_MOBILE}, TouchControls {$ENDIF};

Function MainMenu():Char;
Var
	GM: TGameMode;
	IHasSaves: Boolean;
	ContinueColour: PSDL_Colour;
	LoadColour: PSDL_Colour;

	Menu: TMenu;
	Choice: Char;
Begin
	If (GameOn) then
		ContinueColour := @MenuActiveColour
	else
		ContinueColour := @MenuInactiveColour;

	IHasSaves := False;
	For GM:=Low(GM) to High(GM) do If (SaveExists[GM]) then begin
		IHasSaves:=True;
		Break
	end;
	If (IHasSaves) then
		LoadColour := @MenuActiveColour
	else
		LoadColour := @MenuInactiveColour;

	Menu.Create(9);
	Menu.SetFontScale(2);
	Menu.AddItem('I', 'INTRODUCTION', @MenuActiveColour);
	Menu.AddItem('C', 'CONTINUE', ContinueColour);
	Menu.AddItem('N', 'NEW GAME', @MenuActiveColour);
	Menu.AddItem('L', 'LOAD GAME', LoadColour);
	{$IFNDEF LD25_MOBILE}
		Menu.AddItem('B', 'BIND KEYS', @MenuActiveColour);
	{$ELSE}
		Menu.AddItem('O', 'CHANGE OPTIONS', @MenuActiveColour);
	{$ENDIF}
	Menu.AddItem('P', 'GAMEPAD SETTINGS', @MenuActiveColour);
	Menu.AddItem('S', 'SET COLOURS', @MenuActiveColour);
	{$IFDEF LD25_DONATE}
		Menu.AddItem('D', 'DONATE', @MenuActiveColour);
	{$ENDIF}
	Menu.AddItem('Q', 'QUIT', @MenuActiveColour);

	{$IFDEF LD25_MOBILE}
		TouchControls.SetVisibility(TCV_ONLY_BACK);
	{$ENDIF}

	Result := CHOICE_NONE;
	While (Result = CHOICE_NONE) do begin
		Rendering.BeginFrame();
		DrawTitle();
		Menu.Draw();
		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = CHOICE_QUIT) or (Choice = CHOICE_BACK) then begin
				Shutdown := True;
				Result := 'Q'
			end else
			If (Choice = 'C') then begin
				If (GameOn) then Result := 'C'
			end else
			If (Choice = 'L') then begin
				If (IHasSaves) then Result := 'L'
			end else
			If (Choice <> CHOICE_NONE) then Result := Choice
		end
	end;
	Menu.Destroy()
End;

End.
