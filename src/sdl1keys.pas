(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2018 Artur Iwicki
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
Unit SDL1Keys;

{$INCLUDE defines.inc}

Interface
	uses SDL2;

Type
	TSDL1Key = record
		SDL1: LongWord;
		SDL2: TSDL_Keycode;
	end;

Const
	SDL1KEYCOUNT = 134;
	SDL1KEY: Array[0 .. SDL1KEYCOUNT-1] of TSDL1Key = (
		(SDL1: 8; SDL2: SDLK_BACKSPACE),
		(SDL1: 9; SDL2: SDLK_TAB),
		(SDL1: 12; SDL2: SDLK_CLEAR),
		(SDL1: 13; SDL2: SDLK_RETURN),
		(SDL1: 19; SDL2: SDLK_PAUSE),
		(SDL1: 27; SDL2: SDLK_ESCAPE),
		(SDL1: 32; SDL2: SDLK_SPACE),
		(SDL1: 33; SDL2: SDLK_EXCLAIM),
		(SDL1: 34; SDL2: SDLK_QUOTEDBL),
		(SDL1: 35; SDL2: SDLK_HASH),
		(SDL1: 36; SDL2: SDLK_DOLLAR),
		(SDL1: 38; SDL2: SDLK_AMPERSAND),
		(SDL1: 39; SDL2: SDLK_QUOTE),
		(SDL1: 40; SDL2: SDLK_LEFTPAREN),
		(SDL1: 41; SDL2: SDLK_RIGHTPAREN),
		(SDL1: 42; SDL2: SDLK_ASTERISK),
		(SDL1: 43; SDL2: SDLK_PLUS),
		(SDL1: 44; SDL2: SDLK_COMMA),
		(SDL1: 45; SDL2: SDLK_MINUS),
		(SDL1: 46; SDL2: SDLK_PERIOD),
		(SDL1: 47; SDL2: SDLK_SLASH),
		(SDL1: 48; SDL2: SDLK_0),
		(SDL1: 49; SDL2: SDLK_1),
		(SDL1: 50; SDL2: SDLK_2),
		(SDL1: 51; SDL2: SDLK_3),
		(SDL1: 52; SDL2: SDLK_4),
		(SDL1: 53; SDL2: SDLK_5),
		(SDL1: 54; SDL2: SDLK_6),
		(SDL1: 55; SDL2: SDLK_7),
		(SDL1: 56; SDL2: SDLK_8),
		(SDL1: 57; SDL2: SDLK_9),
		(SDL1: 58; SDL2: SDLK_COLON),
		(SDL1: 59; SDL2: SDLK_SEMICOLON),
		(SDL1: 60; SDL2: SDLK_LESS),
		(SDL1: 61; SDL2: SDLK_EQUALS),
		(SDL1: 62; SDL2: SDLK_GREATER),
		(SDL1: 63; SDL2: SDLK_QUESTION),
		(SDL1: 64; SDL2: SDLK_AT),
		(SDL1: 91; SDL2: SDLK_LEFTBRACKET),
		(SDL1: 92; SDL2: SDLK_BACKSLASH),
		(SDL1: 93; SDL2: SDLK_RIGHTBRACKET),
		(SDL1: 94; SDL2: SDLK_CARET),
		(SDL1: 95; SDL2: SDLK_UNDERSCORE),
		(SDL1: 96; SDL2: SDLK_BACKQUOTE),
		(SDL1: 97; SDL2: SDLK_a),
		(SDL1: 98; SDL2: SDLK_b),
		(SDL1: 99; SDL2: SDLK_c),
		(SDL1: 100; SDL2: SDLK_d),
		(SDL1: 101; SDL2: SDLK_e),
		(SDL1: 102; SDL2: SDLK_f),
		(SDL1: 103; SDL2: SDLK_g),
		(SDL1: 104; SDL2: SDLK_h),
		(SDL1: 105; SDL2: SDLK_i),
		(SDL1: 106; SDL2: SDLK_j),
		(SDL1: 107; SDL2: SDLK_k),
		(SDL1: 108; SDL2: SDLK_l),
		(SDL1: 109; SDL2: SDLK_m),
		(SDL1: 110; SDL2: SDLK_n),
		(SDL1: 111; SDL2: SDLK_o),
		(SDL1: 112; SDL2: SDLK_p),
		(SDL1: 113; SDL2: SDLK_q),
		(SDL1: 114; SDL2: SDLK_r),
		(SDL1: 115; SDL2: SDLK_s),
		(SDL1: 116; SDL2: SDLK_t),
		(SDL1: 117; SDL2: SDLK_u),
		(SDL1: 118; SDL2: SDLK_v),
		(SDL1: 119; SDL2: SDLK_w),
		(SDL1: 120; SDL2: SDLK_x),
		(SDL1: 121; SDL2: SDLK_y),
		(SDL1: 122; SDL2: SDLK_z),
		(SDL1: 127; SDL2: SDLK_DELETE),
		(SDL1: 256; SDL2: SDLK_KP_0),
		(SDL1: 257; SDL2: SDLK_KP_1),
		(SDL1: 258; SDL2: SDLK_KP_2),
		(SDL1: 259; SDL2: SDLK_KP_3),
		(SDL1: 260; SDL2: SDLK_KP_4),
		(SDL1: 261; SDL2: SDLK_KP_5),
		(SDL1: 262; SDL2: SDLK_KP_6),
		(SDL1: 263; SDL2: SDLK_KP_7),
		(SDL1: 264; SDL2: SDLK_KP_8),
		(SDL1: 265; SDL2: SDLK_KP_9),
		(SDL1: 266; SDL2: SDLK_KP_PERIOD),
		(SDL1: 267; SDL2: SDLK_KP_DIVIDE),
		(SDL1: 268; SDL2: SDLK_KP_MULTIPLY),
		(SDL1: 269; SDL2: SDLK_KP_MINUS),
		(SDL1: 270; SDL2: SDLK_KP_PLUS),
		(SDL1: 271; SDL2: SDLK_KP_ENTER),
		(SDL1: 272; SDL2: SDLK_KP_EQUALS),
		(SDL1: 273; SDL2: SDLK_UP),
		(SDL1: 274; SDL2: SDLK_DOWN),
		(SDL1: 275; SDL2: SDLK_RIGHT),
		(SDL1: 276; SDL2: SDLK_LEFT),
		(SDL1: 277; SDL2: SDLK_INSERT),
		(SDL1: 278; SDL2: SDLK_HOME),
		(SDL1: 279; SDL2: SDLK_END),
		(SDL1: 280; SDL2: SDLK_PAGEUP),
		(SDL1: 281; SDL2: SDLK_PAGEDOWN),
		(SDL1: 282; SDL2: SDLK_F1),
		(SDL1: 283; SDL2: SDLK_F2),
		(SDL1: 284; SDL2: SDLK_F3),
		(SDL1: 285; SDL2: SDLK_F4),
		(SDL1: 286; SDL2: SDLK_F5),
		(SDL1: 287; SDL2: SDLK_F6),
		(SDL1: 288; SDL2: SDLK_F7),
		(SDL1: 289; SDL2: SDLK_F8),
		(SDL1: 290; SDL2: SDLK_F9),
		(SDL1: 291; SDL2: SDLK_F10),
		(SDL1: 292; SDL2: SDLK_F11),
		(SDL1: 293; SDL2: SDLK_F12),
		(SDL1: 294; SDL2: SDLK_F13),
		(SDL1: 295; SDL2: SDLK_F14),
		(SDL1: 296; SDL2: SDLK_F15),
		(SDL1: 300; SDL2: SDLK_NUMLOCKCLEAR),
		(SDL1: 301; SDL2: SDLK_CAPSLOCK),
		(SDL1: 302; SDL2: SDLK_SCROLLLOCK),
		(SDL1: 303; SDL2: SDLK_RSHIFT),
		(SDL1: 304; SDL2: SDLK_LSHIFT),
		(SDL1: 305; SDL2: SDLK_RCTRL),
		(SDL1: 306; SDL2: SDLK_LCTRL),
		(SDL1: 307; SDL2: SDLK_RALT),
		(SDL1: 308; SDL2: SDLK_LALT),
		(SDL1: 309; SDL2: SDLK_RGUI),
		(SDL1: 310; SDL2: SDLK_LGUI),
		(SDL1: 311; SDL2: SDLK_LGUI),  // Left "Windows" key
		(SDL1: 312; SDL2: SDLK_RGUI),  // Right "Windows" key
		(SDL1: 313; SDL2: SDLK_MODE),    // "Alt Gr" key
		(SDL1: 314; SDL2: SDLK_APPLICATION), // Multi-key compose key
		(SDL1: 315; SDL2: SDLK_HELP),
		(SDL1: 316; SDL2: SDLK_PRINTSCREEN),
		(SDL1: 317; SDL2: SDLK_SYSREQ),
		(SDL1: 318; SDL2: SDLK_PAUSE),
		(SDL1: 319; SDL2: SDLK_MENU),
		(SDL1: 320; SDL2: SDLK_POWER), // Power Macintosh power key */
		// (SDL1: 321; SDL2: SDLK_EURO),  // Some european keyboards */
		(SDL1: 322; SDL2: SDLK_UNDO)  // Atari keyboard has Undo */
	);

Function TranslateSDL1KeyToSDL2Keycode(Const OldKey: sInt):TSDL_Keycode;


Implementation
	Uses Math;

Function BinarySearch(Const Min, Max, Search: sInt):TSDL_Keycode;
Var
	Idx: sInt;
Begin
	If(Min = Max) then begin
		If(Search = SDL1KEY[Min].SDL1) then
			Result := SDL1KEY[Min].SDL2
		else
			Result := -1
	end else begin
		Idx := (Min + Max) div 2;
		Case CompareValue(Search, SDL1KEY[Idx].SDL1) of
			0: Result := SDL1KEY[Idx].SDL2;
			
			-1: Result := BinarySearch(Min, Idx-1, Search);
			
			+1: Result := BinarySearch(Idx+1, Max, Search);
		end
	end
End;

Function TranslateSDL1KeyToSDL2Keycode(Const OldKey: sInt):TSDL_Keycode;
Begin
	Result := BinarySearch(0, SDL1KEYCOUNT-1, OldKey)
End;

End.
