(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2017 Artur Iwicki
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
Unit rooms;

{$INCLUDE defines.inc}

Interface
	uses SDL2, Shared;

Type
	TTile = (
		TILE_WALL,                       // Self-explanatory
		TILE_VBAR, TILE_VBUP, TILE_VBDO, // Vertical metal bar - whole, up-end, down-end
		TILE_HBAR, TILE_HBLE, TILE_HBRI, // Horizontal metal bar - whole, left-end, right-end
		TILE_CBAR,                       // Metal box
		TILE_VDOOR, TILE_HDOOR,          // Doors - vertical & horizontal 
		TILE_GENUP, TILE_GENDO,          // Generator "chassis"
		TILE_ZONE = 14, TILE_ROOM,            // Room borders (transfer zones)
		TILE_NONE                        // Empty tile
	);
Const
	TILE_NoCollide = TILE_ZONE;

Type
	PRoom = ^TRoom;
	TRoom = Object
		Private
			Function CollisionCheck(Const cX, cY:Double; Const OutsideVal:Boolean):Boolean;
			
		Public
			X, Y : uInt;
			Tile : Array[0..(ROOM_W-1), 0..(ROOM_H-1)] of TTile;
			TCol : Array[0..(ROOM_W-1), 0..(ROOM_H-1)] of PSDL_Colour;
			Scri : Array of AnsiString;

			Function  CollidesOrOutside(Const cX,cY:Double):Boolean;
			Function  Collides(Const cX,cY:Double):Boolean;
			Procedure HitSfx(Const cX,cY:Double);

			Procedure RunScript();
			Procedure SetTile(Const tX,tY:sInt; Const tT:Char);

			Constructor Create();
			Destructor Destroy;
	end;

Var OrgRoom:Array[0..(ORG_MAP_W-1), 0..(ORG_MAP_H-1)] of PRoom;
    TutRoom:Array[0..(TUT_MAP_W-1), 0..(TUT_MAP_H-1)] of PRoom;
    Room : PRoom;

Function LoadRoom(Name:AnsiString):PRoom;
Procedure FreeRooms();


Implementation
	uses FloatingText, SysUtils, StrUtils;

Procedure TRoom.RunScript();
Var
	C,P,tX,tY,Col:uInt; L:AnsiString; T:Array of AnsiString;
	EnemType : TEnemyType; ElseSrch,FiSrch:Boolean;
Begin
	If (Length(Scri) = 0) then Exit;
	
	ElseSrch:=False; FiSrch:=False;
	For C:=Low(Scri) to High(Scri) do begin
	
		// Tokenize the string
		SetLength(T,1); L:=Scri[C]; P:=Pos(#32,L);
		While (P<>0) do begin
			T[High(T)]:=LeftStr(L,P-1);
			SetLength(T,Length(T)+1);
			Delete(L,1,P); P:=Pos(#32,L)
		end;
		// Put the last part of the string (after last space) as last token
		T[High(T)]:=L;
		
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
					Continue
				end;
			
				If (T[1]='drone'    ) then EnemType:=ENEM_DRONE     else
				If (T[1]='basher'   ) then EnemType:=ENEM_basher    else
				If (T[1]='ball'     ) then EnemType:=ENEM_ball      else
				If (T[1]='spitter'  ) then EnemType:=ENEM_spitter   else
				If (T[1]='spammer'  ) then EnemType:=ENEM_spammer   else
				If (T[1]='generator') then EnemType:=ENEM_generator else
				If (T[1]='turret'   ) then EnemType:=ENEM_TURRET    else begin
					Writeln('Error in room ',X,':',Y,' at line ',C+21,
					': unknown spawn type "',T[1],'"');
					Continue
				end;
				
				If (Length(T)>=5) and (InRange(StrToInt(T[4]),Low(Switch),High(Switch)))
					then Shared.SpawnEnemy(EnemType,StrToInt(T[2])-1,StrToInt(T[3])-1,StrToInt(T[4]))
					else Shared.SpawnEnemy(EnemType,StrToInt(T[2])-1,StrToInt(T[3])-1);
			end else
			If (T[0]='tile') then begin
				If (Length(T)<3) then begin
					Writeln('Error in room ',X,':',Y,' at line ',C+21,
					': "tile" command requires at least two arguments.');
					Continue
				end;
				
				If (Length(T)>=4)
				then SetTile(StrToInt(T[1])-1,StrToInt(T[2])-1,T[3][1])
				else SetTile(StrToInt(T[1])-1,StrToInt(T[2])-1,#$20)
			end else
			If (T[0]='colour') then begin
				If (Length(T)<4) then begin
					Writeln('Error in room ',X,':',Y,' at line ',C+21,
					': "colour" command requires three arguments.');
					Continue
				end;

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
					Continue
				end;
			
				If (ColState[Crystal.Col]=STATE_NONE) then begin
					Crystal.mX:=StrToInt(T[2])-1; Crystal.mY:=StrToInt(T[3])-1;
					Crystal.IsSet:=True
				end
			end else
			If (T[0]='palette') then begin
				If (Length(T)<2) then begin
					Writeln('Error in room ',X,':',Y,' at line ',C+21,
					': "palette" command requires an argument.');
					Continue
				end;
				
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
					Continue
				end;
				
				If (Col<>8) then
					For tY:=0 to (ROOM_H-1) do For tX:=0 to (ROOM_W-1) do
						TCol[tX][tY]:=@PaletteColour[Col]
				else
					For tY:=0 to (ROOM_H-1) do For tX:=0 to (ROOM_W-1) do
						TCol[tX][tY]:=@CentralPalette[Random(8)];
				RoomPalette:=Col
			end else
			If (T[0]='text') then begin
				If (Length(T)<5) then begin
					Writeln('Error in room ',X,':',Y,' at line ',C+21,
					': "text" command at least four arguments.');
					Continue
				end;
				If (T[1]='black'  ) then Col:=0 else
				If (T[1]='navy'   ) then Col:=1 else
				If (T[1]='green'  ) then Col:=2 else
				If (T[1]='blue'   ) then Col:=3 else
				If (T[1]='red'    ) then Col:=4 else
				If (T[1]='purple' ) then Col:=5 else
				If (T[1]='yellow' ) then Col:=6 else
				If (T[1]='white'  ) then Col:=7 else
				If (T[1]='grey'   ) then Col:=8 else
				{else} begin
					Writeln('Error in room ',X,':',Y,' at line ',C+21,
					': unknown colour "',T[1],'".');
					Continue
				end;
				
				If (Length(T)>5) then
					For tX:=5 to High(T) do T[4]+=#$20+T[tX];
				AddFloatTxt(StrToInt(T[2]),StrToInt(T[3]),Col,T[4])
			end else
			If (T[0]='if') then begin
				If (Length(T)<2) then begin
					Writeln('Error in room ',X,':',Y,' at line ',C+21,
					': "if" with missing condition');
					FiSrch:=True; Continue
				end;
				If (Not InRange(StrToInt(T[1]),Low(Switch),High(Switch))) then begin
					Writeln('Error in room ',X,':',Y,' at line ',C+21,
					': switch of our range (',T[1],')');
					FiSrch:=True; Continue
				end;
				If Not ((Switch[StrToInt(T[1])]) xor ((Length(T)>=3) and (T[2]='not')))
				then ElseSrch:=True;
			end else
			If (T[0]='else') then FiSrch:=True else
			If (T[0]='fi') then else
			{else} Writeln('Error in room ',X,':',Y,' at line ',C+21,
				': unknown command "',T[0],'"');
		end // not else nor fi
	end // for every line (Scri)
End;

Procedure TRoom.SetTile(Const tX,tY:sInt; Const tT:Char);
Begin
	If (tX<0) or (tY<0) or (tX>=ROOM_W) or (tY>=ROOM_H) then Exit;
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
		'^': Tile[tX][tY]:=TILE_VBUP;
		'v': Tile[tX][tY]:=TILE_VBDO;
		'<': Tile[tX][tY]:=TILE_HBLE;
		'>': Tile[tX][tY]:=TILE_HBRI;
		else Tile[tX][tY]:=TILE_NONE;
	end
End;

Function TRoom.CollisionCheck(Const cX, cY:Double; Const OutsideVal:Boolean):Boolean;
Var 
	iX,iY:sInt;
Begin
	If (cX<0) or (cY<0) then Exit(OutsideVal);
	
	iX:=Trunc(cX / TILE_W); iY:=Trunc(cY / TILE_H);
	If (iX>=ROOM_W) or (iY>=ROOM_H) then Exit(OutsideVal);
	
	Exit(Tile[iX][iY] < TILE_NoCollide)
End;

Function TRoom.CollidesOrOutside(Const cX, cY:Double):Boolean;
Begin
	Exit(Self.CollisionCheck(cX, cY, True))
End;

Function TRoom.Collides(Const cX, cY:Double):Boolean;
Begin
	Exit(Self.CollisionCheck(cX, cY, False))
End;

Procedure TRoom.HitSfx(Const cX,cY:Double);
Var
	iX,iY:sInt;
Begin
	If (cX<0) or (cY<0) then Exit;
	
	iX:=Trunc(cX / TILE_W); iY:=Trunc(cY / TILE_H);
	If (iX>=ROOM_W) or (iY>=ROOM_H) then Exit;

	If (Tile[iX][iY]=TILE_WALL) then
		PlaySfx(SFX_WALL+Random(WALL_SFX))
	else
		PlaySfx(SFX_METAL+Random(METAL_SFX))
end;

Constructor TRoom.Create();
Begin
	SetLength(Scri,0)
end;

Destructor TRoom.Destroy();
Begin
	SetLength(Scri,0)
End;

Procedure FreeRooms();
Var X,Y:uInt;
Begin
	For Y:=0 to (ORG_MAP_H-1) do For X:=0 to (ORG_MAP_W-1) do
		If (OrgRoom[X][Y]<>NIL) then Dispose(OrgRoom[X][Y],Destroy());
	For Y:=0 to (TUT_MAP_H-1) do For X:=0 to (TUT_MAP_W-1) do
		If (TutRoom[X][Y]<>NIL) then Dispose(TutRoom[X][Y],Destroy());
End;

Function LoadRoom(Name:AnsiString):PRoom;
Var
	X,Y,C:uInt; R:PRoom; F:Text; L:AnsiString; T:Char;
Begin
	// Open file safely, bail out if failed to open
	Assign(F,Name); {$I-} Reset(F); {$I+}
	If (IOResult <> 0) then Exit(NIL);
	
	New(R,Create()); 
	For Y:=0 to (ROOM_H-1) do begin
		For X:=0 to (ROOM_W-1) do begin
			Read(F,T); R^.SetTile(X,Y,T);
			R^.TCol[X][Y]:=@WhiteColour;
		end;
		Readln(F)
	end;
	
	C:=0;
	While Not Eof(F) do begin
		Readln(F,L); L:=Trim(L);
		If (Length(L)>0) then begin
			SetLength(R^.Scri,C+1);
			R^.Scri[C]:=DelSpace1(L);
			C:=C+1
		end
	end;
	
	Close(F);
	Exit(R)
End;

End.
