program ld25; 

{$INCLUDE defines.inc}

uses SysUtils, Shared, SDL, Sour, GL, SDL_Mixer, Objects, FloatingText, configfiles, Game;


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
   Var K:TPlayerKey; NewBind:Array[TPlayerKey] of TSDLKey; dt:uInt; Finito,Bound:Boolean;
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
       YPos:uInt; Col:Sour.PColour; dt:uInt;
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
   Var Q:sInt; dt:uInt;
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
   Var C:uInt;
   begin
   For C:=Low(SlideIn) to High(SlideIn) do
       If (Not ShowSlide(SlideIn[C])) then Exit(False);
   If (Not ShowSlide(TitleGfx)) then Exit(False);
   Exit(True)
   end;

Function Menu():Char;
   Var Choice:Char; dt,XPos,YPos:uInt; Col:Sour.PColour; IHasSaves:Boolean; GM:TGameMode;
   begin
   XPos:=Length('I - INTRODUCTION');
   XPos:=((Font^.SpaX*(XPos-1))+Font^.ChrW)*2;
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
   Var C:uInt; YPos:uInt;
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
   Write('Initializing SDL video... ');
   If (SDL_Init(SDL_Init_Video or SDL_Init_Timer)<>0) then begin
      Writeln('Failed!'); Halt(1) end else Writeln('Success!');
   Write('Initializing SDL audio... ');
   If (SDL_InitSubSystem(SDL_Init_Audio)<>0) then begin
      Writeln('Failed!'); NoSound:=True end else Writeln('Success!');
   If (Not NoSound) then begin
      Write('Initializing SDL_mixer... ');
      If (Mix_OpenAudio(AUDIO_FREQ, AUDIO_TYPE, AUDIO_CHAN, AUDIO_CSIZ)<>0) then begin
         Writeln('Failed!'); NoSound:=True end else Writeln('Success!')
      end else Writeln('SDL audio init failed - skipping SDL_mixer init.');
   If (Not NoSound) then Mix_AllocateChannels(SFXCHANNELS);
   LoadAndSetWindowIcon();
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
      Writeln('ERROR'); Writeln(S); Exit(False)
      end else Writeln('Success!');
   Write('Loading gameworld resources... ');
   If Not Shared.LoadRes(S,@LoadUpdate) then begin
      Writeln('ERROR'); Writeln(S); Exit(False);
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

Procedure QuitProg();
   Var Timu:Comp;
   begin
   Timu:=GetMSecs();
   Write('Freeing resouces... '); Shared.Free(); Writeln('Done.');
   Write('Closing SDL_mixer... '); Mix_CloseAudio(); Writeln('Done.');
   Write('Closing SDL... '); SDL_Quit(); Writeln('Done.');
   If (GameOn) then begin
      Write('Saving current game...');
      If (SaveGame(GameMode)) then Writeln('Done.') end;
   Write('Saving configuration file... ');
   If (SaveIni()) then Writeln('Done.');
   Writeln('Finalization finished in ',((GetMSecs-Timu)/1000):0:2,' second(s).');
   Writeln('Thanks for playing and have a nice day!');
   end;

begin
Writeln(GAMENAME,' by ',GAMEAUTH);
Writeln('v.',GAMEVERS,' (build ',GAMEDATE,')');
Writeln(StringOfChar('-',36));
If (Not Startup()) Then Halt(255);
Repeat
   MenuChoice:=Menu();
   Case MenuChoice of
      'I': Intro();
      'C': PlayGame();
      'N': begin
           MenuChoice:=GameworldDialog(False);
           If (MenuChoice<>'Q') and (GameOn) then begin
              Write('Saving current game... ');
              If (SaveGame(GameMode)) then Writeln('Done.') end;
           Case MenuChoice of
              'T': begin NewGame_Turotial(); PlayGame() end;
              'N': begin NewGame_Original(); PlayGame() end;
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
                         Writeln('Done.'); PlayGame() end end;
              'N': begin Write('Loading game... '); If LoadGame(GM_ORIGINAL) then begin
                         Writeln('Done.'); PlayGame() end end;
              end;
           MenuChoice:='L'
           end;
      'B': BindKeys();
      end;
   If (GameOn) and (GameMode <> GM_TUTORIAL) and (Given >= 8) then begin
      GameOn:=False; Outro() end;
   Until (MenuChoice = 'Q') or (Shutdown);
QuitProg()
end.

