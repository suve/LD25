(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2024 suve (a.k.a. Artur Frenszek Iwicki)
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
Unit game; {$INCLUDE defines.inc}


Interface

Procedure DamageMob(Const mID:uInt; Const Power:Double);
Procedure DamagePlayer(Const Power:Double);

Function PlayGame():Boolean;


Implementation
Uses
	SDL2,
	{$IFDEF LD25_MOBILE} ctypes, TouchControls, {$ENDIF}
	Assets, Colours, ConfigFiles, Entities, FloatingText, Fonts, Images,
	MathUtils, Rendering, Rooms, Shared, Sprites, Stats;

Type
	TRoomChange = (
		RCHANGE_NONE,
		RCHANGE_UP,
		RCHANGE_RIGHT,
		RCHANGE_DOWN,
		RCHANGE_LEFT
	);

Const
	AnimFPS = 12; AnimTime = 1000 div AnimFPS;

	PAUSETXT_W = (64 - 35 - 2); 
	PAUSETXT_H = (32 - 7 - 2);

Var
	Frames, FrameTime, AniFra: uInt;
	FrameStr: ShortString;
	PauseTxt: TSDL_Point;
	Paused, WantToQuit: Boolean;
	RoomChange: TRoomChange;

{$IFDEF LD25_DEBUG}
	Type
		TFreezeMode = (
			FREEZE_NONE,
			FREEZE_MOBS,
			FREEZE_ALL
		);
	Var
		CheatInvulnerability, CheatNoClip, CheatHitboxes, CheatHideUI: Boolean;
		CheatFreeze: TFreezeMode;
{$ENDIF}

Procedure SetAllowScreensaver(Allow: Boolean);
Begin
	If(Allow) then
		SDL_SetHint(SDL_HINT_VIDEO_ALLOW_SCREENSAVER, '1')
	else
		SDL_SetHint(SDL_HINT_VIDEO_ALLOW_SCREENSAVER, '0')
end;

{$IFDEF LD25_DEBUG}
Procedure TriggerInvulnerabilityCheat(); Inline;
Begin
	If(CheatInvulnerability) then begin
		CheatInvulnerability := False;
		Exit
	end;

	// Prevent enabling invulnerability if the hero is already dead
	If(DeadTime > 0) then Exit;

	Hero^.HP := Hero^.MaxHP;
	CheatInvulnerability := True
End;

Procedure TriggerFreezeCheat(); Inline;
Begin
	CheatFreeze := TFreezeMode((Ord(CheatFreeze) + 1) mod (Ord(High(TFreezeMode)) + 1))
End;
{$ENDIF}

Procedure GatherInput();
Var
	NewPaused: Boolean;
Begin
	NewPaused := Paused;
	While (SDL_PollEvent(@Ev)>0) do begin
		If (Ev.Type_ = SDL_QuitEv) then begin
			Shutdown:=True; WantToQuit:=True 
		end else
		If (Ev.Type_ = SDL_KeyDown) then begin
			If (Ev.Key.Keysym.Sym = SDLK_Escape) then WantToQuit:=True else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_Up]        ) then Key[KEY_UP   ]     :=True else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_RIGHT]     ) then Key[KEY_RIGHT]     :=True else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_DOWN]      ) then Key[KEY_DOWN ]     :=True else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_LEFT]      ) then Key[KEY_LEFT ]     :=True else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_ShootLeft] ) then Key[KEY_ShootLeft] :=True else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_ShootRight]) then Key[KEY_ShootRight]:=True else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_VolDown]) then ChgVol(-1) else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_VolUp])	then ChgVol(+1) else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_Pause])	then NewPaused:=(Not NewPaused) else
			If (Ev.Key.Keysym.Sym = SDLK_AC_BACK) then begin
				If (Paused) then
					NewPaused:=False
				else
					WantToQuit:=True
			end else
			{$IFDEF LD25_DEBUG}
				If (Ev.Key.Keysym.Sym = SDLK_F1) then TriggerInvulnerabilityCheat() else
				If (Ev.Key.Keysym.Sym = SDLK_F2) then TriggerFreezeCheat() else
				If (Ev.Key.Keysym.Sym = SDLK_F3) then CheatNoClip:=(Not CheatNoClip) else
				If (Ev.Key.Keysym.Sym = SDLK_F11) then CheatHitboxes:=(Not CheatHitboxes) else
				If (Ev.Key.Keysym.Sym = SDLK_F12) then CheatHideUI:=(Not CheatHideUI) else
			{$ENDIF}
		end else
		If (Ev.Type_ = SDL_KeyUp) then begin
			If (Ev.Key.Keysym.Sym = KeyBind[Key_Up]        ) then Key[KEY_UP   ]     :=False else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_RIGHT]     ) then Key[KEY_RIGHT]     :=False else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_DOWN]      ) then Key[KEY_DOWN ]     :=False else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_LEFT]      ) then Key[KEY_LEFT ]     :=False else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_ShootLeft] ) then Key[KEY_ShootLeft] :=False else
			If (Ev.Key.Keysym.Sym = KeyBind[Key_ShootRight]) then Key[KEY_ShootRight]:=False else
		end else
		{$IFDEF LD25_MOBILE}
		If (Ev.Type_ = SDL_FingerUp) or (Ev.Type_ = SDL_FingerDown) or (Ev.Type_ = SDL_FingerMotion) then begin
			TouchControls.HandleEvent(@Ev)
		end else
		{$ENDIF}
		If (Ev.Type_ = SDL_WindowEvent) then begin
			If (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then begin
				HandleWindowResizedEvent(@Ev);
				NewPaused:=True
			end else
			If (Ev.Window.Event = SDL_WINDOWEVENT_FOCUS_LOST) then begin
				NewPaused:=True
			end else
			If (Ev.Window.Event = SDL_WINDOWEVENT_CLOSE) then begin
				Shutdown:=True; WantToQuit:=True
			end
		end
	end;

	If(NewPaused <> Paused) then begin
		SetAllowScreensaver(Not Paused);
		Paused := NewPaused
	end
End;

Procedure Animate(Const Ticks:uInt);
Begin
	{$IFDEF LD25_DEBUG}
		If(CheatFreeze = FREEZE_ALL) then AniFra:=0 else
	{$ENDIF}
	AniFra:=(Ticks div AnimTime) mod 2
End;

Procedure CalculateHero(Const Time:uInt);
Var
	C: sInt;
	XDif, YDif, ChkX, ChkY: Double;
Begin
	If (Hero^.HP > 0.0) then begin
		Hero^.Calculate(Time);
		
		XDif:=Hero^.XVel*Time/1000;
		YDif:=Hero^.YVel*Time/1000;
		
		{$IFDEF LD25_DEBUG}
		If (Not CheatNoClip) then begin
		{$ENDIF}
			If (XDif<>0) then begin
				If (XDif<0) then ChkX:=Hero^.X else ChkX:=Hero^.X+Hero^.W-1;
				
				If (Not Room^.Collides(ChkX+XDif,Hero^.Y)) and (Not Room^.Collides(ChkX+XDif,Hero^.Y+Hero^.H-1)) then 
					Hero ^.X:=Hero^.X+XDif
			end;
			
			If (YDif<>0) then begin
				If (YDif<0) then ChkY:=Hero^.Y else ChkY:=Hero^.Y+Hero^.H-1;
				
				If (Not Room^.Collides(Hero^.X,ChkY+YDif)) and (Not Room^.Collides(Hero^.X+Hero^.W-1,ChkY+YDif)) then
					Hero^.Y:=Hero^.Y+YDif
			end;
		{$IFDEF LD25_DEBUG}
		end else begin 
			Hero^.X:=Hero^.X+XDif; Hero^.Y:=Hero^.Y+YDif 
		end
		{$ENDIF}
	end else begin
		If (DeadTime > 0) then 
			DeadTime-=Time
		else begin
			ChangeRoom(RespRoom[GameMode].X,RespRoom[GameMode].Y);
			Hero^.mX:=RespPos[GameMode].X; Hero^.mY:=RespPos[GameMode].Y;
			
			Hero^.HP:=Hero^.MaxHP;
			Hero^.FireTimer:=0;
			Hero^.InvTimer:=0;
			
			For C:=0 to 7 do
				If (ColState[C]=STATE_PICKED) then
					ColState[C]:=STATE_NONE;
			Carried:=0;

			SaveCurrentGame('upon death')
		end 
	end
End;

Procedure CalculateCrystalPickup();
Var
	C: sInt;
Begin
	If (Not Crystal.IsSet) then Exit;
	If (Not Overlap(Hero^.X,Hero^.Y,Hero^.W,Hero^.H,Crystal.mX*TILE_W,Crystal.mY*TILE_H,TILE_W,TILE_H)) then Exit;
	
	If (Crystal.Col<>WOMAN) then begin
		ColState[Crystal.Col]:=STATE_PICKED; 
		Crystal.IsSet:=False;
		
		PlaySfx(SFX_EXTRA);
		Carried+=1
	end else If (Carried>0) then begin
		PlaySfx(SFX_EXTRA+1);
		Given+=Carried; Carried:=0;
		Hero^.Level := Given;
		
		For C:=0 to 7 do begin
			If (ColState[C]=STATE_PICKED) then begin
				CentralPalette[C]:=PaletteColour[C];
				PaletteColour[C]:=GreyColour;
				ColState[C]:=STATE_GIVEN
			end
		end;
		
		// If this is the last crystal, switch the quit-flag so we exit to outro after this game cycle.
		If (Given >= 8) then
			WantToQuit:=True 
		else
			SaveCurrentGame('upon progress')
	end;
End;

Procedure CalculateRoomChange();
Begin
	If (Hero^.iX < 0) then begin
		If (Room^.Tile[0][Hero^.mY]=TILE_ZONE) or (Room^.Tile[0][Hero^.mY]=TILE_ROOM) then
			RoomChange := RCHANGE_LEFT
	end else
	If (Hero^.iY < 0) then begin
		If (Room^.Tile[Hero^.mX][0]=TILE_ZONE) or (Room^.Tile[Hero^.mX][0]=TILE_ROOM) then
			RoomChange := RCHANGE_UP
	end else
	If (Hero^.iX > ((ROOM_W-1)*TILE_W)) then begin
		If (Room^.Tile[ROOM_W-1][Hero^.mY]=TILE_ZONE) or (Room^.Tile[ROOM_W-1][Hero^.mY]=TILE_ROOM) then
			RoomChange := RCHANGE_RIGHT
	end else
	If (Hero^.iY > ((ROOM_H-1)*TILE_H)) then begin
		If (Room^.Tile[Hero^.mX][ROOM_H-1]=TILE_ZONE) or (Room^.Tile[Hero^.mX][ROOM_H-1]=TILE_ROOM) then
			RoomChange := RCHANGE_DOWN
	end
End;

Procedure CalculateMonsters(Const Time:uInt);
Var
	M: sInt;
	E: PEntity;
	XDif, YDif, ChkX, ChkY: Double;
Begin
	If(Length(Mob)=0) then Exit;

	For M:=Low(Mob) to High(Mob) do begin
		If (Mob[M]=NIL) then Continue;

		E:=Mob[M];
		{$IFDEF LD25_DEBUG}
		If(CheatFreeze = FREEZE_NONE) then begin
		{$ENDIF}
			E^.Calculate(Time);

			XDif:=E^.XVel*Time/1000;
			YDif:=E^.YVel*Time/1000;
			If (XDif<>0) then begin
				If (XDif<0) then begin
					E^.Face:=FACE_LEFT;  ChkX:=E^.X
				end else begin
					E^.Face:=FACE_RIGHT; ChkX:=E^.X+E^.W-1
				end;

				If (Not Room^.CollidesOrOutside(ChkX+XDif,E^.Y)) and (Not Room^.CollidesOrOutside(ChkX+XDif,E^.Y+E^.H-1)) then begin
					E^.X:=E^.X+XDif; E^.XCol:=False
				end else
					E^.XCol:=True;
			end else
				E^.XCol:=False;

			If (YDif<>0) then begin
				If (YDif<0) then ChkY:=E^.Y else ChkY:=E^.Y+E^.H-1;

				If (Not Room^.CollidesOrOutside(E^.X,ChkY+YDif)) and (Not Room^.CollidesOrOutside(E^.X+E^.W-1,ChkY+YDif)) then begin
					E^.Y:=E^.Y+YDif; E^.YCol:=False
				end else
					E^.YCol:=True
			end else
				E^.YCol:=False;
		{$IFDEF LD25_DEBUG}
		end;
		{$ENDIF}

		If (Hero^.HP > 0) and (Hero^.InvTimer <= 0) and (Overlap(Hero,E)) then begin 
			DamageMob(M,9.5); DamagePlayer(9.5) 
		end
	end
End;

Procedure CalculateBulletMovement(Const Bullet:PBullet; Const Time: uInt);
Var
	XDif, YDif, ChkX, ChkY: Double;
Begin
	XDif:=Bullet^.XVel*Time/1000; YDif:=Bullet^.YVel*Time/1000;
	If (XDif<>0) then begin
		If (XDif<0) then ChkX:=Bullet^.X else ChkX:=Bullet^.X+Bullet^.W-1;
		
		If (Room^.CollidesOrOutside(ChkX+XDif,Bullet^.Y)) then begin
			Room^.HitSfx(ChkX+XDif,Bullet^.Y); Bullet^.HP:=-10 
		end else
		If (Room^.CollidesOrOutside(ChkX+XDif,Bullet^.Y+Bullet^.H-1)) then begin 
			Room^.HitSfx(ChkX+XDif,Bullet^.Y+Bullet^.H-1); Bullet^.HP:=-10
		end else
			Bullet^.X:=Bullet^.X+XDif
	end;
		
	If (YDif<>0) then begin
		If (YDif<0) then ChkY:=Bullet^.Y else ChkY:=Bullet^.Y+Bullet^.H-1;
		
		If (Room^.CollidesOrOutside(Bullet^.X,ChkY+YDif)) then begin 
			Room^.HitSfx(Bullet^.X,ChkY+YDif); Bullet^.HP:=-10 
		end else
		If (Room^.CollidesOrOutside(Bullet^.X+Bullet^.W-1,ChkY+YDif)) then begin 
			Room^.HitSfx(Bullet^.X+Bullet^.W-1,ChkY+YDif); Bullet^.HP:=-10
		end else
			Bullet^.Y:=Bullet^.Y+YDif
	end;
End;

Procedure CalculatePlayerBullets(Const Time:uInt);
Var
	B, M: sInt;
Begin
	If (Length(PBul)=0) then Exit;
	
	For B:=Low(PBul) to High(PBul) do begin
		If (PBul[B]=NIL) then Continue;

		{$IFDEF LD25_DEBUG}
		If(CheatFreeze <> FREEZE_ALL) then begin
		{$ENDIF}
			CalculateBulletMovement(PBul[B], Time);
			If (PBul[B]^.HP <= 0) then begin
				Dispose(PBul[B],Destroy()); PBul[B]:=NIL;
				Continue
			end;
		{$IFDEF LD25_DEBUG}
		end;
		{$ENDIF}

		If (Length(Mob)>0) then M:=Low(Mob) else M:=High(M);
		While (M<=High(Mob)) do begin
			If (Mob[M]=NIL) then begin 
				M+=1; Continue
			end;
			
			If (Overlap(PBul[B],Mob[M])) then begin
				Stats.ShotsHit.Modify(+1);
				DamageMob(M,PBul[B]^.Power);
				Dispose(PBul[B],Destroy()); PBul[B]:=NIL;
				M:=High(Mob)*2
			end else 
				M+=1
		end
	end
End;

Procedure CalculateEnemyBullets(Const Time:uInt);
Var
	B: sInt;
Begin
	If (Length(EBul)=0) then Exit;
	
	For B:=Low(EBul) to High(EBul) do begin
		If (EBul[B]=NIL) then Continue;

		{$IFDEF LD25_DEBUG}
		If(CheatFreeze <> FREEZE_ALL) then begin
		{$ENDIF}
			CalculateBulletMovement(EBul[B], Time);
			If (EBul[B]^.HP <= 0) then begin
				Dispose(EBul[B],Destroy()); EBul[B]:=NIL;
				Continue
			end;
		{$IFDEF LD25_DEBUG}
		end;
		{$ENDIF}

		If (Hero^.HP > 0) and (Hero^.InvTimer <= 0) and (Overlap(EBul[B],Hero)) then begin 
			DamagePlayer(EBul[B]^.Power);
			Dispose(EBul[B],Destroy()); EBul[B]:=NIL
		end;
	end;
End;

Procedure CalculateGibs(Const Time:uInt);
Var
	G: sInt;
	XDif, YDif, ChkX, ChkY: Double;
Begin
	If (Length(Gib)=0) then Exit;
	{$IFDEF LD25_DEBUG} If(CheatFreeze = FREEZE_ALL) then Exit; {$ENDIF}
	
	For G:=Low(Gib) to High(Gib) do begin
		If (Gib[G]=NIL) then Continue;
		
		XDif:=Gib[G]^.XVel*Time/1000; 
		YDif:=Gib[G]^.YVel*Time/1000;
		
		If (XDif<>0) then begin
			If (XDif<0) then ChkX:=Gib[G]^.X else ChkX:=Gib[G]^.X+Gib[G]^.W-1;
			
			If (Room^.CollidesOrOutside(ChkX+XDif,Gib[G]^.Y)) or (Room^.CollidesOrOutside(ChkX+XDif,Gib[G]^.Y+Gib[G]^.H-1))
				then Gib[G]^.HP:=-10 
				else Gib[G]^.X:=Gib[G]^.X+XDif
		end;
		
		If (YDif<>0) then begin
			If (YDif<0) then ChkY:=Gib[G]^.Y else ChkY:=Gib[G]^.Y+Gib[G]^.H-1;
			
			If (Room^.CollidesOrOutside(Gib[G]^.X,ChkY+YDif)) or (Room^.CollidesOrOutside(Gib[G]^.X+Gib[G]^.W-1,ChkY+YDif))
				then Gib[G]^.HP:=-10 
				else Gib[G]^.Y:=Gib[G]^.Y+YDif
		end;
		
		If (Gib[G]^.HP <= 0) then begin
			Dispose(Gib[G],Destroy()); Gib[G]:=NIL 
		end
	end;
End;

Procedure CalculateGameCycle(Const Time:uInt);
Begin
	CalculateHero(Time);
	CalculateCrystalPickup();
	CalculateRoomChange();
	
	CalculatePlayerBullets(Time);
	CalculateMonsters(Time);
	CalculateEnemyBullets(Time);
	CalculateGibs(Time);

	Stats.TotalTime.Modify(+Time)
End;

Procedure DrawRoom();
Var
	X, Y: sInt;
	Src, Dst: TSDL_Rect;
Begin
	// All tiles have the same size, no need to set this in the loop 
	Src.W:=TILE_W; Src.H:=TILE_H; 
	Dst.W:=TILE_W; Dst.H:=TILE_H;
	
	Src.X:=AniFra*TILE_W;
	For Y:=0 to (ROOM_H-1) do For X:=0 to (ROOM_W-1) do begin
		If (Room^.Tile[X][Y]=TILE_NONE) then Continue;
		Dst.X:=X*TILE_W; Dst.Y:=Y*TILE_H;
		Src.Y:=Ord(Room^.Tile[X][Y])*TILE_H;
		DrawImage(TileGfx,@Src,@Dst,Room^.TCol[X][Y])
	end
End;

Procedure DrawGibs();
Var
	G: sInt;
	Rect: TSDL_Rect;
Begin
	For G:=Low(Gib) to High(Gib) do
		If (Gib[G]<>NIL) then begin
			Rect.X := Gib[G]^.iX;
			Rect.Y := Gib[G]^.iY;
			Rect.W := Gib[G]^.Rect.W;
			Rect.H := Gib[G]^.Rect.H;

			{$IFDEF LD25_DEBUG}
			If(CheatHitboxes) then DrawRectOutline(@Rect, @YellowColour);
			{$ENDIF}
			DrawImage(EntityGfx, @Gib[G]^.Rect, @Rect, Gib[G]^.Col)
		end
End;

Procedure SetEntityDrawRects(Const E: PEntity; Const Sprite: PSprite; Out Src, Dst: TSDL_Rect);
Begin
	Dst.X := E^.iX;
	Dst.Y := E^.iY;
	Dst.W := E^.W;
	Dst.H := E^.H;

	Src := Sprite^.GetFrame(AniFra, E^.Face)
End;

Procedure DrawEntity(
	Const E:PEntity;
	Const Sprite: PSprite
	{$IFDEF LD25_DEBUG}; Const OutlineColour: PSDL_Colour {$ENDIF}
);
Var
	Src, Dst: TSDL_Rect;
Begin
	SetEntityDrawRects(E, Sprite, Src, Dst);
	{$IFDEF LD25_DEBUG}
	If(CheatHitboxes) then DrawRectOutline(@Dst, OutlineColour);
	{$ENDIF}
	DrawImage(EntityGfx, @Src, @Dst, E^.Col)
End;

Procedure DrawMonsters();
Var
	M: sInt;
Begin
	For M:=Low(Mob) to High(Mob) do
		If (Mob[M]<>NIL) then
			DrawEntity(Mob[M], Mob[M]^.Sprite {$IFDEF LD25_DEBUG}, @RedColour {$ENDIF})
End;

Procedure DrawPlayerBullets();
Var
	B: sInt;
Begin
	For B:=Low(PBul) to High(PBul) do
		If (PBul[B]<>NIL) then
			DrawEntity(PBul[B], PBul[B]^.Sprite {$IFDEF LD25_DEBUG}, @LimeColour {$ENDIF})
End;

Procedure DrawEnemyBullets();
Var
	B: sInt;
Begin
	For B:=Low(EBul) to High(EBul) do
		If (EBul[B]<>NIL) then
			DrawEntity(EBul[B], EBul[B]^.Sprite {$IFDEF LD25_DEBUG}, @RedColour {$ENDIF})
End;

Procedure DrawHero();
Var
	C, X: sInt;
	Src, Dst: TSDL_Rect;
	Col: TSDL_Colour;
Begin
	If (Hero^.HP <= 0.0) then Exit;

	SetEntityDrawRects(Hero, @HeroSprite, Src, Dst);

	{$IFDEF LD25_DEBUG}
	If(CheatHitboxes) then DrawRectOutline(@Dst, @LimeColour);
	{$ENDIF}

	// If hero has taken damage recently, randomly move target position to make a "damage shake" effect
	If (Hero^.InvTimer > 0) then begin
		Dst.X += Random(-1, +1);
		Dst.Y += Random(-1, +1) 
	end;
	
	// If hero is carrying a colour, randomly colourise the bastard
	If (Carried>0) then begin
		If (Random(5)<>0) then 
			Col:=GreyColour 
		else begin
			C:=Random(Carried)+1; X:=-1;
			Repeat 
				X+=1;
				If (ColState[X]=STATE_PICKED) then C-=1
			Until (C = 0);
			Col:=PaletteColour[X]
		end
	end else
		Col:=GreyColour;
	
	DrawImage(EntityGfx, @Src, @Dst, @Col)
End;

Procedure DrawCrystal();
Var
	Src, Dst: TSDL_Rect;
Begin
	If(Not Crystal.IsSet) then Exit;
	
	Src.X := AniFra * TILE_W;
	Src.Y := Crystal.Col * TILE_H;
	Src.W := TILE_W;
	Src.H := TILE_H;
	
	Dst.X := Crystal.mX * TILE_W;
	Dst.Y := Crystal.mY * TILE_H;
	Dst.W := TILE_W;
	Dst.H := TILE_H;
	
	If (Crystal.Col <> WOMAN) then
		DrawImage(ColourGfx, @Src, @Dst, @WhiteColour)
	else
		DrawImage(ColourGfx, @Src, @Dst, @CentralPalette[FrameTime div (1000 div 8)])
End;

Procedure DrawFloatingTexts();
Var
	ft: sInt;
Begin
	For ft:=Low(FloatTxt) to High(FloatTxt) do
		If (FloatTxt[ft]<>NIL) then
			PrintText(FloatTxt[ft]^.Text, Font, FloatTxt[ft]^.X, FloatTxt[ft]^.Y, ALIGN_LEFT, ALIGN_TOP, FloatTxt[ft]^.Colour)
End;

Procedure DrawUI();
Const
	HP_src: TSDL_Rect = (X: 0; Y:0; W:16; H:16);
	HP_dst: TSDL_Rect = (X: 0; Y:0; W:16; H:16);
	
	Col_src: TSDL_Rect = (X: 16; Y:0; W:16; H:16);
	Col_dst: TSDL_Rect = (X: RESOL_W-16; Y:0; W:16; H:16);
	
	FPS_src: TSDL_Rect = (X: 32; Y:0; W:16; H:16);
	FPS_dst: TSDL_Rect = (X: RESOL_W-16; Y:RESOL_H-16; W:16; H:16);
	
	Vol_src: TSDL_Rect = (X: 48; Y:0; W:16; H:16);
	Vol_dst: TSDL_Rect = (X: 0; Y:RESOL_H-16; W:16; H:16);
	
	PauseRect: TSDL_Rect = (X: (RESOL_W - 64) div 2; Y: (RESOL_H - 32) div 2; W: 64; H: 32);
Var
	Dst, DstCpy: TSDL_Rect;
	HealthBarColour: PSDL_Colour;
	C, d: sInt;
Begin
	// Health indicator
	DrawImage(UIgfx, @HP_src, @HP_dst, NIL);
	If (Hero^.HP > 0) then begin
		Dst.X := 3;
		Dst.Y := 9;
		Dst.W := 1+Trunc(9*Hero^.HP/Hero^.MaxHP);
		Dst.H := 4;

		{$IFDEF LD25_DEBUG}
		If CheatInvulnerability then
			HealthBarColour := @LimeColour
		else
		{$ENDIF}
		If (Hero^.InvTimer > 0) then
			HealthBarColour := @GreyColour
		else
			HealthBarColour := @WhiteColour;

		DrawRectFilled(@Dst, HealthBarColour)
	end;

	// Colour indicator
	DrawImage(UIgfx, @Col_src, @Col_dst, NIL);
	For C:=0 to 7 do begin
		If (ColState[C]=STATE_NONE) then Continue;
		
		Dst.X:=RESOL_W-14+((C mod 4)*3); 
		If ((C mod 4)>1) then Dst.X+=1;
		
		Dst.Y:=9; 
		If (C>=4) then Dst.Y+=3;
		
		// For given colours, draw a 2x2 rectangle.
		// For carried colours, draw two (randomly selected) pixels in the 2x2 rectangle area.
		If (ColState[C]=STATE_GIVEN) then begin
			Dst.W:=2; Dst.H:=2;
			DrawRectFilled(@Dst, @UIcolour[C])
		end else begin
			Dst.W:=1; Dst.H:=1;
			For d:=0 to 1 do begin
				dstcpy := Dst;
				dstcpy.X += Random(0, 1);
				dstcpy.Y += Random(0, 1);
				DrawRectFilled(@dstcpy, @UIcolour[C])
			end
		end
	end;

	// Volume indicator
	DrawImage(UIgfx, @Vol_src, @Vol_dst, NIL);
	For C:=GetVol() downto 1 do begin
		Dst.X := C*2;              Dst.W := 2;
		Dst.Y := RESOL_H - 2 - C;  Dst.H := C;
		DrawRectFilled(@Dst, @WhiteColour)
	end;

	// Frames per second indicator
	DrawImage(UIgfx, @FPS_src, @FPS_dst, NIL);
	PrintText(FrameStr, NumFont, (RESOL_W-8), (RESOL_H-7), ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

	// If paused, draw frame with "PAUSED" bouncing
	If (Paused) then begin
		Dst := PauseRect;
		DrawRectFilled(@Dst, @WhiteColour);
		
		With Dst do begin X+=1; Y+=1; W-=2; H-=2 end;
		DrawRectFilled(@Dst, @BlackColour);
		
		PrintText('PAUSED', Font, Dst.X+PauseTxt.X, Dst.Y+PauseTxt.Y, ALIGN_LEFT, ALIGN_TOP, @WhiteColour)
	end
End;

Procedure DrawFrame();
Begin
	Rendering.BeginFrame();
	DrawRoom();

	If (Length(Gib)>0) then DrawGibs();
	If (Length(Mob)>0) then DrawMonsters();
	If (Length(PBul)>0) then DrawPlayerBullets();
	If (Length(EBul)>0) then DrawEnemyBullets();

	DrawHero();
	DrawCrystal();
	
	If (Length(FloatTxt)>0) then DrawFloatingTexts();

	{$IFDEF LD25_DEBUG} If Not (CheatHideUI) then {$ENDIF} DrawUI();

	Rendering.FinishFrame()
end;

Procedure CountFrames(Const Time:uInt);
Begin
	Frames+=1; FrameTime+=Time;
	
	If (FrameTime >= 1000) then begin
		If (Paused) then begin 
			PauseTxt.X:=Random(PAUSETXT_W); PauseTxt.Y:=Random(PAUSETXT_H) 
		end;
		
		WriteStr(FrameStr,Frames);
		FrameTime-=1000; Frames:=0
	end
End;

Procedure PerformRoomChange();
Begin
	Case (RoomChange) of
		RCHANGE_UP: begin
			If (ChangeRoom(Room^.X,Room^.Y-1)) then Hero^.mY:=(ROOM_H-1)
		end;
		
		RCHANGE_RIGHT: begin
			If (ChangeRoom(Room^.X+1,Room^.Y)) then Hero^.mX:=0
		end;
		
		RCHANGE_DOWN: begin
			If (ChangeRoom(Room^.X,Room^.Y+1)) then Hero^.mY:=0
		end;
		
		RCHANGE_LEFT: begin
			If (ChangeRoom(Room^.X-1,Room^.Y)) then Hero^.mX:=(ROOM_W-1)
		end
	end;
	
	RoomChange := RCHANGE_NONE
End;


Procedure DamageMob(Const mID:uInt; Const Power:Double);
Var
	Idx, ChildID: sInt;
Begin
	Mob[mID]^.HP-=Power;
	If (Mob[mID]^.HP <= 0) then begin
		If (Mob[mID]^.SwitchNum >= 0) then Switch[Mob[mID]^.SwitchNum]:=True;

		PlaceGibs(Mob[mID], Mob[mID]^.Sprite^.GetFrame(AniFra, Mob[mID]^.Face));
		PlaySfx(Mob[mID]^.SfxID);
		Stats.KillsMade.Modify(+1);

		If (Length(Mob[mID]^.Children) > 0) then begin
			For Idx := Low(Mob[mID]^.Children) to High(Mob[mID]^.Children) do begin
				ChildID := Mob[mID]^.Children[Idx];
				If Mob[ChildID] <> NIL then DamageMob(ChildID, 1000);
			end;
		end;

		Dispose(Mob[mID],Destroy()); Mob[mID]:=NIL
	end 
End;

Procedure DamagePlayer(Const Power:Double);
Begin
	PlaySfx(SFX_HIT);
	Hero^.InvTimer := Hero^.InvLength;

	Stats.HitsTaken.Modify(+1);

	{$IFDEF LD25_DEBUG}
	If(CheatInvulnerability) then Exit;
	{$ENDIF}

	Hero^.HP -= Power;
	If (Hero^.HP <= 0) then begin
		DeadTime:=DeathLength;
		PlaceGibs(Hero, HeroSprite.GetFrame(AniFra, Hero^.Face));
		
		PlaySfx(SFX_EXTRA+2);
		Stats.TimesDied.Modify(+1)
	end
End;

{$IFDEF LD25_DEBUG}
Procedure ResetDebugCheats(); Inline;
Begin
	CheatInvulnerability := False;
	CheatNoClip := False;
	CheatHitboxes := False;
	CheatHideUI := False;

	CheatFreeze := FREEZE_NONE
End;
{$ENDIF}

Function PlayGame():Boolean;
Const
	DELTA_MAXIMUM = 100; // Limit timestep to 100ms (10 updates/s)
Var
	DeltaTime, Ticks, Timestep: uInt;
	pk: TPlayerKey;
Begin
	GetDeltaTime(DeltaTime);
	SetAllowScreensaver(False);
	SDL_ShowCursor(0);
	
	For pk := Low(TPlayerKey) to High(TPlayerKey) do Key[pk]:=False;
	{$IFDEF LD25_MOBILE} TouchControls.SetVisibility(True); {$ENDIF}
	
	RoomChange:=RCHANGE_NONE;
	Paused:=False; WantToQuit:=False; 
	Frames:=0; FrameTime:=0; FrameStr:='???';
	
	PauseTxt.X:=PAUSETXT_W div 2; PauseTxt.Y:=PAUSETXT_H div 2;
	Font^.Scale := 1;

	{$IFDEF LD25_DEBUG} ResetDebugCheats(); {$ENDIF}
	Repeat
		If (RoomChange <> RCHANGE_NONE) then PerformRoomChange();
		
		GetDeltaTime(DeltaTime, Ticks);
		Animate(Ticks);
		GatherInput();

		If (Not Paused) then begin
			Timestep := DeltaTime;
			While Timestep > DELTA_MAXIMUM do begin
				CalculateGameCycle(DELTA_MAXIMUM);
				Timestep -= DELTA_MAXIMUM
			end;
			CalculateGameCycle(Timestep)
		end;

		DrawFrame();
		CountFrames(DeltaTime);

	Until WantToQuit;

	{$IFDEF LD25_MOBILE} TouchControls.SetVisibility(False); {$ENDIF}

	SetAllowScreensaver(True);
	SDL_ShowCursor(1);
	Exit(Given >= 8)
End;

End.
