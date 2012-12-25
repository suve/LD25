program ld25; {$MODE OBJFPC} {$TYPEDADDRESS ON} {$COPERATORS ON} {$WRITEABLECONST OFF}
   uses SysUtils, Shared, SDL, Sour, GL, BASS, Rooms, Objects, FloatingText, configfiles;

//{$DEFINE DEVELOPER}
(* Activates some debug functions. Remember to comment out when building a public release! *)

Var MenuChoice:Char;

Procedure DrawTitle();
   begin
   Sour.DrawImage(TitleGfx,NIL);
   Sour.SetFontScaling(Font,1);
   Sour.PrintText(UpperCase('V.'+GAMEVERS+' (build '+GAMEDATE+')')
                  {$IFDEF DEVELOPER}+' DEVELOPER'{$ENDIF},
                  Font,(RESOL_W div 2),82,ALIGN_CENTER,ALIGN_MIDDLE)
   end;

Procedure LoadUpdate(Name:AnsiString;Perc:Double);
   Const STARTX = RESOL_W div 32; SIZEX = RESOL_W - (STARTX*2);
         SIZEY = RESOL_H div 32; STARTY = RESOL_H - (SIZEY*3);
   Var Rect:Sour.TRect; Col:Sour.TColour;
   begin
   Sour.BeginFrame(); DrawTitle();
   Sour.SetFontScaling(Font,2);
   Sour.PrintText(UpperCase(Name),Font,(RESOL_W div 2),STARTY-(Font^.ChrW*2),ALIGN_CENTER,ALIGN_MIDDLE);
   Rect:=Sour.MakeRect(STARTX,STARTY,SIZEX,SIZEY);
   Sour.FillRect(@Rect);
   Rect:=Sour.MakeRect(STARTX,STARTY,Trunc(SIZEX*Perc),SIZEY);
   Col:=Sour.MakeColour(64+Random(128),64+Random(128),64+Random(128),255);
   Sour.FillRect(@Rect,@Col);
   Sour.FinishFrame();
   end;

Procedure BindKeys();
   Const KeyName : Array[TPlayerKey] of AnsiString = (
         'MOVE UP','MOVE RIGHT','MOVE DOWN','MOVE LEFT','SHOOT LEFT','SHOOT RIGHT',
         'PAUSE','VOLUME DOWN','VOLUME UP');
   Var K:TPlayerKey; NewBind:Array[TPlayerKey] of TSDLKey; dt:LongWord; Finito,Bound:Boolean;
   begin
   Finito:=False; Bound:=False; K:=Low(TPlayerKey);
   Repeat
       Sour.BeginFrame(); DrawTitle();
       Sour.SetFontScaling(Font,2);
       Sour.PrintText('SET KEY BINDINGS',Font,(RESOL_W div 2),TitleGfx^.H,ALIGN_CENTER);
       Sour.PrintText(KeyName[K],Font,(RESOL_W div 2),(RESOL_H + TitleGfx^.H) div 2,ALIGN_CENTER,ALIGN_MIDDLE);
       Sour.FinishFrame();
       GetDeltaTime(dt);
       While (SDL_PollEvent(@Ev)>0) do begin
          If (Ev.Type_ = SDL_QuitEv) then begin
             Shutdown:=True; Exit() end else
          If (Ev.Type_ = SDL_KeyDown) then begin
             If (Ev.Key.Keysym.Sym = SDLK_Escape) then Exit() else begin
                NewBind[K]:=Ev.Key.Keysym.Sym; Bound:=True end
             end else
          If (Ev.Type_ = SDL_VideoResize) then
            Shared.ResizeWindow(Ev.Resize.W,Ev.Resize.H,False) else
          end;
       If (Bound) then begin
          If (K<High(TPlayerKey)) then Inc(K) else Finito:=True;
          Bound:=False
          end;
       until Finito;
   For K:=Low(TPlayerKey) to High(TPlayerKey)
       do KeyBind[K]:=NewBind[K]
   end;

Function GameworldDialog(Load:Boolean):Char;
   Const WorldNames:Array[TGameMode] of AnsiString = (
         'T - TUTORIAL','N - NORMAL  ');
   Var Msg:AnsiString; OK:Array[TGameMode] of Boolean; GM:TGameMode; Choice:Char;
       YPos:LongWord; Col:Sour.PColour; dt:LongWord;
   begin
   If Load then begin Msg:='LOAD GAME';
      For GM:=Low(GM) to High(GM) do Ok[GM]:=SaveExists[GM]
      end else begin Msg:='NEW GAME';
      For GM:=Low(GM) to High(GM) do Ok[GM]:=True
      end;
   Choice:=#$20;
   While (Choice = #$20) do begin
      Sour.BeginFrame(); DrawTitle();
      Sour.SetFontScaling(Font,2.0);
      Sour.PrintText([Msg,'','SELECT GAMEWORLD'],Font,(RESOL_W div 2),TitleGfx^.H,ALIGN_CENTER);
      YPos:=((RESOL_H * 3) div 5);
      For GM:=Low(GM) to High(GM) do begin
          If (OK[GM]) then Col:=@WhiteColour else Col:=@GreyColour;
          Sour.PrintText(WorldNames[GM],Font,(RESOL_W div 2),YPos,ALIGN_CENTER,Col);
          YPos+=Trunc(Font^.SpaY*2*Font^.Scale)
          end;
      Sour.FinishFrame();
      GetDeltaTime(dt);
      While (SDL_PollEvent(@Ev)>0) do begin
          If (Ev.Type_ = SDL_QuitEv) then begin
             Shutdown:=True; Exit('Q') end else
          If (Ev.Type_ = SDL_KeyDown) then begin
             If (Ev.Key.Keysym.Sym = SDLK_Escape) then Choice:='Q' else
             If (Ev.Key.Keysym.Sym = SDLK_T) then begin
                If (OK[GM_TUTORIAL]) then Choice:='T' end else
             If (Ev.Key.Keysym.sym = SDLK_N) then begin
                If (Ok[GM_ORIGINAL]) then Choice:='N' end else
             end else
          If (Ev.Type_ = SDL_VideoResize) then
            Shared.ResizeWindow(Ev.Resize.W,Ev.Resize.H,False) else
          end;
      end;
   Exit(Choice)
   end;

Function ShowSlide(Img:Sour.PImage):Boolean;
   Var Q:LongInt; dt:LongWord;
   begin
   Q:=0;
   While (Q = 0) do begin
      Sour.BeginFrame();
      Sour.DrawImage(Img,NIL);
      Sour.FinishFrame();
      GetDeltaTime(dt);
      While (SDL_PollEvent(@Ev)>0) do begin
         If (Ev.Type_ = SDL_QuitEv) then begin
            Shutdown:=True; Exit(False) end else
         If (Ev.Type_ = SDL_KeyDown) then begin
            If (Ev.Key.Keysym.Sym = SDLK_ESCAPE) then Q:=-1 else Q:=1
            end else
         If (Ev.Type_ = SDL_VideoResize) then
            Shared.ResizeWindow(Ev.Resize.W,Ev.Resize.H,False) else
         end;
      end;
   Exit(Q >= 0)
   end;

Function Intro():Boolean;
   Var C:LongWord;
   begin
   For C:=Low(SlideIn) to High(SlideIn) do
       If (Not ShowSlide(SlideIn[C])) then Exit(False);
   If (Not ShowSlide(TitleGfx)) then Exit(False);
   Exit(True)
   end;

Function Menu():Char;
   Var Choice:Char; dt,XPos,YPos:LongWord; Col:Sour.PColour; IHasSaves:Boolean; GM:TGameMode;
   begin
   XPos:=Length('I - INTRODUCTION');
   XPos:=Trunc(((Font^.SpaX*(XPos-1))+Font^.ChrW)*2);
   XPos:=(RESOL_W - XPos) div 2;
   IHasSaves:=False;
   For GM:=Low(GM) to High(GM) do If (SaveExists[GM]) then IHasSaves:=True;
   Choice:=#$20;
   While (Choice = #32) do begin
      Sour.BeginFrame(); DrawTitle();
      Sour.SetFontScaling(Font,2); YPos:=TitleGfx^.H;
      Sour.PrintText('I - INTRODUCTION',Font,XPos,YPos,@WhiteColour);
         YPos+=Trunc(Font^.ChrH * 2 * Font^.Scale);
      If (GameOn) then Col:=@WhiteColour else Col:=@GreyColour;
      Sour.PrintText('C - CONTINUE',Font,XPos,YPos,Col);
         YPos+=Trunc(Font^.ChrH * 2 * Font^.Scale);
      Sour.PrintText('N - NEW GAME',Font,XPos,YPos,@WhiteColour);
         YPos+=Trunc(Font^.ChrH * 2 * Font^.Scale);
      If (IHasSaves) then Col:=@WhiteColour else Col:=@GreyColour;
      Sour.PrintText('L - LOAD GAME',Font,XPos,YPos,Col);
         YPos+=Trunc(Font^.ChrH * 2 * Font^.Scale);
      Sour.PrintText('B - BIND KEYS',Font,XPos,YPos,@WhiteColour);
         YPos+=Trunc(Font^.ChrH * 2 * Font^.Scale);
      Sour.PrintText('Q - QUIT',Font,XPos,YPos,@WhiteColour);
      Sour.FinishFrame();
      GetDeltaTime(dt);
      // Draw the title and menu
      While (SDL_PollEvent(@Ev)>0) do begin
            If (Ev.Type_ = SDL_QuitEv) then begin
               Shutdown:=True; Exit('Q') end else
            If (Ev.Type_ = SDL_KeyDown) then begin
               If (Ev.Key.Keysym.Sym = SDLK_ESCAPE) then Choice:='Q' else
               If (Ev.Key.Keysym.Sym = SDLK_Q) then Choice:='Q' else
               If (Ev.Key.Keysym.Sym = SDLK_I) then Choice:='I' else
               If (Ev.Key.Keysym.Sym = SDLK_N) then Choice:='N' else
               If (Ev.Key.Keysym.Sym = SDLK_C) then begin
                  If (GameOn) then Choice:='C' end else
               If (Ev.Key.Keysym.Sym = SDLK_L) then begin
                  If (IHasSaves) then Choice:='L' end else
               If (Ev.Key.Keysym.Sym = SDLK_B) then Choice:='B' else
               end else
            If (Ev.Type_ = SDL_VideoResize) then
               Shared.ResizeWindow(Ev.Resize.W,Ev.Resize.H,False) else
         end // Check SDL events
      end;
   Exit(Choice)
   end;

Procedure Outro();
   Var C:LongWord; YPos:LongWord;
   begin
   For C:=Low(SlideOut) to High(SlideOut) do
       If Not ShowSlide(SlideOut[C]) then Exit();
   While True do begin
      Sour.BeginFrame(); DrawTitle(); SetFontScaling(Font,2.0);
      Sour.PrintText([UpperCase(GAMENAME),'BY SUPER VEGETA','','A LUDUM DARE 25 GAME','','THANKS TO:','','DANIEL REMAR'],
                     Font,(RESOL_W div 2),TitleGfx^.H,ALIGN_CENTER);
      YPos:=TitleGfx^.H+Trunc(8*Font^.SpaY*Font^.Scale); Sour.SetFontScaling(Font,1.0);
      Sour.PrintText('FOR HERO CORE, WHICH THIS GAME WAS BASED UPON',Font,(RESOL_W div 2),YPos,Align_Center);
      Sour.SetFontScaling(Font,2.0); YPos+=Trunc((Font^.SpaY)+(Font^.SpaY*Font^.Scale));
      Sour.PrintText('DEXTERO',Font,(RESOL_W div 2),YPos,ALIGN_CENTER);
      YPos+=Trunc(Font^.SpaY*Font^.Scale); Sour.SetFontScaling(Font,1.0);
      Sour.PrintText(['FOR INTRODUCING ME TO LUDUM DARE','AND CHEERING ME UP DURING THE COMPO'],
                     Font,(RESOL_W div 2),YPos,ALIGN_CENTER);
      Sour.FinishFrame();
      GetDeltaTime(C);
      While (SDL_PollEvent(@Ev)>0) do begin
        If (Ev.Type_ = SDL_QuitEv) then begin
           Shutdown:=True; Exit() end else
        If (Ev.Type_ = SDL_KeyDown) then Exit() else
        If (Ev.Type_ = SDL_VideoResize) then
           Shared.ResizeWindow(Ev.Resize.W,Ev.Resize.H,False) else
        end
      end
   end;

Function Startup():Boolean;
   Var S:AnsiString; Timu:Comp; GM:TGameMode;
   begin
   Timu:=GetMSecs();
   SetPaths(); Randomize;
   If (IHasIni()) then begin
      Write('Loading configuration file... ');
      If (LoadIni())
         then Writeln('Success!')
         else begin Writeln('Failed! Using default settings.'); DefaultSettings() end;
      end else begin
      ConfigFiles.DefaultSettings();
      Writeln('Configuration file not found. Using default settings.')
      end;
   For GM:=Low(GM) to High(GM)
       do SaveExists[GM]:=IHasGame(GM);
   Write('Initializing BASS... ');
   If (Not BASS_Init(1,44100,0,0,NIL))
      then Writeln('Failed!') else Writeln('Success!');
   Write('Initializing SDL... ');
   If (SDL_Init(SDL_Init_Video or SDL_Init_Timer)<>0) then begin
      Writeln('Failed!'); Halt(1) end else Writeln('Success!');
   Sour.SetGLAttributes(8,8,8);
   Write('Opening window... ');
   If (Not Wnd_F)
      then Screen:=Sour.OpenWindow(Wnd_W,Wnd_H,SDL_RESIZABLE)
      else Screen:=Sour.OpenWindow(0,0,SDL_FullScreen);
   If (Screen=NIL) then begin
      Writeln('Failed!'); Halt(1) end else Writeln('Success!');
   S:=GAMENAME+' v.'+GAMEVERS;
   SDL_WM_SetCaption(PChar(S),PChar(S));
   Shared.SetResolution();
   Sour.SetClearColour(Sour.MakeColour($000000));
   Sour.NonPOT := True;
   Write('Loading basic resources... ');
   If Not Shared.LoadBasics(S) then begin
      Writeln('ERROR: ',S); Exit(False)
      end else Writeln('Success!');
   Write('Loading gameworld resources... ');
   If Not Shared.LoadRes(S,@LoadUpdate) then begin
      Writeln('ERROR: ',S); Exit(False);
      end else Writeln('Success!');
   SetLength(Mob,0); SetLength(EBul,0); SetLength(PBul,0); SetLength(Gib,0); Hero:=NIL;
   Writeln('All done! Initialization finished in ',((GetMSecs()-Timu)/1000):0:2,' second(s).');
   Exit(True)
   end;

Procedure NewGame_Turotial();
   begin
   GameMode:=GM_Tutorial; GameOn:=True;
   DestroyEntities(True); ResetGamestate();
   New(Hero,Create()); ChangeRoom(RespRoom[GM_Tutorial].X,RespRoom[GM_TUTORIAL].Y);
   end;

Procedure NewGame_Original();
   begin
   GameMode:=GM_ORIGINAL; GameOn:=True;
   DestroyEntities(True); ResetGamestate();
   New(Hero,Create()); ChangeRoom(RespRoom[GM_Original].X,RespRoom[GM_Original].Y);
   end;

Procedure DamageMob(X:LongWord;Power:Double);
   begin
   Mob[X]^.HP-=Power;
   If (Mob[X]^.HP <= 0) then begin
      If (Mob[X]^.SwitchNum >= 0) then Switch[Mob[X]^.SwitchNum]:=True;
      PlaceGibs(Mob[X]); PlaySfx(Mob[X]^.SfxID);
      Dispose(Mob[X],Destroy()); Mob[X]:=NIL
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

Function PlayableLulz():Boolean;
   Const TwoRoot = Sqrt(2);
         HPrect : Sour.TRect = (X: 0; Y:0; W:16; H:16);
         ColRect : Sour.TRect = (X: 16; Y:0; W:16; H:16);
         FPSRect : Sour.TRect = (X: 32; Y:0; W:16; H:16);
         VolRect : Sour.TRect = (X: 48; Y:0; W:16; H:16);
         PAUSETXT_W = (64 - 35 - 2); PAUSETXT_H = (32 - 7 - 2);
   Var Time,Ticks : LongWord; Q,Paused:Boolean; E:PEntity;
       XDif, YDif, ChkX, ChkY : Double;
       C, X, Y : LongInt;
       Src,Dst,Rect,PauseRect : Sour.TRect; Crd,PauseTxt : Sour.TCrd; Col:Sour.TColour;
       AniFra,FraTime,Frames:LongWord; FraStr:AnsiString;
       {$IFDEF DEVELOPER} debugY,debugU,debugI:Boolean; {$ENDIF}
   begin
   GetDeltaTime(Time); Q:=False; FraTime:=0; Frames:=0; FraStr:='???';
   Src.W:=TILE_W; Src.H:=TILE_H; Dst.W:=TILE_W; Dst.H:=TILE_H;
   PauseRect:=Sour.MakeRect(((RESOL_W - 64) div 2),((RESOL_H - 32) div 2),64,32);
   PauseTxt.X:=PAUSETXT_W div 2; PauseTxt.Y:=PAUSETXT_H div 2;
   Sour.SetFontScaling(Font,1); Paused:=False;
   {$IFDEF DEVELOPER} debugY:=False; debugU:=False; debugI:=False; {$ENDIF}
   Repeat
      GetDeltaTime(Time, Ticks);

      {$IFNDEF DEVELOPER}
      AniFra:=(Ticks div AnimTime) mod 2;
      {$ELSE}
      If (Not debugY) then AniFra:=(Ticks div AnimTime) mod 2
                      else AniFra:=0;
      {$ENDIF}

      While (SDL_PollEvent(@Ev)>0) do begin
         If (Ev.Type_ = SDL_QuitEv) then begin
            Shutdown:=True; Q:=True end else
         If (Ev.Type_ = SDL_KeyDown) then begin
            If (Ev.Key.Keysym.Sym = SDLK_Escape) then Q:=True else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_Up]        ) then Key[KEY_UP   ]     :=True else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_RIGHT]     ) then Key[KEY_RIGHT]     :=True else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_DOWN]      ) then Key[KEY_DOWN ]     :=True else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_LEFT]      ) then Key[KEY_LEFT]      :=True else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_ShootLeft] ) then Key[KEY_ShootLeft] :=True else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_ShootRight]) then Key[KEY_ShootRight]:=True else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_VolDown]) then ChgVol(-1) else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_VolUp])   then ChgVol(+1) else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_Pause])   then Paused:=(Not Paused) else
            {$IFDEF DEVELOPER}
            If (Ev.Key.Keysym.Sym = SDLK_H) then begin If (DeadTime <= 0) then Hero^.HP:=Hero^.MaxHP end else
            If (Ev.Key.Keysym.Sym = SDLK_U) then debugU:=(Not debugU) else
            If (Ev.Key.Keysym.Sym = SDLK_I) then debugI:=(Not debugI) else
            If (Ev.Key.Keysym.Sym = SDLK_Y) then debugY:=(Not debugY) else
            {$ENDIF}
            end else
         If (Ev.Type_ = SDL_KeyUp) then begin
            If (Ev.Key.Keysym.Sym = KeyBind[Key_Up]        ) then Key[KEY_UP   ]     :=False else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_RIGHT]     ) then Key[KEY_RIGHT]     :=False else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_DOWN]      ) then Key[KEY_DOWN ]     :=False else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_LEFT]      ) then Key[KEY_LEFT]      :=False else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_ShootLeft] ) then Key[KEY_ShootLeft] :=False else
            If (Ev.Key.Keysym.Sym = KeyBind[Key_ShootRight]) then Key[KEY_ShootRight]:=False else
            end else
         If (Ev.Type_ = SDL_VideoResize) then begin
            Shared.ResizeWindow(Ev.Resize.W,Ev.Resize.H,False);
            Paused:=True
            end else
         If (Ev.Type_ = SDL_ActiveEvent) then begin
            If (Ev.Active.State <> SDL_APPMOUSEFOCUS) and (Ev.Active.Gain = 0) then Paused:=True
            end else
         end;

      If (Not Paused) then begin // Looks ugly, but seriously, to indent everything beyond this point?

      If (Hero^.HP > 0) then begin
         Hero^.Calculate(Time);
         XDif:=Hero^.XVel*Time/1000; YDif:=Hero^.YVel*Time/1000;
         {$IFDEF DEVELOPER} If (Not debugI) then begin {$ENDIF}
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
         {$IFDEF DEVELOPER} end else begin Hero^.X:=Hero^.X+XDif; Hero^.Y:=Hero^.Y+YDif end {$ENDIF}
         end else begin
         If (DeadTime > 0) then DeadTime-=Time else begin
            ChangeRoom(RespRoom[GameMode].X,RespRoom[GameMode].Y);
            Hero^.mX:=RespPos[GameMode].X; Hero^.mY:=RespPos[GameMode].Y;
            Hero^.HP:=Hero^.MaxHP; Hero^.FireTimer:=0; Hero^.InvTimer:=0; Carried:=0;
            For C:=0 to 7 do If (ColState[C]=STATE_PICKED) then ColState[C]:=STATE_NONE;
            Write('Saving game upon death... '); If (SaveGame(GameMode)) then Writeln('Success!');
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
                 If (Given >= 8) then Q:=True else begin
                    Write('Saving game upon progress... '); If (SaveGame(GameMode)) then Writeln('Success!') end
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
                   Dispose(PBul[X],Destroy()); PBul[X]:=NIL; Continue end;
                If (Length(Mob)>0) then Y:=Low(Mob) else Y:=High(Y);
                While (Y<=High(Mob)) do begin
                   If (Mob[Y]=NIL) then begin Y+=1; Continue end;
                   If (Overlap(PBul[X],Mob[Y])) then begin
                      DamageMob(Y,PBul[X]^.Power);
                      Dispose(PBul[X],Destroy()); PBul[X]:=NIL;
                      Y:=High(Mob)*2
                      end else Y+=1
                   end
                end
         end;
      
      {$IFDEF DEVELOPER} If (Not debugY) then begin {$ENDIF}
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
                then begin DamageMob(X,9.5); DamagePlayer(9.5) end
             end;
      {$IFDEF DEVELOPER} end; {$ENDIF}

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
                   Dispose(EBul[X],Destroy()); EBul[X]:=NIL; Continue end;
                If (Hero^.HP > 0) and (Hero^.InvTimer <= 0) and (Overlap(EBul[X],Hero))
                   then begin DamagePlayer(EBul[X]^.Power);
                              Dispose(EBul[X],Destroy()); EBul[X]:=NIL end;
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
                Dispose(Gib[C],Destroy()); Gib[C]:=NIL end
             end;

      end; //This is the "If (Not Paused)" end.

      Sour.BeginFrame(); // Haha, time for ponies! I mean, time to draw.

      Src.X:=AniFra*TILE_W; // All tiles have the same size, no need to set this in the loop
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
      // Gibs have been drawn

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
         // Set drawing position
         If (Carried>0) then begin
            If (Random(5)<>0) then Col:=GreyColour else begin
               C:=Random(Carried)+1; X:=-1;
               Repeat X+=1;
                  If (ColState[X]=STATE_PICKED) then C-=1
                  Until (C = 0);
               Col:=PaletteColour[X]
               end
            end else Col:=GreyColour;
         // If hero is carrying a colour, randomly colourise the bastard
         Sour.DrawImage(Hero^.Gfx,@Rect,@Crd,@Col)
         end; // Hero drawn

      If (Crystal.IsSet) then begin
         Sour.SetRect(Src,AniFra*TILE_W,Crystal.Col*TILE_H,TILE_W,TILE_H);
         Sour.SetCrd(Crd,Crystal.mX*TILE_W,Crystal.mY*TILE_H);
         If (Crystal.Col <> WOMAN)
            then Sour.DrawImage(ColGfx,@Src,@Crd)
            else Sour.DrawImage(ColGfx,@Src,@Crd,@CentralPalette[Random(8)])
         end; // Colour artifact / woman drawn

      If (Length(FloatTxt)>0) then
         For C:=Low(FloatTxt) to High(FloatTxt) do
             If (FloatTxt[C]<>NIL) then
                Sour.PrintText(FloatTxt[C]^.Text,Font,FloatTxt[C]^.X,FloatTxt[C]^.Y,FloatTxt[C]^.Col);
      // Floating texts drawn (used mostly in the tutorial)

      {$IFDEF DEVELOPER} If Not (debugU) then begin {$ENDIF}
      Crd:=Sour.MakeCrd(0,0);
      Sour.DrawImage(UIgfx,@HPrect,@Crd);
      If (Hero^.HP > 0) then begin
         Sour.SetRect(Rect,3,9,1+Trunc(9*Hero^.HP/Hero^.MaxHP),4);
         If (Hero^.InvTimer <= 0)
            then Sour.FillRect(@Rect,@WhiteColour)
            else Sour.FillRect(@Rect,@GreyColour)
         end;
      // Drawn UI HP square

      Crd:=Sour.MakeCrd(RESOL_W-16,0);
      Sour.DrawImage(UIgfx,@ColRect,@Crd);
      For C:=0 to 7 do
          If (ColState[C]<>STATE_NONE) then begin
             Rect.X:=RESOL_W-14+((C mod 4)*3); If ((C mod 4)>1) then Rect.X+=1;
             Rect.Y:=09; If (C>=4) then Rect.Y+=3;
             If (ColState[C]=STATE_GIVEN)
                then begin
                Rect.W:=2; Rect.H:=2;
                Sour.FillRect(@Rect,UIcolour[C])
                end else begin
                Rect.W:=1; Rect.H:=1;
                Crd.X:=Rect.X; Crd.Y:=Rect.Y;
                Rect.X+=Random(2); Rect.Y+=Random(2);
                Sour.FillRect(@Rect,UIcolour[C]);
                Rect.X:=Crd.X+1-Random(2); Rect.Y:=Crd.Y+1-Random(2);
                Sour.FillRect(@Rect,UIcolour[C])
                end
             end;
      // Drawn UI colour square

      Crd:=Sour.MakeCrd(RESOL_W-16,RESOL_H-16);
      Sour.DrawImage(UIgfx,@FPSrect,@Crd);
      Sour.PrintText(FraStr,NumFont,(RESOL_W-8),(RESOL_H-7),ALIGN_CENTER);
      // Drawn UI FPS square

      Crd:=Sour.MakeCrd(0,RESOL_H-16);
      Sour.DrawImage(UIgfx,@VolRect,@Crd);
      For C:=GetVol() downto 1 do begin
         Rect.X:=(C*2); Rect.Y:=RESOL_H-2-C;
         Rect.W:=2; Rect.H:=C;
         Sour.FillRect(@Rect,@WhiteColour)
         end;
      // Drawn UI volume square

      If (Paused) then begin
         Sour.FillRect(@PauseRect,@WhiteColour);
         With PauseRect do begin X+=1; Y+=1; W-=2; H-=2 end;
         Sour.FillRect(@PauseRect,@BlackColour);
         Sour.PrintText('PAUSED',Font,PauseRect.X+PauseTxt.X,PauseRect.Y+PauseTxt.Y);
         With PauseRect do begin X-=1; Y-=1; W+=2; H+=2 end
         end;
      // Drawn Paused info-thingy

      {$IFDEF DEVELOPER} end; {$ENDIF}

      Sour.FinishFrame(); // Change OGL buffers, sending the current frame to video display.

      Frames+=1; FraTime+=Time;
      If (FraTime >= 1000) then begin
         If (Paused) then begin PauseTxt.X:=Random(PAUSETXT_W); PauseTxt.Y:=Random(PAUSETXT_H) end;
         WriteStr(FraStr,Frames);
         FraTime-=1000; Frames:=0
         end;
      // Count frames, duh

      until Q;
   Exit(Given >= 8)
   end;

begin
Writeln(GAMENAME,' by ',GAMEAUTH);
Writeln('v.',GAMEVERS,' (build ',GAMEDATE,')');
Writeln(StringOfChar('-',36));
Startup();
Repeat
   MenuChoice:=Menu();
   Case MenuChoice of
      'I': Intro();
      'C': PlayableLulz();
      'N': begin
           MenuChoice:=GameworldDialog(False);
           If (MenuChoice<>'Q') and (GameOn) then begin
              Write('Saving current game... ');
              If (SaveGame(GameMode)) then Writeln('Done.') end;
           Case MenuChoice of
              'T': begin NewGame_Turotial(); PlayableLulz() end;
              'N': begin NewGame_Original(); PlayableLulz() end;
              end;
           MenuChoice:='N'
           end;
      'L': begin
           MenuChoice:=GameworldDialog(True);
           If (MenuChoice<>'Q') and (GameOn) and
              ((MenuChoice='T') xor (GameMode=GM_TUTORIAL)) then begin
              Write('Saving current game... ');
              If (SaveGame(GameMode)) then Writeln('Done.') end;
           Case MenuChoice of
              'T': begin Write('Loading game... '); If LoadGame(GM_TUTORIAL) then begin
                         Writeln('Done.'); PlayableLulz() end end;
              'N': begin Write('Loading game... '); If LoadGame(GM_ORIGINAL) then begin
                         Writeln('Done.'); PlayableLulz() end end;
              end;
           MenuChoice:='L'
           end;
      'B': BindKeys();
      end;
   If (GameOn) and (GameMode <> GM_TUTORIAL) and (Given >= 8) then begin
      GameOn:=False; Outro() end;
   Until (MenuChoice = 'Q') or (Shutdown);
Write('Freeing resouces... '); Shared.Free(); Writeln('Done.');
Write('Closing BASS... '); BASS_Free(); Writeln('Done.');
Write('Closing SDL... '); SDL_Quit(); Writeln('Done.');
If (GameOn) then begin
   Write('Saving current game...');
   If (SaveGame(GameMode)) then Writeln('Done.') end;
Write('Saving configuration file... ');
If (SaveIni()) then Writeln('Done.');
end.

