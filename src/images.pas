(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2022 suve (a.k.a. Artur Frenszek-Iwicki)
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
Unit Images;

{$INCLUDE defines.inc}

Interface
Uses
	SDL2;

Type
	PImage = ^TImage;
	TImage = record
		Tex: PSDL_Texture;
		W, H: uInt
	end;

Function LoadImage(Const Path: AnsiString; Const TransparentColour: PSDL_Colour):PImage;
Procedure FreeImage(Image: PImage);

Procedure DrawImage(Const Image: PImage; Const Src, Dst: PSDL_Rect; Const Colour: PSDL_Colour);

Function ImageError():AnsiString;


Implementation
Uses
	SDL2_Image,
	Rendering;

Var
	ErrorCode: sInt = 0;

Const
	ErrorNames: Array[0..4] of AnsiString = (
		'No error',
		'Failed to read file',
		'Failed to convert surface',
		'Failed to create texture from surface',
		'Failed to allocate image'
	);
	
	TRANSPARENT: QWord = $00000000;
// static const SDL_Colour DEFAULT_COLORKEY = {0x00, 0xFF, 0xFF, 0xFF}; // rgba

Function AllocateImage():PImage;
Var
	Image: PImage;
Begin
	New(Image);
	
	If(Image = NIL) then
		ErrorCode := 4
	else
		ErrorCode := 0;
	
	Exit(Image)
End;

Procedure FreeImage(Image: PImage);
Begin
	If(Image = NIL) then Exit();
	
	If(Image^.Tex <> NIL) then begin
		SDL_DestroyTexture(Image^.Tex);
		Image^.Tex := NIL
	end;
	
	Dispose(Image)
End;

Procedure ColorkeyToTransparent(Const Surface: PSDL_Surface; Const TransparentColour: PSDL_Colour);
Type
	uInt32 = LongWord;
Var
	Offset: QWord;
	Colorkey: uInt32;
	Pixel: ^uInt32;
	X, Y: sInt;
Begin
	Colorkey := (TransparentColour^.a * $1000000) + (TransparentColour^.r * $10000) + (TransparentColour^.g * $100) + (TransparentColour^.b);
	
	SDL_LockSurface(Surface);
	For Y:=0 to Surface^.h-1 do begin
		For X:=0 to Surface^.w - 1 do begin
			Offset := (Y * Surface^.pitch) + (X * Surface^.Format^.BytesPerPixel);
			
			Pixel := PLongWord(@( PByte(Surface^.pixels)[Offset] ));
			If(Pixel^ = Colorkey) then Pixel^ := TRANSPARENT
		end
	end;
	
	SDL_UnlockSurface(Surface);
End;

Function ImageFromSurface(Const Surface: PSDL_Surface; Const TransparentColour: PSDL_Colour):PImage;
Var
	W, H: uInt;
	Tex: PSDL_Texture;
	Img: PImage;
Begin
	W := Surface^.w;
	H := Surface^.h;
	
	if(TransparentColour <> NIL) then ColorkeyToTransparent(Surface, TransparentColour);
	
	Tex := SDL_CreateTextureFromSurface(Renderer, Surface);
	If(Tex = NIL) then begin
		ErrorCode := 3;
		Exit(NIL)
	end;
	
	Img := AllocateImage();
	If(Img = NIL) then begin
		SDL_DestroyTexture(Tex);
		ErrorCode := 4;
		Exit(NIL)
	end;
	
	SDL_SetTextureBlendMode(Tex, SDL_BLENDMODE_BLEND);
	Img^.Tex := Tex;
	Img^.W := W;
	Img^.H := H;
	
	ErrorCode := 0;
	Exit(Img)
End;

Function LoadImage(Const Path: AnsiString; Const TransparentColour: PSDL_Colour):PImage;
Var
	Original, Converted: PSDL_Surface;
	Image: PImage;
Begin
	Original := IMG_Load(PChar(Path));
	if(Original = NIL) then begin
		ErrorCode := 1;
		Exit(NIL)
	end;
	
	Converted := SDL_ConvertSurfaceFormat(Original, SDL_PIXELFORMAT_ARGB8888, 0);
	SDL_FreeSurface(Original);
	
	if(Converted = NIL) then begin
		ErrorCode := 2;
		Exit(NIL)
	end;
	
	Image := ImageFromSurface(Converted, TransparentColour);
	SDL_FreeSurface(Converted);
	Exit(Image)
End;

Procedure DrawImage(Const Image: PImage; Const Src, Dst: PSDL_Rect; Const Colour: PSDL_Colour);
Begin
	If(Colour <> NIL) then SDL_SetTextureColorMod(Image^.Tex, Colour^.R, Colour^.G, Colour^.B);
	SDL_RenderCopy(Renderer, Image^.Tex, Src, Dst)
End;

Function ImageError():AnsiString;
Begin
	Exit(ErrorNames[ErrorCode])
End;


End.
