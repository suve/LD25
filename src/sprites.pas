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
Unit Sprites;

{$INCLUDE defines.inc}

Interface

Uses
	SDL2;

Type
    TFacing = (
		FACE_RIGHT,
		FACE_LEFT
	);

Type
	PSprite = ^TSprite;
	TSprite = object
		Private
			FirstFrame: TSDL_Rect;
			HasLeftFrames: Boolean;
		Public
			Function GetFrame(FrameNo: uInt; Facing: TFacing): TSDL_Rect;
			Procedure GetFrameSize(Out W, H: uInt);
	end;

Const
	HeroSprite: TSprite = (
		FirstFrame: (X: 0; Y: 0; W: 16; H: 16);
		HasLeftFrames: True
	);
	HeroBulletSprite: TSprite = (
		FirstFrame: (X: 32; Y: 16; W: 5; H: 3);
		HasLeftFrames: False
	);
	DroneSprite: TSprite = (
		FirstFrame: (X: 0; Y: 16; W: 16; H: 16);
		HasLeftFrames: False
	);
	SpitterSprite: TSprite = (	
		FirstFrame: (X: 0; Y: 32; W: 16; H: 16);
		HasLeftFrames: True
	);
	SpitterBulletSprite: TSprite = (	
		FirstFrame: (X: 32; Y: 48; W: 3; H: 3);
		HasLeftFrames: False
	);
	BallSprite: TSprite = (
		FirstFrame: (X: 0; Y: 48; W: 16; H: 16);
		HasLeftFrames: False
	);
	BasherSprite: TSprite = (
		FirstFrame: (X: 0; Y: 64; W: 16; H: 16);
		HasLeftFrames: False
	);
	SpammerSprite: TSprite = (
		FirstFrame: (X: 0; Y: 80; W: 16; H: 16);
		HasLeftFrames: False
	);
	GeneratorSprite: TSprite = (
		FirstFrame: (X: 0; Y: 96; W: 16; H: 16);
		HasLeftFrames: False
	);
	GeneratorSmallBulletSprite: TSprite = (	
		FirstFrame: (X: 32; Y: 96; W: 3; H: 3);
		HasLeftFrames: False
	);
	GeneratorBigBulletSprite: TSprite = (	
		FirstFrame: (X: 48; Y: 96; W: 5; H: 5);
		HasLeftFrames: False
	);
	TurretSprite: TSprite = (
		FirstFrame: (X: 0; Y: 112; W: 16; H: 16);
		HasLeftFrames: False
	);

Implementation

Const
	LEFTFRAMES_OFFSET = 2;

Function TSprite.GetFrame(FrameNo: uInt; Facing: TFacing): TSDL_Rect;
Var
	Offset: uInt;
Begin	
	Offset := FrameNo;
	If (Self.HasLeftFrames) and (Facing = FACE_LEFT) then Offset += LEFTFRAMES_OFFSET;

	Result := Self.FirstFrame;
	Result.X += (Offset * Result.W)
End;

Procedure TSprite.GetFrameSize(Out W, H: uInt);
Begin
	W := Self.FirstFrame.W;
	H := Self.FirstFrame.H
End;

End.
