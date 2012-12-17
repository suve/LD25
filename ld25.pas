program ld25; {$MODE OBJFPC} {$TYPEDADDRESS ON} {$COPERATORS ON} {$WRITEABLECONST OFF}

uses SysUtils, Shared, SDL, Sour, GL, BASS, Rooms, Objects;

Var Room:PRoom;

Procedure LoadUpdate(Name:AnsiString;Perc:Double);
   Const STARTX = RESOL_W div 32; SIZEX = RESOL_W - (STARTX*2);
         SIZEY = RESOL_H div 32; STARTY = RESOL_H - (SIZEY*3);
   Var Rect:Sour.TRect; Col:Sour.TColour;
   begin
   Sour.BeginFrame();
   Sour.DrawImage(TitleGfx,NIL);
   Sour.SetFontScaling(Font,1);
   Sour.PrintText(UpperCase('V.'+GAMEVERS+' (build '+GAMEDATE+')'),Font,(RESOL_W div 2),82,ALIGN_CENTER,ALIGN_MIDDLE);
   Sour.SetFontScaling(Font,2);
   Sour.PrintText(UpperCase(Name),Font,(RESOL_W div 2),STARTY-(Font^.ChrW*2),ALIGN_CENTER,ALIGN_MIDDLE);
   Rect:=Sour.MakeRect(STARTX,STARTY,SIZEX,SIZEY);
   Sour.FillRect(@Rect);
   Rect:=Sour.MakeRect(STARTX,STARTY,Trunc(SIZEX*Perc),SIZEY);
   Col:=Sour.MakeColour(64+Random(128),64+Random(128),64+Random(128),255);
   Sour.FillRect(@Rect,@Col);
   Sour.FinishFrame();
   end;

Function WaitForKey:Boolean;
   Var Q:LongInt;
   begin
   Q:=0;
   While (Q=0) do begin
      While (SDL_PollEvent(@Ev)>0) do begin
            If (Ev.Type_ = SDL_QuitEv) then Q:=-1 else
            If (Ev.Type_ = SDL_KeyDown) then begin
               If (Ev.Key.Keysym.Sym = SDLK_ESCAPE) then Q:=-1 else Q:=1
            end
         end;
      SDL_Delay(25)
      end;
   Exit(Q >= 0)
   end;

Function Intro():Boolean;
   Var Q,I,P:Boolean; C:LongWord;
   begin
   Sour.BeginFrame();
   Sour.DrawImage(TitleGfx,NIL);
   Sour.SetFontScaling(Font,1);
   Sour.PrintText(UpperCase('V.'+GAMEVERS+' (build '+GAMEDATE+')'),Font,(RESOL_W div 2),82,ALIGN_CENTER,ALIGN_MIDDLE);
   Sour.SetFontScaling(Font,2);
   Sour.PrintText(['I - INTRODUCTION','','P - PLAY','','Q - QUIT'],
                  Font,(RESOL_W div 2),((RESOL_H*3) div 4),ALIGN_CENTER,ALIGN_MIDDLE);
   Sour.FinishFrame();
   Q:=False; I:=False; P:=False;
   While Not (Q or I or P) do begin
      While (SDL_PollEvent(@Ev)>0) do begin
            If (Ev.Type_ = SDL_QuitEv) then Q:=True else
            If (Ev.Type_ = SDL_KeyDown) then begin
               If (Ev.Key.Keysym.Sym = SDLK_ESCAPE) then Q:=True else
               If (Ev.Key.Keysym.Sym = SDLK_I) then I:=True else
               If (Ev.Key.Keysym.Sym = SDLK_P) then P:=True else
               If (Ev.Key.Keysym.Sym = SDLK_Q) then Q:=True else
               If (Ev.Key.Keysym.Sym = SDLK_RETURN) then P:=True else
            end
         end;
      SDL_Delay(25)
      end;
   If (Q) then Exit(False) else If (P) then Exit(True);
   For C:=Low(SlideIn) to High(SlideIn) do begin
       Sour.BeginFrame();
       Sour.DrawImage(SlideIn[C],NIL);
       Sour.FinishFrame();
       If Not WaitForKey then Exit(False)
       end;
   Sour.BeginFrame();
   Sour.DrawImage(TitleGFX,NIL);
   Sour.FinishFrame();
   If Not WaitForKey then Exit(False);
   Exit(True);
   end;

Procedure Outro();
   Var C:LongWord;
   begin
   For C:=Low(SlideOut) to High(SlideOut) do begin
       Sour.BeginFrame();
       Sour.DrawImage(SlideOut[C],NIL);
       Sour.FinishFrame();
       If Not WaitForKey then Exit()
       end;
   Sour.BeginFrame();
   Sour.PrintText([UpperCase(GAMENAME),'BY SUPER VEGETA','','A LUDUM DARE 25 GAME','','THANKS TO:','DANIEL REMAR','DEXTERO'],
                  Font,(RESOL_W div 2),(RESOL_H div 2),ALIGN_CENTER,ALIGN_MIDDLE);
   Sour.FinishFrame();
   If Not WaitForKey then Exit();
   end;

Procedure Startup;
   Var S:AnsiString; Dr:PDrone; Ba:PBasher; Bl:PBall; Sp:PSpitter; Sm:PSpammer;
   begin
   If (Not BASS_Init(1,44100,0,0,NIL)) then ;
   If (SDL_Init(SDL_Init_Video or SDL_Init_Timer)<>0) then begin
      Writeln('ERROR: SDL_Init() failed!'); Halt(1) end;
   Sour.SetGLAttributes(8,8,8);
   Writeln('Opening window...');
   Screen:=Sour.OpenWindow(WINDOW_W,WINDOW_H);
   If (Screen=NIL) then begin
      Writeln('ERROR: Failed to open window!'); Halt(1) end;
   S:=GAMENAME+' v.'+GAMEVERS;
   SDL_WM_SetCaption(PChar(S),PChar(S));
   Sour.SetClearColour(Sour.MakeColour($000000));
   Sour.SetResolution(RESOL_W,RESOL_H);
   Sour.NonPOT := True;
   If Not Shared.LoadBasics(S) then begin
      Shared.Free(); SDL_Quit;
      Writeln('ERROR: ',S); Halt(1)
      end;
   If Not Shared.LoadRes(S,@LoadUpdate) then begin
      Shared.Free(); SDL_Quit;
      Writeln('ERROR: ',S); Halt(1)
      end;
   New(Hero,Create());
      Hero^.mX:=10; Hero^.mY:=6; Hero^.W:=TILE_W; Hero^.H:=TILE_H;
   SetLength(Mob,0); SetLength(EBul,0); SetLength(PBul,0);
   Room:=GameRoom[3,3]; Room^.RunScript()
   end;

Function ChangeRoom(NX,NY:LongInt):Boolean;
   Var C:LongWord;
   begin
   // First, check if room exists
   If (NX<0) or (NY<0) or (NX>=MAP_W) or (NY>=MAP_H) or (GameRoom[NX][NY]=NIL) then Exit(False);
   // Remove entities (apart from the hero, that is)
   If (Length(Mob)>0) then
      For C:=Low(Mob) to High(Mob) do
          If (Mob[C]<>NIL) then Mob[C]^.Destroy;
   If (Length(PBul)>0) then
      For C:=Low(PBul) to High(PBul) do
          If (PBul[C]<>NIL) then PBul[C]^.Destroy;
   If (Length(EBul)>0) then
      For C:=Low(EBul) to High(EBul) do
          If (EBul[C]<>NIL) then EBul[C]^.Destroy;
   If (Length(Gib)>0) then
      For C:=Low(Gib) to High(Gib) do
          If (Gib[C]<>NIL) then Gib[C]^.Destroy;
   SetLength(Mob,0); SetLength(EBul,0); SetLength(PBul,0); SetLength(Gib,0);
   Crystal.IsSet:=False;
   // Change room and run its script
   Room:=GameRoom[NX][NY]; Room^.RunScript();
   Exit(True)
   end;

Procedure DamageMob(X:LongWord;Power:Double);
   begin
   Mob[X]^.HP-=Power;
   If (Mob[X]^.HP <= 0) then begin
      If (Mob[X]^.SwitchNum >= 0) then Switch[Mob[X]^.SwitchNum]:=True;
      PlaceGibs(Mob[X]); PlaySfx(Mob[X]^.SfxID); Mob[X]:=NIL
      end // else PlaySfx(SFX_HIT)
   end;

Procedure DamagePlayer(Power:Double);
   begin
   Hero^.HP-=Power;
   Hero^.InvTimer := Hero^.InvLength; PlaySfx(SFX_HIT);
   If (Hero^.HP <= 0) then begin
      DeadTime:=DeathLength;
      PlaceGibs(Hero); PlaySfx(SFX_EXTRA+2)
      end
   end;

Function PlayableLulz:Boolean;
   Const TwoRoot = Sqrt(2);
         HPrect : Sour.TRect = (X: 0; Y:0; W:16; H:16);
         ColRect : Sour.TRect = (X: 16; Y:0; W:16; H:16);
         FPSRect : Sour.TRect = (X: 32; Y:0; W:16; H:16);
         Gray : Sour.TColour = (R: 128; G: 128; B: 128; A:255);
   Var Time,Ticks : LongWord; Q:Boolean; E:PEntity;
       XDif, YDif, ChkX, ChkY : Double;
       C, X, Y : LongInt;
       Src,Dst,Rect : Sour.TRect; Crd : Sour.TCrd; Col:Sour.TColour;
       AniFra,FraTime,Frames:LongWord; FraStr:AnsiString;
   begin
   GetDeltaTime(Time); Q:=False; FraTime:=0; Frames:=0; FraStr:='???';
   Src.W:=TILE_W; Src.H:=TILE_H; Dst.W:=TILE_W; Dst.H:=TILE_H;
   Repeat
      GetDeltaTime(Time, Ticks);
      AniFra:=(Ticks div AnimTime) mod 2;

      While (SDL_PollEvent(@Ev)>0) do begin
         If (Ev.Type_ = SDL_QuitEv) then Q:=True else
         If (Ev.Type_ = SDL_KeyDown) then begin
            If (Ev.Key.Keysym.Sym = SDLK_Escape) then Q:=True else
            If (Ev.Key.Keysym.Sym = SDLK_UP    ) then Key[KEY_UP   ]:=True else
            If (Ev.Key.Keysym.Sym = SDLK_RIGHT ) then Key[KEY_RIGHT]:=True else
            If (Ev.Key.Keysym.Sym = SDLK_DOWN  ) then Key[KEY_DOWN ]:=True else
            If (Ev.Key.Keysym.Sym = SDLK_LEFT  ) then Key[KEY_LEFT ]:=True else
            If (Ev.Key.Keysym.Sym = SDLK_Z     ) then Key[KEY_Z    ]:=True else
            If (Ev.Key.Keysym.Sym = SDLK_X     ) then Key[KEY_X    ]:=True else
            If (Ev.Key.Keysym.Sym = SDLK_H) then Hero^.HP:=Hero^.MaxHP else
            end else
         If (Ev.Type_ = SDL_KeyUp) then begin
            If (Ev.Key.Keysym.Sym = SDLK_UP    ) then Key[KEY_UP   ]:=False else
            If (Ev.Key.Keysym.Sym = SDLK_RIGHT ) then Key[KEY_RIGHT]:=False else
            If (Ev.Key.Keysym.Sym = SDLK_DOWN  ) then Key[KEY_DOWN ]:=False else
            If (Ev.Key.Keysym.Sym = SDLK_LEFT  ) then Key[KEY_LEFT ]:=False else
            If (Ev.Key.Keysym.Sym = SDLK_Z     ) then Key[KEY_Z    ]:=False else
            If (Ev.Key.Keysym.Sym = SDLK_X     ) then Key[KEY_X    ]:=False else
            end else
         end;

      If (Hero^.HP > 0) then begin
         Hero^.Calculate(Time);
         XDif:=Hero^.XVel*Time/1000; YDif:=Hero^.YVel*Time/1000;
         If (XDif<>0) then begin
            If (XDif<0) then ChkX:=Hero^.X else ChkX:=Hero^.X+Hero^.W-1;
            If (Not Room^.Collides(ChkX+XDif,Hero^.Y)) and (Not Room^.Collides(ChkX+XDif,Hero^.Y+Hero^.H-1))
               then Hero ^.X:=Hero^.X+XDif
            end;
         If (YDif<>0) then begin
            If (YDif<0) then ChkY:=Hero^.Y else ChkY:=Hero^.Y+Hero^.H-1;
            If (Not Room^.Collides(Hero^.X,ChkY+YDif)) and (Not Room^.Collides(Hero^.X+Hero^.W-1,ChkY+YDif))
               then Hero^.Y:=Hero^.Y+YDif
            end;
         end else begin
         If (DeadTime > 0) then DeadTime-=Time else begin
            ChangeRoom(3,3); Hero^.mX:=10; Hero^.mY:=6; Hero^.HP:=Hero^.MaxHP;
            Hero^.FireTimer:=0; Hero^.InvTimer:=0; Carried:=0;
            For C:=0 to 7 do If (ColState[C]=STATE_PICKED) then ColState[C]:=STATE_NONE;
         end end;

      If (Crystal.IsSet) and (Overlap(Hero^.X,Hero^.Y,Hero^.W,Hero^.H,Crystal.mX*TILE_W,Crystal.mY*TILE_H,TILE_W,TILE_H))
         then begin
         If (Crystal.Col<>WOMAN)
            then begin PlaySfx(SFX_EXTRA); ColState[Crystal.Col]:=STATE_PICKED; Carried+=1; Crystal.IsSet:=False end
            else If (Carried>0) then begin
                 PlaySfx(SFX_EXTRA+1); Given+=Carried; Carried:=0;
                 For C:=0 to 7 do if (ColState[C]=STATE_PICKED) then begin
                     CentralPalette[C]:=PaletteColour[C]; PaletteColour[C]:=GreyColour;
                     ColState[C]:=STATE_GIVEN end;
                 Hero^.MaxHP:=HERO_HEALTH*(1+(Given/14)); Hero^.HP:=Hero^.MaxHP;
                 Hero^.FirePower:=HERO_FIREPOWER*(1+(Given/14));
                 Hero^.InvLength:=Trunc(HERO_INVUL*(1+(Given/14)));
                 If (Given >= 8) then Q:=True
                 end
         end;

      If (Hero^.iX <= 0) then begin
         If (Room^.Tile[Hero^.mX][Hero^.mY]=TILE_ZONE) or (Room^.Tile[Hero^.mX][Hero^.mY]=TILE_ROOM)
            then begin if (ChangeRoom(Room^.X-1,Room^.Y)) then Hero^.mX:=(ROOM_W-1) end
         end else
      If (Hero^.iY <= 0) then begin
         If (Room^.Tile[Hero^.mX][Hero^.mY]=TILE_ZONE) or (Room^.Tile[Hero^.mX][Hero^.mY]=TILE_ROOM)
            then begin if (ChangeRoom(Room^.X,Room^.Y-1)) then Hero^.mY:=(ROOM_H-1) end
         end else
      If (Hero^.iX >= ((ROOM_W-1)*TILE_W)) then begin
         If (Room^.Tile[Hero^.mX][Hero^.mY]=TILE_ZONE) or (Room^.Tile[Hero^.mX][Hero^.mY]=TILE_ROOM)
            then begin if (ChangeRoom(Room^.X+1,Room^.Y)) then Hero^.X:=1 end
         end else
      If (Hero^.iY >= ((ROOM_H-1)*TILE_H)) then begin
         If (Room^.Tile[Hero^.mX][Hero^.mY]=TILE_ZONE) or (Room^.Tile[Hero^.mX][Hero^.mY]=TILE_ROOM)
            then begin if (ChangeRoom(Room^.X,Room^.Y+1)) then Hero^.Y:=1 end
         end;

      If (Length(PBul)>0) then begin
         For X:=Low(PBul) to High(PBul) do
             If (PBul[X]<>NIL) then begin
                XDif:=PBul[X]^.XVel*Time/1000; YDif:=PBul[X]^.YVel*Time/1000;
                If (XDif<>0) then begin
                   If (XDif<0) then ChkX:=PBul[X]^.X else ChkX:=PBul[X]^.X+PBul[X]^.W-1;
                   If (Room^.Collides(ChkX+XDif,PBul[X]^.Y))
                      then begin Room^.HitSfx(ChkX+XDif,PBul[X]^.Y); PBul[X]^.HP:=-10 end else
                   If (Room^.Collides(ChkX+XDif,PBul[X]^.Y+PBul[X]^.H-1))
                      then begin Room^.HitSfx(ChkX+XDif,PBul[X]^.Y+PBul[X]^.H-1); PBul[X]^.HP:=-10 end else
                      {else} PBul[X]^.X:=PBul[X]^.X+XDif
                   end;
                If (YDif<>0) then begin
                   If (YDif<0) then ChkY:=PBul[X]^.Y else ChkY:=PBul[X]^.Y+PBul[X]^.H-1;
                   If (Room^.Collides(PBul[X]^.X,ChkY+YDif))
                      then begin Room^.HitSfx(PBul[X]^.X,ChkY+YDif); PBul[X]^.HP:=-10 end else
                   If (Room^.Collides(PBul[X]^.X+PBul[X]^.W-1,ChkY+YDif))
                      then begin Room^.HitSfx(PBul[X]^.X+PBul[X]^.W-1,ChkY+YDif); PBul[X]^.HP:=-10 end else
                      {else} PBul[X]^.Y:=PBul[X]^.Y+YDif
                   end;
                If (PBul[X]^.HP <= 0) then begin
                    PBul[X]^.Destroy(); PBul[X]:=NIL; Continue end;
                If (Length(Mob)>0) then Y:=Low(Mob) else Y:=High(Y);
                While (Y<=High(Mob)) do begin
                   If (Mob[Y]=NIL) then begin Y+=1; Continue end;
                   If (Overlap(PBul[X],Mob[Y])) then begin
                      DamageMob(Y,PBul[X]^.Power);
                      PBul[X]^.Destroy(); PBul[X]:=NIL;
                      Y:=High(Mob)*2
                      end else Y+=1
                   end
                end
         end;

      For X:=Low(Mob) to High(Mob) do
          If (Mob[X]<>NIL) then begin
             E:=Mob[X];
             E^.Calculate(Time);
             XDif:=E^.XVel*Time/1000;
             YDif:=E^.YVel*Time/1000;
             If (XDif<>0) then begin
                If (XDif<0) then begin E^.Face:=FACE_LEFT;  ChkX:=E^.X end
                            else begin E^.Face:=FACE_RIGHT; ChkX:=E^.X+E^.W-1 end;
                If (Not Room^.Collides(ChkX+XDif,E^.Y)) and (Not Room^.Collides(ChkX+XDif,E^.Y+E^.H-1))
                   then begin E^.X:=E^.X+XDif; E^.XCol:=False end
                   else E^.XCol:=True;
                end else E^.XCol:=False;
             If (YDif<>0) then begin
                If (YDif<0) then ChkY:=E^.Y else ChkY:=E^.Y+E^.H-1;
                If (Not Room^.Collides(E^.X,ChkY+YDif)) and (Not Room^.Collides(E^.X+E^.W-1,ChkY+YDif))
                   then begin E^.Y:=E^.Y+YDif; E^.YCol:=False end
                   else E^.YCol:=True
                end else E^.YCol:=False;
             If (Hero^.HP > 0) and (Hero^.InvTimer <= 0) and (Overlap(Hero,E))
                then begin DamageMob(X,9.75); DamagePlayer(9.75) end
             end;

      If (Length(EBul)>0) then begin
         For X:=Low(EBul) to High(EBul) do
             If (EBul[X]<>NIL) then begin
                XDif:=EBul[X]^.XVel*Time/1000; YDif:=EBul[X]^.YVel*Time/1000;
                If (XDif<>0) then begin
                   If (XDif<0) then ChkX:=EBul[X]^.X else ChkX:=EBul[X]^.X+EBul[X]^.W-1;
                   If (Room^.Collides(ChkX+XDif,EBul[X]^.Y))
                      then begin Room^.HitSfx(ChkX+XDif,EBul[X]^.Y); EBul[X]^.HP:=-10 end else
                   If (Room^.Collides(ChkX+XDif,EBul[X]^.Y+EBul[X]^.H-1))
                      then begin Room^.HitSfx(ChkX+XDif,EBul[X]^.Y+EBul[X]^.H-1); EBul[X]^.HP:=-10 end else
                      {else} EBul[X]^.X:=EBul[X]^.X+XDif
                   end;
                If (YDif<>0) then begin
                   If (YDif<0) then ChkY:=EBul[X]^.Y else ChkY:=EBul[X]^.Y+EBul[X]^.H-1;
                   If (Room^.Collides(EBul[X]^.X,ChkY+YDif))
                      then begin Room^.HitSfx(EBul[X]^.X,ChkY+YDif); EBul[X]^.HP:=-10 end else
                   If (Room^.Collides(EBul[X]^.X+EBul[X]^.W-1,ChkY+YDif))
                      then begin Room^.HitSfx(EBul[X]^.X+EBul[X]^.W-1,ChkY+YDif); EBul[X]^.HP:=-10 end else
                      {else} EBul[X]^.Y:=EBul[X]^.Y+YDif
                   end;
                If (EBul[X]^.HP <= 0) then begin
                    EBul[X]^.Destroy(); EBul[X]:=NIL; Continue end;
                If (Hero^.HP > 0) and (Hero^.InvTimer <= 0) and (Overlap(EBul[X],Hero))
                   then begin DamagePlayer(EBul[X]^.Power); EBul[X]^.Destroy(); EBul[X]:=NIL end;
                end
         end;

      If (Length(Gib)>0) then For C:=Low(Gib) to High(Gib) do
          If (Gib[C]<>NIL) then begin
             XDif:=Gib[C]^.XVel*Time/1000; YDif:=Gib[C]^.YVel*Time/1000;
             If (XDif<>0) then begin
                If (XDif<0) then ChkX:=Gib[C]^.X else ChkX:=Gib[C]^.X+Gib[C]^.W-1;
                If (Room^.Collides(ChkX+XDif,Gib[C]^.Y)) or (Room^.Collides(ChkX+XDif,Gib[C]^.Y+Gib[C]^.H-1))
                   then Gib[C]^.HP:=-10 else Gib[C]^.X:=Gib[C]^.X+XDif
                end;
             If (YDif<>0) then begin
                If (YDif<0) then ChkY:=Gib[C]^.Y else ChkY:=Gib[C]^.Y+Gib[C]^.H-1;
                If (Room^.Collides(Gib[C]^.X,ChkY+YDif)) or (Room^.Collides(Gib[C]^.X+Gib[C]^.W-1,ChkY+YDif))
                   then Gib[C]^.HP:=-10 else Gib[C]^.Y:=Gib[C]^.Y+YDif
             end;
             If (Gib[C]^.HP <= 0) then begin
                Gib[C]^.Destroy(); Gib[C]:=NIL end
             end;

      Sour.BeginFrame();
      Src.X:=AniFra*TILE_W;
      For Y:=0 to (ROOM_H-1) do For X:=0 to (ROOM_W-1) do begin
          If (Room^.Tile[X][Y]=TILE_NONE) then Continue;
          Dst.X:=X*TILE_W; Dst.Y:=Y*TILE_H;
          Src.Y:=Room^.Tile[X][Y]*TILE_H;
          Sour.DrawImage(TileGfx,@Src,@Dst,Room^.TCol[X][Y])
          end;
      // Map has been drawn

      If (Length(Gib)>0) then For C:=Low(Gib) to High(Gib) do
         If (Gib[C]<>NIL) then begin
            Sour.SetRect(Rect,Gib[C]^.iX,Gib[C]^.iY,Gib[C]^.Rect.W,Gib[C]^.Rect.H);
            Sour.DrawImage(Gib[C]^.Gfx,@Gib[C]^.Rect,@Rect,Gib[C]^.Col)
            end;

      If (Length(Mob)>0) then
         For X:=Low(Mob) to High(Mob) do
             If (Mob[X]<>NIL) then begin
                E:=Mob[X]; Crd:=E^.GetCrd;
                Rect:=Sour.MakeRect(AniFra*E^.W,E^.Face*E^.H,E^.W,E^.H);
                Sour.DrawImage(E^.Gfx,@Rect,@Crd,E^.Col)
                end;
      // Enemies drawn

      If (Length(PBul)>0) then
         For X:=Low(PBul) to High(PBul) do
             If (PBul[X]<>NIL) then begin
                E:=PBul[X]; Crd:=E^.GetCrd;
                Rect:=Sour.MakeRect(AniFra*E^.W,E^.Face*E^.H,E^.W,E^.H);
                Sour.DrawImage(E^.Gfx,@Rect,@Crd,E^.Col)
                end;
      If (Length(EBul)>0) then
         For X:=Low(EBul) to High(EBul) do
             If (EBul[X]<>NIL) then begin
                E:=EBul[X]; Crd:=E^.GetCrd;
                Rect:=Sour.MakeRect(AniFra*E^.W,E^.Face*E^.H,E^.W,E^.H);
                Sour.DrawImage(E^.Gfx,@Rect,@Crd,E^.Col)
                end;
      //Bullets drawn

      If (Hero^.HP > 0) then begin
         Sour.SetCrd(Crd,Hero^.iX,Hero^.iY);
         If (Hero^.InvTimer > 0) then begin
            Crd.X+=Random(-1,1); Crd.Y+=Random(-1,1) end;
         Sour.SetRect(Rect,AniFra*Hero^.W,Hero^.Face*Hero^.H,Hero^.W,Hero^.H);
         Sour.DrawImage(Hero^.Gfx,@Rect,@Crd,Hero^.Col)
         end; // Hero drawn

      If (Crystal.IsSet) then begin
         Sour.SetRect(Src,AniFra*TILE_W,Crystal.Col*TILE_H,TILE_W,TILE_H);
         Sour.SetCrd(Crd,Crystal.mX*TILE_W,Crystal.mY*TILE_H);
         Sour.DrawImage(ColGfx,@Src,@Crd)
         end;

      Crd:=Sour.MakeCrd(0,0);
      Sour.DrawImage(UIgfx,@HPrect,@Crd);
      If (Hero^.HP > 0) then begin
         Sour.SetRect(Rect,3,9,1+Trunc(9*Hero^.HP/Hero^.MaxHP),4);
         If (Hero^.InvTimer <= 0)
            then Sour.FillRect(@Rect,@WhiteColour)
            else Sour.FillRect(@Rect,@GreyColour)
         end;

      Crd:=Sour.MakeCrd(RESOL_W-16,0);
      Sour.DrawImage(UIgfx,@ColRect,@Crd);
      For C:=0 to 7 do
          If (ColState[C]<>STATE_NONE) then begin
             Rect.X:=RESOL_W-14+((C mod 4)*3); If ((C mod 4)>1) then Rect.X+=1;
             Rect.Y:=09; If (C>=4) then Rect.Y+=3;
             If (ColState[C]=STATE_GIVEN)
                then begin
                Rect.W:=2; Rect.H:=2
                end else begin
                Rect.W:=1; Rect.H:=1;
                Rect.X+=Random(2); Rect.Y+=Random(2)
                end;
             Sour.FillRect(@Rect,UIcolour[C])
             end;

      Crd:=Sour.MakeCrd(RESOL_W-16,RESOL_H-16);
      Sour.DrawImage(UIgfx,@FPSrect,@Crd);
      Sour.PrintText(FraStr,NumFont,(RESOL_W-8),(RESOL_H-7),ALIGN_CENTER);

      Sour.FinishFrame();

      Frames+=1; FraTime+=Time;
      If (FraTime >= 1000) then begin
         WriteStr(FraStr,Frames);
         FraTime-=1000; Frames:=0
         end;

      until Q;
   Exit(Given >= 8)
   end;

begin
Writeln(GAMENAME,' by ',GAMEAUTH);
Writeln('v.',GAMEVERS,' (build ',GAMEDATE,')');
Writeln(StringOfChar('-',40));
Randomize();
Startup();
If Intro()
   then If PlayableLulz()
           then Outro();
Shared.Free();
SDL_Quit;
end.

