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
		TILE_UNUSED1, TILE_UNUSED2,      // Maybe something in the future
		TILE_ZONE, TILE_ROOM,            // Room borders (transfer zones)
		TILE_NONE                        // Empty tile
	);
Const
	TILE_NoCollide = TILE_ZONE;

Type
	PRoom = ^TRoom;
	TRoom = Object
		Private
			Function CollisionCheck(Const cX, cY:Double; Const OutsideVal:Boolean):Boolean;
			
			Procedure Script_Colour(Const LineNo: sInt; Const Tokens:Array of AnsiString);
			Procedure Script_Palette(Const LineNo: sInt; Const Tokens:Array of AnsiString);
			Procedure Script_Spawn(Const LineNo: sInt; Const Tokens:Array of AnsiString);
			Procedure Script_Text(Const LineNo: sInt; Const Tokens:Array of AnsiString);
			Procedure Script_Tile(Const LineNo: sInt; Const Tokens:Array of AnsiString);
			
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

			Constructor Create(Var Stream:Text);
			Destructor Destroy;
	end;

Var
	OrgRoom:Array[0..(ORG_MAP_W-1), 0..(ORG_MAP_H-1)] of PRoom;
	TutRoom:Array[0..(TUT_MAP_W-1), 0..(TUT_MAP_H-1)] of PRoom;
	Room : PRoom;

Function LoadRoom(Const Name:AnsiString):PRoom;
Procedure FreeRooms();


Implementation
	uses FloatingText, SysUtils, StrUtils;

Procedure TRoom.Script_Colour(Const LineNo: sInt; Const Tokens: Array of AnsiString);
Begin
	If (Length(Tokens)<4) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "colour" command requires three arguments.'
		);
		Exit()
	end;

	Case(Tokens[1]) of
		'black':  Crystal.Col:=0;
		'navy':   Crystal.Col:=1;
		'green':  Crystal.Col:=2;
		'blue':   Crystal.Col:=3;
		'red':    Crystal.Col:=4;
		'purple': Crystal.Col:=5;
		'yellow': Crystal.Col:=6;
		'white':  Crystal.Col:=7;
		'woman':  Crystal.Col:=8;
		
		otherwise begin
			Writeln(
				'Error in room ',X,':',Y,' at line ',LineNo,
				': unknown crystal "',Tokens[1],'".'
			);
			Exit()
		end
	end;

	// Do not set crystal on the map if we're currently carrying it
	// or have already given it to the woman
	If (ColState[Crystal.Col]=STATE_NONE) then begin
		// Crystal spawn coords are 1-20 instead of 0-19, so we have to subtract 1
		Crystal.mX:=StrToInt(Tokens[2])-1; Crystal.mY:=StrToInt(Tokens[3])-1;
		Crystal.IsSet:=True
	end
End;

Procedure TRoom.Script_Palette(Const LineNo: sInt; Const Tokens: Array of AnsiString);
Var
	Colour, tX, tY: sInt;
Begin
	If (Length(Tokens)<2) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "palette" command requires an argument.'
		);
		Exit()
	end;
	
	Case(Tokens[1]) of
		'black':   Colour := 0;
		'navy':    Colour := 1;
		'green':   Colour := 2;
		'blue':    Colour := 3;
		'red':     Colour := 4;
		'purple':  Colour := 5;
		'yellow':  Colour := 6;
		'white':   Colour := 7;
		'central': Colour := 8;
		
		otherwise begin
			Writeln(
				'Error in room ',X,':',Y,' at line ',LineNo,
				': unknown colour "',Tokens[1],'".'
			);
			Exit()
		end
	end;
	
	// The "Central zone" palette is special as it randomizes the tile colours.
	If (Colour <> 8) then
		For tY:=0 to (ROOM_H-1) do For tX:=0 to (ROOM_W-1) do
			TCol[tX][tY]:=@PaletteColour[Colour]
	else
		For tY:=0 to (ROOM_H-1) do For tX:=0 to (ROOM_W-1) do
			TCol[tX][tY]:=@CentralPalette[Random(8)];
	
	Shared.RoomPalette := Colour
End;

Procedure TRoom.Script_Spawn(Const LineNo: sInt; Const Tokens: Array of AnsiString);
Var
	SpawnX, SpawnY: sInt;
	EnemType: TEnemyType;
Begin
	If (Length(Tokens)<4) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "spawn" command requires three arguments.'
		);
		Exit()
	end;

	Case(Tokens[1]) of
		'drone':     EnemType:=ENEM_DRONE;
		'basher':    EnemType:=ENEM_BASHER;
		'ball':      EnemType:=ENEM_BALL;
		'spitter':   EnemType:=ENEM_SPITTER;
		'spammer':   EnemType:=ENEM_SPAMMER;
		'generator': EnemType:=ENEM_GENERATOR;
		'turret':    EnemType:=ENEM_TURRET;
		
		otherwise begin
			Writeln(
				'Error in room ',X,':',Y,' at line ',LineNo,
				': unknown spawn type "',Tokens[1],'"'
			);
			Exit()
		end
	end;
	
	// Enemy spawn coords are 1-20 rather than 0-19, so we have to subtract 1
	SpawnX := StrToInt(Tokens[2]) - 1;
	SpawnY := StrToInt(Tokens[3]) - 1;
	
	// If there is a fifth token, use that as "flick this switch when enemy dies"
	If (Length(Tokens)>=5) and (InRange(StrToInt(Tokens[4]),Low(Switch),High(Switch))) then
		Shared.SpawnEnemy(EnemType, SpawnX, SpawnY, StrToInt(Tokens[4]))
	else
		Shared.SpawnEnemy(EnemType, SpawnX, SpawnY);
End;

Procedure TRoom.Script_Text(Const LineNo: sInt; Const Tokens: Array of AnsiString);
Var
	Colour, tk: sInt;
	Text: AnsiString;
Begin
	If (Length(Tokens)<5) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "text" command at least four arguments.'
		);
		Exit()
	end;
	
	Case(Tokens[1]) of
		'black':  Colour := 0;
		'navy':   Colour := 1;
		'green':  Colour := 2;
		'blue':   Colour := 3;
		'red':    Colour := 4;
		'purple': Colour := 5;
		'yellow': Colour := 6;
		'white':  Colour := 7;
		'grey':   Colour := 8;
		
		otherwise begin
			Writeln(
				'Error in room ',X,':',Y,' at line ',LineNo,
				': unknown colour "',Tokens[1],'".'
			);
			Exit()
		end
	end;
	
	Text := Tokens[4];
	If (Length(Tokens)>5) then
		For tk:=5 to High(Tokens) do Text += ' ' + Tokens[tk];
	
	AddFloatTxt(StrToInt(Tokens[2]), StrToInt(Tokens[3]), Colour, Text)
End;

Procedure TRoom.Script_Tile(Const LineNo: sInt; Const Tokens: Array of AnsiString);
Var
	TileX, TileY: sInt;
	TileChar: Char;
Begin
	If (Length(Tokens)<3) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "tile" command requires at least two arguments.'
		);
		Exit()
	end;
	
	// Tile coords in script are 1-20 rather than 0-19, so we have to subtract 1
	TileX := StrToInt(Tokens[1]) - 1;
	TileY := StrToInt(Tokens[2]) - 1;
	
	// A command setting a tile to an empty tile will have less tokens than the others,
	// as the space (representing the empty tile) gets consumed during parsing. 
	If (Length(Tokens)>=4) then
		TileChar := Tokens[3][1]
	else
		TileChar := ' ';
	
	Self.SetTile(TileX, TileY, TileChar)
End;

Procedure TRoom.RunScript();
Const
	SCRIPT_OFFSET = 21;
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
				Self.Script_Spawn(SCRIPT_OFFSET + C, T)
			end else
			If (T[0]='tile') then begin
				Self.Script_Tile(SCRIPT_OFFSET + C, T)
			end else
			If (T[0]='colour') then begin
				Self.Script_Colour(SCRIPT_OFFSET + C, T)
			end else
			If (T[0]='palette') then begin
				Self.Script_Palette(SCRIPT_OFFSET + C, T)
			end else
			If (T[0]='text') then begin
				Self.Script_Text(SCRIPT_OFFSET + C, T)
			end else
			If (T[0]='if') then begin
				If (Length(T)<2) then begin
					Writeln('Error in room ',X,':',Y,' at line ',(SCRIPT_OFFSET + C),
					': "if" with missing condition');
					FiSrch:=True; Continue
				end;
				If (Not InRange(StrToInt(T[1]),Low(Switch),High(Switch))) then begin
					Writeln('Error in room ',X,':',Y,' at line ',(SCRIPT_OFFSET + C),
					': switch of our range (',T[1],')');
					FiSrch:=True; Continue
				end;
				If Not ((Switch[StrToInt(T[1])]) xor ((Length(T)>=3) and (T[2]='not')))
				then ElseSrch:=True;
			end else
			If (T[0]='else') then FiSrch:=True else
			If (T[0]='fi') then else
			{else} Writeln('Error in room ',X,':',Y,' at line ',(SCRIPT_OFFSET + C),
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

Constructor TRoom.Create(Var Stream:Text);
Var
	rx, ry, LineCount: sInt;
	TileChar: Char;
	Line: AnsiString;
Begin
	For rY:=0 to (ROOM_H-1) do begin
		For rX:=0 to (ROOM_W-1) do begin
			Read(Stream, TileChar);
			Self.SetTile(rX, rY, TileChar);
			Self.TCol[rX][rY] := @WhiteColour;
		end;
		Readln(Stream)
	end;
	
	LineCount := 0;
	While Not Eof(Stream) do begin
		Readln(Stream, Line); Line:=Trim(Line);
		If (Length(Line)>0) then begin
			SetLength(Self.Scri, LineCount+1);
			Self.Scri[LineCount]:=DelSpace1(Line); // Compress multiple spaces to single space
			LineCount += 1
		end
	end
end;

Destructor TRoom.Destroy();
Begin
	SetLength(Scri,0)
End;

Procedure FreeRooms();
Var
	X,Y:uInt;
Begin
	For Y:=0 to (ORG_MAP_H-1) do For X:=0 to (ORG_MAP_W-1) do
		If (OrgRoom[X][Y]<>NIL) then Dispose(OrgRoom[X][Y],Destroy());
	For Y:=0 to (TUT_MAP_H-1) do For X:=0 to (TUT_MAP_W-1) do
		If (TutRoom[X][Y]<>NIL) then Dispose(TutRoom[X][Y],Destroy());
End;

Function LoadRoom(Const Name:AnsiString):PRoom;
Var
	F:Text;
Begin
	// Open file safely, bail out if failed to open
	Assign(F,Name); {$I-} Reset(F); {$I+}
	If (IOResult <> 0) then Exit(NIL);
	
	New(Result, Create(F));
	Close(F)
End;

End.
