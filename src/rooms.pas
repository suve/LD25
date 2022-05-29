(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2022 suve (a.k.a. Artur Frenszek Iwicki)
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
		Private Const
			MAX_TEXT_SIZE = 128 - 3 * SizeOf(sInt);
		Private Type
			TRoomScriptOpcode = (
				RSOP_IF,
				RSOP_ELSE,
				RSOP_COLOUR,
				RSOP_PALETTE,
				RSOP_SPAWN,
				RSOP_TEXT,
				RSOP_TILE
			);
			
			TRoomScriptInstruction = record
				Case Opcode:TRoomScriptOpcode of
					RSOP_IF: (If_: record
						Negative: Boolean;
						SwitchNo: sInt;
						ElseJumpTo: sInt;
					end);
					
					RSOP_ELSE: (Else_: record
						JumpTo: sInt;
					end);
					
					RSOP_COLOUR: (Colour: record
						X, Y, Colour: sInt;
					end);
					
					RSOP_PALETTE: (Palette: record
						Colour: sInt;
					end);
					
					RSOP_SPAWN: (Spawn: record
						X, Y: sInt;
						EnemType: TEnemyType;
						SwitchNo: sInt
					end);
					
					RSOP_TEXT: (Text: record
						X, Y, Colour: sInt;
						Text: String[MAX_TEXT_SIZE];
					end);
					
					RSOP_TILE: (Tile: record
						X, Y: sInt;
						Tile: TTile;
					end);
				end;
			
			TAnsiStringArray = Array of AnsiString;
			PAnsiStringArray = ^TAnsiStringArray;
			
		Private
			Scri: Array of TRoomScriptInstruction;
			
			Function CollisionCheck(Const cX, cY:Double; Const OutsideVal:Boolean):Boolean;
			
			Procedure SetTile(Const tX,tY:sInt; Const tT:TTile);
			Procedure SetTile(Const tX,tY:sInt; Const tChr:Char);
			
			Function ParseScript_If(Const LineNo: sInt; Const Tokens:Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
			Function ParseScript_Colour(Const LineNo: sInt; Const Tokens:Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
			Function ParseScript_Palette(Const LineNo: sInt; Const Tokens:Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
			Function ParseScript_Spawn(Const LineNo: sInt; Const Tokens:Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
			Function ParseScript_Text(Const LineNo: sInt; Const Tokens:Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
			Function ParseScript_Tile(Const LineNo: sInt; Const Tokens:Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
			Procedure ParseScript(Var Stream:Text);
			
			Procedure RunScript_Colour(Const rsi: TRoomScriptInstruction);
			Procedure RunScript_Palette(Const rsi: TRoomScriptInstruction);
			Procedure RunScript_Spawn(Const rsi: TRoomScriptInstruction);
			Procedure RunScript_Text(Const rsi: TRoomScriptInstruction);
			Procedure RunScript_Tile(Const rsi: TRoomScriptInstruction);
			
			Procedure ParseTiles(Var Stream:Text);
			Procedure Tokenize(Const Line: AnsiString; Const Tokens:PAnsiStringArray);
			
		Public
			X, Y : uInt;
			Tile : Array[0..(ROOM_W-1), 0..(ROOM_H-1)] of TTile;
			TCol : Array[0..(ROOM_W-1), 0..(ROOM_H-1)] of PSDL_Colour;
			
			Function  CharToTile(Const tT:Char):TTile; Static;

			Function  CollidesOrOutside(Const cX,cY:Double):Boolean;
			Function  Collides(Const cX,cY:Double):Boolean;
			Procedure HitSfx(Const cX,cY:Double);

			Procedure RunScript();

			Constructor Create(Const rX, rY: sInt; Var Stream:Text);
			Destructor Destroy;
	end;

Var
	Room : PRoom;

Function LoadRoom(Const rX, rY: sInt; Const Name:AnsiString):PRoom;


Implementation
Uses
	StrUtils, SysUtils,
	Assets, Colours, FloatingText;

Function TRoom.ParseScript_If(Const LineNo: sInt; Const Tokens:Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
Var
	SwitchNo: sInt;
	Negative: Boolean;
Begin
	If(Length(Tokens)<2) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "if" command requires at least one argument.'
		);
		Exit(False)
	end;
	
	SwitchNo := StrToInt(Tokens[1]);
	If(Not InRange(SwitchNo, 0, SWITCHES-1)) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': switch number passed to "if" command is out of range ',
			'(expected 0 - ',(SWITCHES-1),', got ',SwitchNo,').'
		);
		Exit(False)
	end;
	
	Negative := False;
	If(Length(Tokens)>=3) then begin
		If(Tokens[2] <> 'not') then begin
			Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': second argument to "if" command must be either "not" or omitted.'
		);
		Exit(False)
		end;
		
		Negative := True
	end;
	
	rsi.Opcode := RSOP_IF;
	rsi.If_.SwitchNo := SwitchNo;
	rsi.If_.Negative := Negative;
	rsi.If_.ElseJumpTo := -1;
	Exit(True)
End;

Function TRoom.ParseScript_Colour(Const LineNo: sInt; Const Tokens: Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
Var
	CrystalColour: sInt;
Begin
	If (Length(Tokens)<>4) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "colour" command requires exactly three arguments.'
		);
		Exit(False)
	end;

	Case(Tokens[1]) of
		'black':  CrystalColour:=0;
		'navy':   CrystalColour:=1;
		'green':  CrystalColour:=2;
		'blue':   CrystalColour:=3;
		'red':    CrystalColour:=4;
		'purple': CrystalColour:=5;
		'yellow': CrystalColour:=6;
		'white':  CrystalColour:=7;
		'woman':  CrystalColour:=8;
		
		otherwise begin
			Writeln(
				'Error in room ',X,':',Y,' at line ',LineNo,
				': unknown crystal "',Tokens[1],'".'
			);
			Exit(False)
		end
	end;

	// Crystal spawn coords are 1-20 instead of 0-19, so we'll have to subtract 1
	rsi.Opcode := RSOP_COLOUR;
	rsi.Colour.X := StrToInt(Tokens[2])-1;
	rsi.Colour.Y := StrToInt(Tokens[3])-1;
	rsi.Colour.Colour := CrystalColour;
	Exit(True)
End;

Function TRoom.ParseScript_Palette(Const LineNo: sInt; Const Tokens: Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
Var
	Colour: sInt;
Begin
	If (Length(Tokens)<2) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "palette" command requires an argument.'
		);
		Exit(False)
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
			Exit(False)
		end
	end;
	
	rsi.Opcode := RSOP_PALETTE;
	rsi.Palette.Colour := Colour;
	Exit(True)
End;

Function TRoom.ParseScript_Spawn(Const LineNo: sInt; Const Tokens: Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
Var
	SwitchNo: sInt;
	EnemType: TEnemyType;
Begin
	If (Length(Tokens)<4) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "spawn" command requires at least three arguments.'
		);
		Exit(False)
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
			Exit(False)
		end
	end;
	
	// If there is a fifth token, use that as "flick this switch when enemy dies"
	If (Length(Tokens)>=5) then begin
		SwitchNo := StrToInt(Tokens[4]);
		If(Not InRange(SwitchNo, 0, SWITCHES-1)) then begin
			Writeln(
				'Error in room ',X,':',Y,' at line ',LineNo,
				': switch number passed to "spawn" command is out of range ',
				'(expected 0 - ',(SWITCHES-1),', got ',SwitchNo,').'
			);
			Exit(False)
		end
	end else
		SwitchNo := -1;
	
	// Enemy spawn coords are 1-20 rather than 0-19, so we'll have to subtract 1
	rsi.Opcode := RSOP_SPAWN;
	rsi.Spawn.X := StrToInt(Tokens[2]) - 1;
	rsi.Spawn.Y := StrToInt(Tokens[3]) - 1;
	rsi.Spawn.EnemType := EnemType;
	rsi.Spawn.SwitchNo := SwitchNo;
	Exit(True)
End;

Function TRoom.ParseScript_Text(Const LineNo: sInt; Const Tokens: Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
Var
	Colour, tk, TextLen: sInt;
	Text: AnsiString;
Begin
	If (Length(Tokens)<5) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "text" command requires at least four arguments.'
		);
		Exit(False)
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
			Exit(False)
		end
	end;
	
	Text := Tokens[4];
	If (Length(Tokens)>5) then
		For tk:=5 to High(Tokens) do Text += ' ' + Tokens[tk];
	
	TextLen := Length(Text);
	If(TextLen > (MAX_TEXT_SIZE-1)) then 
		TextLen := (MAX_TEXT_SIZE-1);
	
	
	// FloatText position is given in pixels, no need to convert from 1-20 to 0-19
	rsi.Opcode := RSOP_TEXT;
	rsi.Text.X := StrToInt(Tokens[2]);
	rsi.Text.Y := StrToInt(Tokens[3]);
	rsi.Text.Colour := Colour;
	rsi.Text.Text := Copy(Text, 1, 63);
	rsi.Text.Text[TextLen+1] := #0;
	Exit(True)
End;

Function TRoom.ParseScript_Tile(Const LineNo: sInt; Const Tokens: Array of AnsiString; Out rsi:TRoomScriptInstruction):Boolean;
Var
	TileChar: Char;
Begin
	If (Length(Tokens)<3) then begin
		Writeln(
			'Error in room ',X,':',Y,' at line ',LineNo,
			': "tile" command requires at least two arguments.'
		);
		Exit(False)
	end;
	
	// A command setting a tile to an empty tile will have less tokens than the others,
	// as the space (representing the empty tile) gets consumed during parsing. 
	If (Length(Tokens)>=4) then
		TileChar := Tokens[3][1]
	else
		TileChar := ' ';
	
	
	// Tile coords in script are 1-20 rather than 0-19, so we'll have to subtract 1
	rsi.Opcode := RSOP_TILE;
	rsi.Tile.X := StrToInt(Tokens[1]) - 1;
	rsi.Tile.Y := StrToInt(Tokens[2]) - 1;
	rsi.Tile.Tile := CharToTile(TileChar);
	Exit(True)
End;

Procedure TRoom.RunScript_Colour(Const rsi: TRoomScriptInstruction);
Begin
	// Do not set crystal on the map if we're currently carrying it
	// or have already given it to the woman
	If (ColState[rsi.Colour.Colour] <> STATE_NONE) then Exit();
	
	Crystal.mX := rsi.Colour.X; Crystal.mY := rsi.Colour.Y;
	Crystal.Col := rsi.Colour.Colour;
	Crystal.IsSet := True
End;

Procedure TRoom.RunScript_Palette(Const rsi: TRoomScriptInstruction);
Var
	tX, tY: sInt;
Begin
	// The "Central zone" palette is special as it randomizes the tile colours.
	If (rsi.Palette.Colour <> 8) then begin
		For tY:=0 to (ROOM_H-1) do For tX:=0 to (ROOM_W-1) do
			TCol[tX][tY]:=@PaletteColour[rsi.Palette.Colour]
	end else begin
		For tY:=0 to (ROOM_H-1) do For tX:=0 to (ROOM_W-1) do
			TCol[tX][tY]:=@CentralPalette[Random(8)];
	end;
	
	Shared.RoomPalette := rsi.Palette.Colour
End;

Procedure TRoom.RunScript_Spawn(Const rsi: TRoomScriptInstruction);
Begin
	If(rsi.Spawn.SwitchNo >= 0) then
		Shared.SpawnEnemy(rsi.Spawn.EnemType, rsi.Spawn.X, rsi.Spawn.Y, rsi.Spawn.SwitchNo)
	else
		Shared.SpawnEnemy(rsi.Spawn.EnemType, rsi.Spawn.X, rsi.Spawn.Y)
End;

Procedure TRoom.RunScript_Text(Const rsi: TRoomScriptInstruction);
Begin
	AddFloatTxt(rsi.Text.X, rsi.Text.Y, rsi.Text.Colour, rsi.Text.Text)
End;

Procedure TRoom.RunScript_Tile(Const rsi: TRoomScriptInstruction);
Begin
	Self.SetTile(rsi.Tile.X, rsi.Tile.Y, rsi.Tile.Tile)
End;

Procedure TRoom.RunScript();
Var
	Idx, Count: sInt;
	rsi: TRoomScriptInstruction;
	Condition: Boolean;
	{$IFDEF DEVELOPER}
		CondStr: AnsiString;
	{$ENDIF}
Begin
	{$IFDEF DEVELOPER}
		Writeln(StdErr, 'RoomScript(', Self.X, ',', Self.Y, ') --- BEGIN');
	{$ENDIF}

	Idx := 0;
	Count := Length(Scri);
	While((Idx >= 0) and (Idx < Count)) do begin
		{$IFDEF DEVELOPER}
			Writeln(StdErr, 'RoomScript: #', Shared.IntToStr(Idx, 2), ' ', Scri[Idx].Opcode);
		{$ENDIF}

		rsi := Scri[Idx];
		Idx += 1;

		Case(rsi.Opcode) of
			RSOP_IF: begin
				Condition := Shared.Switch[rsi.If_.SwitchNo];
				If(rsi.If_.Negative) then begin
					{$IFDEF DEVELOPER}
						WriteStr(CondStr, 'switchNo: ~', Shared.IntToStr(rsi.If_.SwitchNo, 2));
					{$ENDIF}
					Condition := Not Condition;
				end else begin
					{$IFDEF DEVELOPER}
						WriteStr(CondStr, 'switchNo: ', Shared.IntToStr(rsi.If_.SwitchNo, 2));
					{$ENDIF}
				end;
				
				If(Not Condition) then begin
					{$IFDEF DEVELOPER}
						Writeln(StdErr, 'RoomScript:     Condition not met (', CondStr, '); jumping to #', Shared.IntToStr(rsi.If_.ElseJumpTo, 2));
					{$ENDIF}
					Idx := rsi.If_.ElseJumpTo
				end else begin
					{$IFDEF DEVELOPER}
						Writeln(StdErr, 'RoomScript:     Condition satisfied (', CondStr, ')');
					{$ENDIF}
				end
			end;

			RSOP_ELSE: begin
				{$IFDEF DEVELOPER}
					Writeln(StdErr, 'RoomScript:     Jumping to ', rsi.Else_.JumpTo);
				{$ENDIF}
				Idx := rsi.Else_.JumpTo
			end;

			RSOP_COLOUR:  RunScript_Colour(rsi);
			RSOP_PALETTE: RunScript_Palette(rsi);
			RSOP_SPAWN:   RunScript_Spawn(rsi);
			RSOP_TEXT:    RunScript_Text(rsi);
			RSOP_TILE:    RunScript_Tile(rsi);
		end
	end;

	{$IFDEF DEVELOPER}
		Writeln(StdErr, 'RoomScript(', Self.X, ',', Self.Y, ') --- END');
	{$ENDIF}
End;

Function TRoom.CharToTile(Const tT:Char):TTile;
Begin
	Case tT of
		' ': Result:=TILE_NONE;
		'X': Result:=TILE_WALL;
		'|': Result:=TILE_VBAR;
		'-': Result:=TILE_HBAR;
		'+': Result:=TILE_CBAR;
		'D': Result:=TILE_VDOOR;
		'=': Result:=TILE_HDOOR;
		'{': Result:=TILE_GENUP;
		'}': Result:=TILE_GENDO;
		'#': Result:=TILE_ZONE;
		':': Result:=TILE_ROOM;
		'^': Result:=TILE_VBUP;
		'v': Result:=TILE_VBDO;
		'<': Result:=TILE_HBLE;
		'>': Result:=TILE_HBRI;
		else Result:=TILE_NONE;
	end
End;

Procedure TRoom.SetTile(Const tX,tY:sInt; Const tT:TTile);
Begin
	If (tX<0) or (tY<0) or (tX>=ROOM_W) or (tY>=ROOM_H) then Exit;
	Tile[tX][tY] := tT
End;

Procedure TRoom.SetTile(Const tX,tY:sInt; Const tChr:Char);
Begin
	Self.SetTile(tX, tY, Self.CharToTile(tChr))
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

Procedure TRoom.ParseTiles(Var Stream:Text);
Var
	rx, ry: sInt;
	Line: AnsiString;
Begin
	For rY:=0 to (ROOM_H-1) do begin
		Readln(Stream, Line);
		For rX:=0 to (ROOM_W-1) do begin
			Self.SetTile(rX, rY, Line[rX+1]);
			Self.TCol[rX][rY] := @WhiteColour;
		end
	end
End;

Procedure TRoom.Tokenize(Const Line: AnsiString; Const Tokens:PAnsiStringArray);
Var
	np, sp, tk: sInt;
Begin
	tk := 0;
	SetLength(Tokens^, 0);
	
	np := 1;
	While True do begin
		sp := PosEx(#32, Line, np);
		If(sp = 0) then Break;
		
		SetLength(Tokens^, tk+1);
		Tokens^[tk] := Copy(Line, np, sp-np);
		tk := tk + 1;
		
		np := sp+1
	end;
	If(np <= Length(Line)) then begin
		SetLength(Tokens^, tk+1);
		Tokens^[tk] := Copy(Line, np, Length(Line));
		tk := tk + 1
	end;
End;

Procedure TRoom.ParseScript(Var Stream:Text);
Const
	SCRIPT_OFFSET = 21;
	MAX_IF_NEST = 8;
Type
	TIfInfo = record
		IfLine, IfInstr: sInt;
		ElseLine, ElseInstr: sInt;
	end;
Var
	LineNo, LineCount: sInt;
	Line: AnsiString;
	Tokens: Array of AnsiString;
	
	IfStack: Array[1..MAX_IF_NEST] of TIfInfo;
	IfNest: sInt;
	
	Instruction: TRoomScriptInstruction;
	InstrOK: Boolean;
Begin
	IfNest := 0;
	LineNo := SCRIPT_OFFSET - 1;
	LineCount := 0;
	While Not Eof(Stream) do begin
		LineNo += 1;
		
		Readln(Stream, Line); Line:=Trim(Line);
		If (Length(Line) = 0) then Continue;
		
		// Oddly named function. Replaces multiple spaces with single spaces.
		Line := DelSpace1(Line);
		Tokenize(Line, @Tokens);
		
		Case(Tokens[0]) of
			'if': begin
				If(IfNest = MAX_IF_NEST) then begin
					Writeln(
						'Error in room ',X,':',Y,' at line ',LineNo,
						': conditionals ("if") can be nested up to ',MAX_IF_NEST,' times.'
					);
					InstrOK := False
				end else begin
					InstrOK := ParseScript_If(LineNo, Tokens, Instruction);
					If(InstrOK) then begin
						IfNest += 1;
						IfStack[IfNest].IfLine := LineNo;
						IfStack[IfNest].IfInstr := LineCount;
						IfStack[IfNest].ElseLine := -1;
						IfStack[IfNest].ElseInstr := -1;
					end
				end
			end;
			
			'else': begin
				If(IfNest = 0) then begin
					Writeln(
						'Error in room ',X,':',Y,' at line ',LineNo,
						': "else" without matching "if".'
					);
					InstrOK := False
				end else begin
					If(IfStack[IfNest].ElseLine >= 0) then begin
						Writeln(
							'Error in room ',X,':',Y,' at line ',LineNo,
							': a second "else" for "if".'
						);
						InstrOK := False
					end else begin
						InstrOK := True;
						Instruction.Opcode := RSOP_ELSE;
						
						IfStack[IfNest].ElseLine := LineNo;
						IfStack[IfNest].ElseInstr := LineCount;
					end
				end
			end;
			
			'fi': begin
				InstrOK := False;
				If(IfNest = 0) then begin
					Writeln(
						'Error in room ',X,':',Y,' at line ',LineNo,
						': "fi" outside of "if".'
					);
				end else begin
					If(IfStack[IfNest].ElseInstr >= 0) then begin
						Self.Scri[IfStack[IfNest].IfInstr].If_.ElseJumpTo := IfStack[IfNest].ElseInstr + 1;
						Self.Scri[IfStack[IfNest].ElseInstr].Else_.JumpTo := LineCount;
					end else
						Self.Scri[IfStack[IfNest].IfInstr].If_.ElseJumpTo := LineCount;
					
					IfNest -= 1
				end
			end;
			
			'colour': InstrOK := Self.ParseScript_Colour(LineNo, Tokens, Instruction);
			'palette': InstrOK := Self.ParseScript_Palette(LineNo, Tokens, Instruction);
			'spawn': InstrOK := Self.ParseScript_Spawn(LineNo, Tokens, Instruction);
			'text': InstrOK := Self.ParseScript_Text(LineNo, Tokens, Instruction);
			'tile': InstrOK := Self.ParseScript_Tile(LineNo, Tokens, Instruction);
			
			otherwise Writeln(
				'Error in room ', Self.X, ':' , Self.Y,' at line ', LineNo,
				': unknown command "', Tokens[0], '"'
			);
		end;
		
		If(InstrOK) then begin
			SetLength(Self.Scri, LineCount+1);
			Self.Scri[LineCount] := Instruction;
			LineCount += 1
		end
	end
end;

Constructor TRoom.Create(Const rX, rY: sInt; Var Stream:Text);
Begin
	Self.X := rX; Self.Y := rY;
	Self.ParseTiles(Stream);
	Self.ParseScript(Stream);
end;

Destructor TRoom.Destroy();
Begin
	SetLength(Scri,0)
End;

Function LoadRoom(Const rX, rY: sInt; Const Name:AnsiString):PRoom;
Var
	F:Text;
Begin
	// Open file safely, bail out if failed to open
	Assign(F,Name); {$I-} Reset(F); {$I+}
	If (IOResult <> 0) then Exit(NIL);
	
	New(Result, Create(rX, rY, F));
	Close(F)
End;

End.
