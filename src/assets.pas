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
Unit Assets; 

{$INCLUDE defines.inc}


Interface
Uses
	SysUtils,
	SDL2, SDL2_mixer,
	Fonts, Images, Rooms, Shared;

Const
	NEW_MAP_W = 10; NEW_MAP_H = 10; NEW_ROOMNUM = NEW_MAP_W*NEW_MAP_H;
	ORG_MAP_W = 7; ORG_MAP_H = 7; ORG_ROOMNUM = ORG_MAP_W*ORG_MAP_H;
	TUT_MAP_W = 3; TUT_MAP_H = 3; TUT_ROOMNUM = TUT_MAP_W*TUT_MAP_H;
	
	SLIDES_IN = 6;
	SLIDES_OUT = 10;

	WALL_SFX = 4; METAL_SFX = 3; DIE_SFX = 6; SHOT_SFX = 4; HIT_SFX = 1; EXTRA_SFX = 4;
	SFX_WALL = 0; SFX_METAL = SFX_WALL+WALL_SFX; SFX_DIE = SFX_METAL+METAL_SFX;
	SFX_SHOT = SFX_DIE+DIE_SFX; SFX_HIT = SFX_SHOT + SHOT_SFX; SFX_EXTRA = SFX_HIT+HIT_SFX;
	SOUNDS = SFX_EXTRA + EXTRA_SFX;

Var
	IconSurf: PSDL_Surface;
	TitleGfx, UIgfx: PImage;
	TileGfx, ColourGfx, EntityGfx: PImage;

	SlideIn  : Array[0..SLIDES_IN-1] of PImage;
	SlideOut : Array[0..SLIDES_OUT-1] of PImage;

	GamepadGfx, GamepadButtonsGfx: PImage;

	{$IFDEF LD25_MOBILE}
	TouchControlsGfx: PImage;
	{$ENDIF}

	{$IFNDEF ANDOID}
	ToastGfx: PImage;
	{$ENDIF}

	Font, NumFont : PFont;

	Sfx: Array[0..SOUNDS-1] of PMix_Chunk;
	
	OrgRoom:Array[0..(ORG_MAP_W-1), 0..(ORG_MAP_H-1)] of PRoom;
	TutRoom:Array[0..(TUT_MAP_W-1), 0..(TUT_MAP_H-1)] of PRoom;

Type
	TLoadingStatus = (
		ALS_OK,
		ALS_FAILED,
		ALS_INTERRUPTED
	);
	TLoadingResult = record
		Status: TLoadingStatus;
		FileName: AnsiString;
		ErrStr: AnsiString;
	end;
	TUpdateProc = Procedure(Name: AnsiString; Perc: Double);

Procedure RegisterAllAssets();


Function  LoadAssets(Const UpdateCallback: TUpdateProc = NIL):TLoadingResult;
Procedure LoadAndSetWindowIcon();

Procedure FreeAssets();


Implementation
Uses
	SDL2_Image,
	Colours, ConfigFiles, FloatingText, Rendering;

Type
	PPFont = ^PFont;
	PPImage = ^PImage;
	PPRoom = ^PRoom;
	PPMix_Chunk = ^PMix_Chunk;

	TAssetKind = (
		ASSET_FONT,
		ASSET_IMAGE,
		ASSET_ROOM,
		ASSET_SOUND,
		ASSET_RAWPTR
	);

	TAsset = record
		Path: AnsiString;
		
		Case Kind: TAssetKind of
			ASSET_FONT: (
				Font: PPFont;
				FontW, FontH: sInt;
				FontStartChar: Char;
			);
			ASSET_IMAGE: (
				Image: PPImage;
				ImageTransCol: PSDL_Colour;
			);
			ASSET_ROOM: (
				Room: PPRoom;
				RoomX, RoomY: sInt;
			);
			ASSET_SOUND: (
				Sound: PPMix_Chunk
			);
			ASSET_RAWPTR: (Ptr: ^Pointer);
	end;

Var
	AssetCount: sInt;
	AssetArr: Array of TAsset;

Procedure RegisterAsset(Const Asset:TAsset);
Const
	ResizeStep = 32;
Begin
	If(AssetCount >= Length(AssetArr)) then SetLength(AssetArr, Length(AssetArr) + ResizeStep);
	
	AssetArr[AssetCount] := Asset;
	AssetCount += 1
End;

Procedure RegisterFont(Const Path: AnsiString; Const Font: PPFont; Const StartChar: Char; Const CharW, CharH: sInt); 
Var
	Asset: TAsset;
Begin
	Asset.Kind := ASSET_FONT;
	Asset.Path := Path;
	Asset.Font := Font;
	Asset.FontStartChar := StartChar;
	Asset.FontW := CharW;
	Asset.FontH := CharH;
	
	RegisterAsset(Asset)
End;

Procedure RegisterImage(Const Path: AnsiString; Const Image: PPImage; Const TransparentColour: PSDL_Colour); 
Var
	Asset: TAsset;
Begin
	Asset.Kind := ASSET_IMAGE;
	Asset.Path := Path;
	Asset.Image := Image;
	Asset.ImageTransCol := TransparentColour;
	
	RegisterAsset(Asset)
End;

Procedure RegisterRoom(Const Path: AnsiString; Const Room: PPRoom; Const X, Y: sInt);
Var
	Asset: TAsset;
Begin
	Asset.Kind := ASSET_ROOM;
	Asset.Path := Path;
	Asset.Room := Room;
	Asset.RoomX := X;
	Asset.RoomY := Y;

	RegisterAsset(Asset)
End;

Procedure RegisterSound(Const Path: AnsiString; Const Sound: PPMix_Chunk); 
Var
	Asset: TAsset;
Begin
	Asset.Kind := ASSET_SOUND;
	Asset.Path := Path;
	Asset.Sound := Sound;

	RegisterAsset(Asset)
End;

Const
	COLOUR_BLACK: TSDL_Colour = (R: 0; G: 0; B: 0; A: 255);
	COLOUR_GREY: TSDL_Colour = (R: $80; G: $80; B: $80; A: 255);
	COLOUR_LIME: TSDL_Colour = (R: 0; G: 255; B: 0; A: 255);

Procedure RegisterAllAssets();
Var
	X, Y, idx, Offset: sInt;
Begin
	RegisterImage('gfx/title.png', @TitleGfx, @COLOUR_BLACK);
	RegisterFont('gfx/font.png', @Font, ' ', 5, 7);
	
	RegisterImage('gfx/ui.png', @UIgfx, @COLOUR_LIME);
	RegisterFont('gfx/numbers.png', @NumFont, '0', 3, 5);
	
	RegisterImage('gfx/colours.png', @ColourGfx, @COLOUR_GREY);
	RegisterImage('gfx/tiles.png', @TileGfx, @COLOUR_BLACK);
	RegisterImage('gfx/entities.png', @EntityGfx, @COLOUR_BLACK);

	For idx:=0 to (SLIDES_IN-1) do RegisterImage('slides/intro' + IntToStr(idx) + '.png', @SlideIn[idx], @COLOUR_BLACK);
	For idx:=0 to (SLIDES_OUT-1) do RegisterImage('slides/outro' + IntToStr(idx) + '.png', @SlideOut[idx], @COLOUR_BLACK);

	RegisterImage('gfx/gamepad.png', @GamepadGfx, @COLOUR_LIME);
	RegisterImage('gfx/gamepad-buttons.png', @GamepadButtonsGfx, @COLOUR_LIME);

	{$IFDEF LD25_MOBILE}
	RegisterImage('gfx/touch-controls.png', @TouchControlsGfx, @COLOUR_LIME);
	{$ENDIF}

	{$IFNDEF ANDROID}
	RegisterImage('gfx/toasts.png', @ToastGfx, @COLOUR_LIME);
	{$ENDIF}

	// ----- ROOMS -----
	For Y:=0 to (TUT_MAP_H-1) do
		For X:=0 to (TUT_MAP_W-1) do
			RegisterRoom('map/tut/' + IntToStr(X) + '-' + IntToStr(Y) + '.txt', @TutRoom[X][Y], X, Y);

	For Y:=0 to (ORG_MAP_H-1) do
		For X:=0 to (ORG_MAP_W-1) do
			RegisterRoom('map/org/' + IntToStr(X) + '-' + IntToStr(Y) + '.txt', @OrgRoom[X][Y], X, Y);

	// ----- SOUNDS -----
	If(NoSound) then Exit();
	
	Offset := 0;
	For idx:=0 to (WALL_SFX-1) do begin
		RegisterSound('sfx/wall' + IntToStr(idx) + '.ogg', @Sfx[offset]);
		offset += 1;
	end;
	For idx:=0 to (METAL_SFX-1) do begin
		RegisterSound('sfx/metal' + IntToStr(idx) + '.ogg', @Sfx[offset]);
		offset += 1;
	end;
	For idx:=0 to (DIE_SFX-1) do begin
		RegisterSound('sfx/die' + IntToStr(idx) + '.ogg', @Sfx[offset]);
		offset += 1;
	end;
	For idx:=0 to (SHOT_SFX-1) do begin
		RegisterSound('sfx/shot' + IntToStr(idx) + '.ogg', @Sfx[offset]);
		offset += 1;
	end;
	For idx:=0 to (HIT_SFX-1) do begin
		RegisterSound('sfx/hit' + IntToStr(idx) + '.ogg', @Sfx[offset]);
		offset += 1;
	end;
	For idx:=0 to (EXTRA_SFX-1) do begin
		RegisterSound('sfx/extra' + IntToStr(idx) + '.ogg', @Sfx[offset]);
		offset += 1;
	end
End;

Function LoadAssets(Const UpdateCallback: TUpdateProc = NIL):TLoadingResult;
Var
	idx: sInt;
	FullPath: AnsiString;
	ExitRequested: Boolean;
	
	FontImage: PImage;
Begin
	For idx := 0 to (AssetCount-1) do begin
		If(AssetArr[idx].Ptr^ <> NIL) then Continue;
		
		FullPath := {$IFNDEF ANDROID} DataPath + {$ENDIF} AssetArr[idx].Path;
		Case(AssetArr[idx].Kind) of
			ASSET_FONT: begin
				FontImage := LoadImage(FullPath, @COLOUR_BLACK);
				If(FontImage = NIL) then begin
					Result.ErrStr := Images.ImageError()
				end else begin
					AssetArr[idx].Font^ := FontFromImage(FontImage, AssetArr[idx].FontStartChar, AssetArr[idx].FontW, AssetArr[idx].FontH);
					If(AssetArr[idx].Font^ = NIL) then begin
						Result.ErrStr := 'Failed to allocate memory';
						FreeImage(FontImage)
					end
				end
			end;
			
			ASSET_IMAGE: begin
				AssetArr[idx].Image^ := LoadImage(FullPath, AssetArr[idx].ImageTransCol);
				If(AssetArr[idx].Image^ = NIL) then Result.ErrStr := Images.ImageError() // TODO: Improve this
			end;
			ASSET_ROOM: begin
				AssetArr[idx].Room^ := LoadRoom(AssetArr[idx].RoomX, AssetArr[idx].RoomY, FullPath);
				If(AssetArr[idx].Room^ = NIL) then Result.ErrStr := 'Unknown' // TODO: Improve this
			end;
			ASSET_SOUND: begin
				AssetArr[idx].Sound^ := Mix_LoadWAV(PChar(FullPath));
				If(AssetArr[idx].Sound^ = NIL) then Result.ErrStr := Mix_GetError()
			end;
		end;
		
		If(AssetArr[idx].Ptr^ = NIL) then begin
			Result.Status := ALS_FAILED;
			Result.FileName := {$IFDEF LD25_ASSETS_SYSTEMWIDE} FullPath {$ELSE} AssetArr[idx].Path {$ENDIF};
			Exit()
		end;
		
		UpdateCallback(AssetArr[idx].Path, (idx+1) / AssetCount);
		
		// Check for user interrupt
		ExitRequested := False;
		While(SDL_PollEvent(@Ev) > 0) do Case(Ev.Type_) of
			SDL_QuitEv: ExitRequested := True;
			SDL_KeyDown: If((Ev.Key.Keysym.Sym = SDLK_Escape) or (Ev.Key.Keysym.Sym = SDLK_AC_BACK)) then ExitRequested := True;
			SDL_WindowEvent: If(Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then HandleWindowResizedEvent(@Ev);
		end;
		
		If(ExitRequested) then begin
			Result.Status := ALS_INTERRUPTED;
			Result.ErrStr := 'Interrupted by user';
			Exit()
		end
	end;

	Result.Status := ALS_OK	
End;

Procedure LoadAndSetWindowIcon();
Const
	ICON_FILE = 'gfx/icon.png';
Begin
	If(IconSurf = NIL) then begin
		IconSurf:=IMG_Load(PChar({$IFNDEF ANDROID} DataPath + {$ENDIF} ICON_FILE));
		
		If (IconSurf = NIL) then begin
			{$IFDEF LD25_ASSETS_STANDALONE}
			SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to load file: ' + ICON_FILE, []);
			{$ELSE}
			SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to load file: %s%s', [PChar(DataPath), PChar(ICON_FILE)]);
			{$ENDIF}
			Exit()
		end
	end;
	
	SDL_SetWindowIcon(Window, IconSurf)
End;

Procedure FreeAssets();
Var
	idx: sInt;
Begin
	// Stop all playing sounds, because if we free a sample (PMix_Chunk)
	// that's still being played... well, uh... I didn't check that, actually,
	// but it could possibly lead to segfault. Better safe than sorry.
	Mix_HaltChannel(-1);
	
	For idx := 0 to (AssetCount-1) do begin
		If(AssetArr[idx].Ptr^ = NIL) then Continue;
		
		Case(AssetArr[idx].Kind) of
			ASSET_FONT: begin
				FreeImage(AssetArr[idx].Font^^.Image);
				FreeFont(AssetArr[idx].Font^);
			end;
			
			ASSET_IMAGE: FreeImage(AssetArr[idx].Image^);
			ASSET_ROOM:  Dispose(AssetArr[idx].Room^, Destroy());
			ASSET_SOUND: Mix_FreeChunk(AssetArr[idx].Sound^);
		end;
		
		AssetArr[idx].Ptr^ := NIL
	end;
	
	If(IconSurf <> NIL) then SDL_FreeSurface(IconSurf);
	IconSurf := NIL
End;

end.
