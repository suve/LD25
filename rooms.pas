unit rooms; {$MODE OBJFPC} {$COPERATORS ON} {$WRITEABLECONST OFF}

interface
   uses Sour, Shared;

Type  TTile = 0..16;
Const TILE_WALL  = 00; TILE_VBAR  = 01; TILE_HBAR  = 02; TILE_CBAR  = 03;
      TILE_VDOOR = 04; TILE_HDOOR = 05; TILE_GENUP = 06; TILE_GENDO = 07;
      TILE_ZONE  = 14; TILE_ROOM  = 15; TILE_NONE  = 16;
      TILE_NoCollide = 14;

Type PRoom = ^TRoom;
     TRoom = Object
     Public
       X, Y : LongWord;
       Tile : Array[0..(ROOM_W-1), 0..(ROOM_H-1)] of TTile;
       TCol : Array[0..(ROOM_W-1), 0..(ROOM_H-1)] of Sour.PColour;
       Scri : Array of AnsiString;

       Function  Collides(cX,cY:Double):Boolean;
       Procedure HitSfx(cX,cY:Double);

       Procedure RunScript();
       Procedure SetTile(tX,tY:LongInt;tT:Char);

       Constructor Create();
       Destructor Destroy;
     end;

Var GameRoom:Array[0..(MAP_W-1), 0..(MAP_H-1)] of PRoom;

implementation
   uses SysUtils, StrUtils;

Procedure TRoom.RunScript();
   Var C,P,tX,tY,Col:LongWord; L:AnsiString; T:Array of AnsiString;
       EnemType : TEnemyType; ElseSrch,FiSrch:Boolean;
   begin
   If (Length(Scri) = 0) then Exit;
   ElseSrch:=False; FiSrch:=False;
   For C:=Low(Scri) to High(Scri) do begin
       SetLength(T,1); L:=Scri[C]; P:=Pos(#32,L);
       While (P<>0) do begin
          T[High(T)]:=LeftStr(L,P-1);
          SetLength(T,Length(T)+1);
          Delete(L,1,P); P:=Pos(#32,L)
          end;
       T[High(T)]:=L;
       // The string has been tokenized! Let's process it, shall we?
       If (FiSrch) then begin
          If (T[0]='fi') then begin FiSrch:=False; ElseSrch:=False end
          end else
       If (ElseSrch) then begin
          If (T[0]='else') or (T[0]='fi') then ElseSrch:=False;
          end else begin
          If (T[0]='spawn') then begin
             If (Length(T)<4) then begin
                Writeln('Error in room ',X,':',Y,' at line ',C+21,
                        ': "spawn" command requires three arguments.');
                Continue end;
             If (T[1]='drone'    ) then EnemType:=ENEM_DRONE     else
             If (T[1]='basher'   ) then EnemType:=ENEM_basher    else
             If (T[1]='ball'     ) then EnemType:=ENEM_ball      else
             If (T[1]='spitter'  ) then EnemType:=ENEM_spitter   else
             If (T[1]='spammer'  ) then EnemType:=ENEM_spammer   else
             If (T[1]='generator') then EnemType:=ENEM_generator else
             If (T[1]='turret'   ) then EnemType:=ENEM_TURRET    else begin
                Writeln('Error in room ',X,':',Y,' at line ',C+21,
                        ': unknown spawn type "',T[1],'"');
                Continue end;
             If (Length(T)>=5) and (InRange(StrToInt(T[4]),Low(Switch),High(Switch)))
                then Shared.SpawnEnemy(EnemType,StrToInt(T[2])-1,StrToInt(T[3])-1,StrToInt(T[4]))
                else Shared.SpawnEnemy(EnemType,StrToInt(T[2])-1,StrToInt(T[3])-1);
             end else
          If (T[0]='tile') then begin
             If (Length(T)<3) then begin
                Writeln('Error in room ',X,':',Y,' at line ',C+21,
                        ': "tile" command requires at least two arguments.');
                Continue end;
             If (Length(T)>=4)
                then SetTile(StrToInt(T[1]),StrToInt(T[2]),T[3][1])
                else SetTile(StrToInt(T[1]),StrToInt(T[2]),#$20)
             end else
          If (T[0]='colour') then begin
             If (Length(T)<4) then begin
                Writeln('Error in room ',X,':',Y,' at line ',C+21,
                        ': "colour" command requires three arguments.');
                Continue end;
             If (T[1]='black' ) then Crystal.Col:=0 else
             If (T[1]='navy'  ) then Crystal.Col:=1 else
             If (T[1]='green' ) then Crystal.Col:=2 else
             If (T[1]='blue'  ) then Crystal.Col:=3 else
             If (T[1]='red'   ) then Crystal.Col:=4 else
             If (T[1]='purple') then Crystal.Col:=5 else
             If (T[1]='yellow') then Crystal.Col:=6 else
             If (T[1]='white' ) then Crystal.Col:=7 else
             If (T[1]='woman' ) then Crystal.Col:=8 else
                {else} begin
                Writeln('Error in room ',X,':',Y,' at line ',C+21,
                        ': unknown crystal "',T[1],'".');
                Continue end;
             If (ColState[Crystal.Col]=STATE_NONE) then begin
                Crystal.mX:=StrToInt(T[2])-1; Crystal.mY:=StrToInt(T[3])-1;
                Crystal.IsSet:=True
                end
             end else
          If (T[0]='palette') then begin
             If (Length(T)<2) then begin
                Writeln('Error in room ',X,':',Y,' at line ',C+21,
                        ': "palette" command requires an argument.');
                Continue end;
             If (T[1]='black'  ) then Col:=0 else
             If (T[1]='navy'   ) then Col:=1 else
             If (T[1]='green'  ) then Col:=2 else
             If (T[1]='blue'   ) then Col:=3 else
             If (T[1]='red'    ) then Col:=4 else
             If (T[1]='purple' ) then Col:=5 else
             If (T[1]='yellow' ) then Col:=6 else
             If (T[1]='white'  ) then Col:=7 else
             If (T[1]='central') then Col:=8 else
                {else} begin
                Writeln('Error in room ',X,':',Y,' at line ',C+21,
                        ': unknown colour "',T[1],'".');
                Continue end;
             If (Col<>8)
                then For tY:=0 to (ROOM_H-1) do For tX:=0 to (ROOM_W-1) do
                     TCol[tX][tY]:=@PaletteColour[Col]
                else For tY:=0 to (ROOM_H-1) do For tX:=0 to (ROOM_W-1) do
                     TCol[tX][tY]:=@CentralPalette[Random(8)];
             RoomPalette:=Col
             end else
          If (T[0]='if') then begin
             If (Length(T)<2) then begin
                Writeln('Error in room ',X,':',Y,' at line ',C+21,
                        ': "if" with missing condition');
                FiSrch:=True; Continue end;
             If (Not InRange(StrToInt(T[1]),Low(Switch),High(Switch))) then begin
                Writeln('Error in room ',X,':',Y,' at line ',C+21,
                        ': switch of our range (',T[1],')');
                FiSrch:=True; Continue end;
             If Not ((Switch[StrToInt(T[1])]) xor ((Length(T)>=3) and (T[2]='not')))
                then ElseSrch:=True;
             end else
          If (T[0]='else') then FiSrch:=True else
          If (T[0]='fi') then else
             {else} Writeln('Error in room ',X,':',Y,' at line ',C+21,
                            ': unknown command "',T[0],'"');
          end //not else nor fi
       end //for every line
   end;

Procedure TRoom.SetTile(tX,tY:LongInt;tT:Char);
   begin
   if (tX<0) or (tY<0) or (tX>=ROOM_W) or (tY>=ROOM_H) then Exit;
   Case tT of
      ' ': Tile[tX][tY]:=TILE_NONE;
      'X': Tile[tX][tY]:=TILE_WALL;
      '|': Tile[tX][tY]:=TILE_VBAR;
      '-': Tile[tX][tY]:=TILE_HBAR;
      '+': Tile[tX][tY]:=TILE_CBAR;
      'D': Tile[tX][tY]:=TILE_VDOOR;
      '=': Tile[tX][tY]:=TILE_HDOOR;
      '{': Tile[tX][tY]:=TILE_GENUP;
      '}': Tile[tX][tY]:=TILE_GENDO;
      '#': Tile[tX][tY]:=TILE_ZONE;
      ':': Tile[tX][tY]:=TILE_ROOM;
      end
   end;

Function TRoom.Collides(cX,cY:Double):Boolean;
   Var iX,iY:LongInt;
   begin
   If (cX<0) or (cX<0) then Exit(True);
   iX:=Trunc(cX / TILE_W); iY:=Trunc(cY / TILE_H);
   If (iX>=ROOM_W) or (iY>=ROOM_H) then Exit(True);
   Exit(Tile[iX][iY]<TILE_NoCollide)
   end;

Procedure TRoom.HitSfx(cX,cY:Double);
   Var iX,iY:LongInt;
   begin
   If (cX<0) or (cX<0) then Exit;
   iX:=Trunc(cX / TILE_W); iY:=Trunc(cY / TILE_H);
   If (iX>=ROOM_W) or (iY>=ROOM_H) then Exit;
   If (Tile[iX][iY]=TILE_WALL)
      then PlaySfx(SFX_WALL+Random(WALL_SFX))
      else PlaySfx(SFX_METAL+Random(METAL_SFX))
   end;

Constructor TRoom.Create();
   begin SetLength(Scri,0) end;

Destructor TRoom.Destroy();
   begin
   SetLength(Scri,0)
   end;

Procedure FreeRooms();
   Var X,Y:LongWord; R:PRoom;
   begin
   For Y:=0 to (Map_H-1) do For X:=0 to (MAP_W-1) do
       If (GameRoom[X][Y]<>NIL) then Dispose(GameRoom[X][Y],Destroy());
   end;

Procedure LoadRooms();
   Var mX,mY,X,Y,C:LongWord; R:PRoom; F:Text; L:AnsiString; T:Char;
   begin
   For mY:=0 to (MAP_H-1) do For mX:=0 to (MAP_W-1) do begin
       Assign(F,'map/'+IntToStr(mX)+'-'+IntToStr(mY)+'.txt');
       {$I-} Reset(F); {$I+}
       If (IOResult <> 0) then begin
          {Writeln('Unable to load room: ',mX,':',mY);} Continue
          end;
       New(R,Create());
       R^.X:=mX; R^.Y:=mY;
       For Y:=0 to (ROOM_H-1) do begin
           For X:=0 to (ROOM_W-1) do begin
               Read(F,T); R^.SetTile(X,Y,T);
               R^.TCol[X][Y]:=@WhiteColour;
               end;
           Readln(F)
           end;
       C:=0; // set counter to 0
       While Not Eof(F) do begin
          Readln(F,L); L:=Trim(L);
          If (Length(L)>0) then begin
             SetLength(R^.Scri,C+1);
             R^.Scri[C]:=DelSpace1(L);
             C:=C+1
             end
          end;
       Close(F);
       GameRoom[mX][mY]:=R
       end;
   end;

initialization
   LoadRooms();

finalization
   FreeRooms();

end.

