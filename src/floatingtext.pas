unit floatingtext; 

{$INCLUDE defines.inc}

interface
   uses Shared, Sour;

Type PFloatTxt = ^TFloatTxt;
     TFloatTxt = Object
     X, Y : LongInt;
     Col : Sour.PColour;
     Text : AnsiString;

     Constructor Create();
     Destructor Destroy();
     end;

Var FloatTxt:Array of PFloatTxt;

Procedure AddFloatTxt(X,Y,ColID:LongInt;Text:AnsiString);
Procedure FlushFloatTxt();

implementation
   uses SysUtils;

Procedure AddFloatTxt(X,Y,ColID:LongInt;Text:AnsiString);
   Var FT:PFloatTxt;
   begin
   SetLength(FloatTxt,Length(FloatTxt)+1);
   New(FT,Create());
   FT^.X:=X; FT^.Y:=Y; FT^.Text:=UpperCase(Text);
   If (ColID < 0) then FT^.Col:=NIL else
   If (ColID < 8) then FT^.Col:=@PaletteColour[ColID] else
   If (ColID = 8) then FT^.Col:=@GreyColour {else}
                  else FT^.Col:=NIL;
   FloatTxt[High(FloatTxt)]:=FT
   end;

Procedure FlushFloatTxt();
   Var C:LongWord;
   begin
   If (Length(FloatTxt)=0) then Exit;
   For C:=Low(FloatTxt) to High(FloatTxt) do
       If (FloatTxt[C]<>NIL) then Dispose(FloatTxt[C],Destroy());
   SetLength(FloatTxt,0)
   end;

Constructor TFloatTxt.Create();
   begin
   X:=0; Y:=0; Col:=NIL;
   Text:=''
   end;

Destructor TFloatTxt.Destroy();
   begin end;

end.

