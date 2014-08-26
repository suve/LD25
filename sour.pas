(*              Sour by Super Vegeta               *
 *              veg [at]  svgames.pl               *
 *                                                 *
 *                v.1.2, 2012.12.26                *
 *                                                 *
 * Simple unit for doing some basic OpenGL drawing *
 * in place of SDL software blitting.              *
 *                                                 *
 * Visit svgames.pl or read the HTML documentation *
 * for any necessary information.                  *)

unit sour; //SDL-OpenGL Unsophisticated Rendering

{$MODE OBJFPC} {$COPERATORS ON} {$TYPEDADDRESS ON} {$MACRO ON}

interface

uses
  SysUtils, SDL, SDL_image, GL;

Var NonPOT : Boolean;
    // When turned to true, the unit will not resize textures (images)
    // from their original size to a Power-Of-Two size.
    // Initialization section sets it to FALSE.

Type
   GLtex = pGLuint;
   PSDL_Surface = SDL.PSDL_Surface;

   ENilPointer = Class(Exception);

   PImage = ^TImage;
   TImage = record
   Tex  : GLtex;
   W, H : LongWord;
   TexW, TexH : LongWord
   end;

   PRect = ^TRect;
   TRect = record
   X, Y : LongInt;
   W, H : LongWord
   end;

   PCrd = ^TCrd;
   TCrd = record
   X, Y : LongInt;
   end;

   PColour = ^TColour;
   TColour = record
   R, G, B, A : Byte
   end;

   PFont = ^TFont;
   TFont = record
   Img        : PImage;
   ChrW, ChrH : LongWord;
   Start      : LongWord;
   SpaX, SpaY : LongWord;
   Scale      : Double
   end;

   HorizontalAlign = (ALIGN_LEFT,ALIGN_CENTER,ALIGN_RIGHT);
   VerticalAlign = (ALIGN_TOP,ALIGN_MIDDLE,ALIGN_BOTTOM);

   MinFilter = (Min_NEAREST,Min_LINEAR,Min_NEAREST_MIPMAP_NEAREST,Min_LINEAR_MIPMAP_NEAREST,
                Min_NEAREST_MIPMAP_LINEAR,Min_LINEAR_MIPMAP_LINEAR);

   MagFilter = (Mag_NEAREST,Mag_LINEAR);

   {$DEFINE StrArr:=Array of AnsiString}

Procedure SetGLAttributes(R,G,B,DoubleBuf:LongWord);
Procedure SetGLAttributes(R,G,B:LongWord;DoubleBuf:Boolean = True);

Procedure SetClearColour(Col:TColour);
Procedure SetClearColour(Col:PColour);

Procedure SetVisibleArea(X,Y:LongInt;W,H:LongWord);
Procedure SetVisibleArea(Rect:PRect);

Procedure SetResolution(W,H:LongWord);

Function OpenWindow(W,H:LongWord;Attrib:LongWord = 0):PSDL_Surface;
Function ResizeWindow(W,H:LongWord;Attrib:LongWord = 0):PSDL_Surface;

Procedure SetFilters(MinFil:MinFilter;MagFil:MagFilter);
Procedure SetFilters(Fnt:PFont;MinFil:MinFilter;MagFil:MagFilter);
Procedure SetFilters(Img:PImage;MinFil:MinFilter;MagFil:MagFilter);

Procedure TexBind(Tex:GLtex); Inline;
Procedure TexUnbind; Inline;

Procedure TexEnable; Inline;
Procedure TexDisable; Inline;

Procedure BeginFrame; Inline;
Procedure FinishFrame; Inline;

Procedure SetClipRect(Rct:PRect;WndCrd:Boolean = FALSE);
Procedure SetClipRect(Rct:TRect;WndCrd:Boolean = FALSE);

Function LoadImage(Path:AnsiString):PImage;
Function LoadImage(Path:AnsiString;Col:LongWord):PImage;
Function LoadImage(Path:AnsiString;R,G,B:Byte):PImage;

Function ImageFromSurface(Surf:PSDL_Surface):PImage;
Function ImageFromSurface(Surf:PSDL_Surface;Col:LongWord):PImage;
Function ImageFromSurface(Surf:PSDL_Surface;R,G,B:Byte):PImage;

Function  LoadFont(Path:AnsiString;Col,ChrW,ChrH:LongWord;Strt:Char=#32):PFont;

Procedure SetFontSpacing(Fnt:PFont;XS,YS:LongWord);
Procedure SetFontScaling(Fnt:PFont;Scala:Double);

Procedure DrawImage(Img:PImage;Src:PRect;Col:PColour = NIL);
Procedure DrawImage(Img:PImage;Src:PRect;Dst:PCrd;Col:PColour = NIL);
Procedure DrawImage(Img:PImage;Src:PRect;Dst:PRect;Col:PColour = NIL);

Procedure DrawImgRot(Img:PImage;Src,Dst:PRect;Angle:Double;AliH:HorizontalAlign;AliV:VerticalAlign;Col:PColour=NIL);
Procedure DrawImgRot(Img:PImage;Src,Dst:PRect;Angle:Double;AliH:HorizontalAlign;Col:PColour=NIL);
Procedure DrawImgRot(Img:PImage;Src,Dst:PRect;Angle:Double;AliV:VerticalAlign;Col:PColour=NIL);
Procedure DrawImgRot(Img:PImage;Src,Dst:PRect;Angle:Double;Col:PColour=NIL);

Procedure DrawImgRot(Img:PImage;Src:PRect;Dst:PCrd;Angle:Double;AliH:HorizontalAlign;AliV:VerticalAlign;Col:PColour=NIL);
Procedure DrawImgRot(Img:PImage;Src:PRect;Dst:PCrd;Angle:Double;AliH:HorizontalAlign;Col:PColour=NIL);
Procedure DrawImgRot(Img:PImage;Src:PRect;Dst:PCrd;Angle:Double;AliV:VerticalAlign;Col:PColour=NIL);
Procedure DrawImgRot(Img:PImage;Src:PRect;Dst:PCrd;Angle:Double;Col:PColour=NIL);

Procedure PrintText(Txt:AnsiString;Fnt:PFont;X,Y:LongWord;AliH:HorizontalAlign;AliV:VerticalAlign;Col:PColour=NIL);
Procedure PrintText(Txt:AnsiString;Fnt:PFont;X,Y:LongWord;AliH:HorizontalAlign;Col:PColour=NIL);
Procedure PrintText(Txt:AnsiString;Fnt:PFont;X,Y:LongWord;AliV:VerticalAlign;Col:PColour=NIL);
Procedure PrintText(Txt:AnsiString;Fnt:PFont;X,Y:LongWord;Col:PColour=NIL);

Procedure PrintText(Txt:StrArr;Fnt:PFont;X,Y:LongWord;AliH:HorizontalAlign;AliV:VerticalAlign;Col:PColour=NIL);
Procedure PrintText(Txt:StrArr;Fnt:PFont;X,Y:LongWord;AliH:HorizontalAlign;Col:PColour=NIL);
Procedure PrintText(Txt:StrArr;Fnt:PFont;X,Y:LongWord;AliV:VerticalAlign;Col:PColour=NIL);
Procedure PrintText(Txt:StrArr;Fnt:PFont;X,Y:LongWord;Col:PColour=NIL);

Procedure TexRect(Rect:PRect;Img:Sour.PImage;Col:PColour;Scale:Double);
Procedure TexRect(Rect:PRect;Img:Sour.PImage;Scale:Double);
Procedure TexRect(Rect:PRect;Img:Sour.PImage;Col:PColour);
Procedure TexRect(Rect:PRect;Img:Sour.PImage);

Procedure FillRect(Rect:PRect;R,G,B:Byte;A:Byte=255);
Procedure FillRect(Rect:PRect;Col:PColour=NIL);
Procedure FillRect(Rect:PRect;Col:LongWord);
Procedure FillRect(Rect:PRect;Col:TColour);

Procedure SetCrd(Out Crd:TCrd;vX,vY:LongInt);
Procedure SetRect(Out Rect:TRect;vX,vY:LongInt;vW,vH:LongWord);
Procedure SetColour(Out Col:TColour;vR,vG,vB:Byte;vA:Byte=255);
Procedure SetColour(Out Col:TColour;RGB:LongWord;Alpha:Boolean=False);

Function MakeCrd(vX,vY:LongInt):TCrd;
Function MakeRect(vX,vY:LongInt;vW,vH:LongWord):TRect;
Function MakeColour(vR,vG,vB:Byte;vA:Byte=255):TColour;
Function MakeColour(Col:LongWord;Alpha:Boolean=False):TColour;

Function NewCrd(vX,vY:LongInt):PCrd;
Function NewRect(vX,vY:LongInt;vW,vH:LongWord):PRect;
Function NewColour(vR,vG,vB:Byte;vA:Byte=255):PColour;
Function NewColour(Col:LongWord;Alpha:Boolean=False):PColour;

Function RGBToCol(R,G,B:Byte):LongWord;
Function RGBAToCol(R,G,B:Byte;A:Byte=255):LongWord;

Procedure FreeImage(Img:PImage);
Procedure FreeFont(Fnt:PFont);

implementation
   uses Math;

Var MinF,MagF:LongInt;
    Visib : TRect;
    TexOn : Boolean;
    TexNum : GLtex;

Procedure SwapByteOrder(Var Col:LongWord);
   Var A,B,C:LongWord;
   begin
   C:=Col mod 256; B:=Col div 256;
   A:=B div 256; B:=B mod 256;
   Col:=(C shl 16) or (B shl 8) or (A)
   end;

Procedure SetGLAttributes(R,G,B,DoubleBuf:LongWord);
   begin
   SDL_GL_SETATTRIBUTE(SDL_GL_RED_SIZE, R);
   SDL_GL_SETATTRIBUTE(SDL_GL_GREEN_SIZE, G);
   SDL_GL_SETATTRIBUTE(SDL_GL_BLUE_SIZE, B);
   SDL_GL_SETATTRIBUTE(SDL_GL_DEPTH_SIZE, R+G+B);
   SDL_GL_SETATTRIBUTE(SDL_GL_DOUBLEBUFFER, DoubleBuf);
   end;

Procedure SetGLAttributes(R,G,B:LongWord;DoubleBuf:Boolean = True);
   Var D:LongWord;
   begin
   If DoubleBuf then D := 1 else D := 0;
   SetGLAttributes(R,G,B,D)
   end;

Procedure SetClearColour(Col:TColour);
   begin
   glCLEARCOLOR(Col.R/255, Col.G/255, Col.B/255, Col.A/255);
   end;

Procedure SetClearColour(Col:PColour);
   begin
   glCLEARCOLOR(Col^.R/255, Col^.G/255, Col^.B/255, Col^.A/255);
   end;

Procedure SetVisibleArea(X,Y:LongInt;W,H:LongWord);
   begin
   glMatrixMode(GL_PROJECTION); glLoadIdentity();
   glOrtho(X, W+X, H+Y, Y, -1, 1); glMatrixMode(GL_MODELVIEW);
   SetRect(Visib,X,Y,W,H)
   end;

Procedure SetVisibleArea(Rect:PRect);
   begin SetVisibleArea(Rect^.X,Rect^.Y,Rect^.W,Rect^.H) end;

Procedure SetResolution(W,H:LongWord);
   begin SetVisibleArea(0,0,W,H) end;

Procedure SetUpGL(W,H:LongWord);
   begin
   glCLEARCOLOR(0.0, 1.0, 0.0, 1.0);
   glVIEWPORT(0,0,W,H); 
   glMatrixMode(GL_PROJECTION); glPushMatrix(); SetResolution(W,H);
   glMatrixMode(GL_MODELVIEW); glPushMatrix(); glLoadIdentity();
   glEnable(GL_BLEND); glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
   end;

Procedure SetTexFilters(MinFil,MagFil:LongWord);
   begin MinF:=MinFil; MagF:=MagFil end;

Procedure TranslateFilters(Out Min,Mag:LongInt;MinFil:MinFilter;MagFil:MagFilter);
   begin
   Case MinFil of
                     Min_NEAREST: Min:=GL_NEAREST;
                      Min_LINEAR: Min:=GL_LINEAR;
      Min_NEAREST_MIPMAP_NEAREST: Min:=GL_NEAREST_MIPMAP_NEAREST;
       Min_LINEAR_MIPMAP_NEAREST: Min:=GL_LINEAR_MIPMAP_NEAREST;
       Min_NEAREST_MIPMAP_LINEAR: Min:=GL_NEAREST_MIPMAP_LINEAR;
        Min_LINEAR_MIPMAP_LINEAR: Min:=GL_LINEAR_MIPMAP_LINEAR;
      end; //MinFil end
   Case MagFil of
      Mag_NEAREST: Mag:=GL_NEAREST;
       Mag_LINEAR: Mag:=GL_LINEAR;
      end //MagFil end
   end;

Procedure SetFilters(MinFil:MinFilter;MagFil:MagFilter);
   begin
   TranslateFilters(MinF,MagF,MinFil,MagFil)
   end;

Procedure SetFilters(Img:PImage;MinFil:MinFilter;MagFil:MagFilter);
   Var Min,Mag:LongInt;
   begin
   TranslateFilters(Min,Mag,MinFil,MagFil);
   TexBind(Img^.Tex);
   glTEXPARAMETERi(GL_Texture_2D, GL_TEXTURE_MIN_FILTER, Min);
   glTEXPARAMETERi(GL_Texture_2D, GL_TEXTURE_MAG_FILTER, Mag)
   end;

Procedure SetFilters(Fnt:PFont;MinFil:MinFilter;MagFil:MagFilter);
   begin
   SetFilters(Fnt^.Img,MinFil,MagFil)
   end;

Function OpenWindow(W,H:LongWord;Attrib:LongWord = 0):PSDL_Surface;
   Var Srf:PSDL_Surface;
   begin
   Srf:=SDL_SetVideoMode(W,H,24,SDL_OpenGL or Attrib);
   If (Srf = NIL) then Exit(NIL);
   SetUpGL(W,H); Exit(Srf)
   end;

Function ResizeWindow(W,H:LongWord;Attrib:LongWord = 0):PSDL_Surface;
   Var Srf:PSDL_Surface;
   begin
   Srf:=SDL_GetVideoSurface;
   If (Srf<>NIL) then SDL_FreeSurface(Srf);
   Srf:=SDL_SetVideoMode(W,H,24,SDL_OpenGL or Attrib);
   glVIEWPORT(0,0,W,H); SetResolution(W,H);
   Exit(Srf)
   end;

Procedure TexBind(Tex:GLtex); Inline;
   begin
   If (TexNum^ = Tex^) then Exit;
   glBINDTEXTURE(GL_Texture_2D, Tex^);
   TexNum^ := Tex^
   end;

Procedure TexEnable; Inline;
   begin
   If TexOn then Exit;
   glENABLE(GL_TEXTURE_2D);
   TexOn:=True
   end;

Procedure TexDisable; Inline;
   begin
   If Not TexOn then Exit;
   glDISABLE(GL_TEXTURE_2D);
   TexOn:=False
   end;

Procedure TexUnbind; Inline;
   begin TexNum^ := 0 end;

Procedure BeginFrame; Inline;
   begin
   glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
   glLoadIdentity()
   end;

Procedure FinishFrame; Inline;
   begin
   SDL_GL_SwapBuffers()
   end;

Procedure SetClipRect(Rct:PRect;WndCrd:Boolean = FALSE);
   Var cX,cY,cW,cH:LongWord; Srf:PSDL_Surface;
   begin
   Srf:=SDL_GetVideoSurface; If (Srf=NIL) then Exit;
   If (Rct<>NIL) then begin
      cX:=Rct^.X; cY:=Rct^.Y; cW:=Rct^.W; cH:=Rct^.H;
      If (Not WndCrd) then begin
         cX:=((cX*Srf^.W)-Visib.X) div Visib.W; cW:=(cW*Srf^.W) div Visib.W;
         cY:=((cY*Srf^.H)-Visib.Y) div Visib.H; cH:=(cH*Srf^.H) div Visib.H
         end;
      glScissor(cX,cY,cW,cH);
      glEnable(GL_SCISSOR_TEST)
      end else glDisable(GL_SCISSOR_TEST)
   end;

Procedure SetClipRect(Rct:TRect;WndCrd:Boolean = FALSE);
   begin SetClipRect(@Rct,WndCrd) end;

Procedure GetTexSize(Var X,Y:LongWord);
   Var OldX,OldY:LongWord;
   begin
   OldX:=X; OldY:=Y;
   X:=1; While (X<OldX) do X*=2;
   Y:=1; While (Y<OldY) do Y*=2
   end;

Function SurfaceToTex(Surf:PSDL_Surface;Alpha:Boolean):GLtex;
   Var Tex:GLtex; BPP,ColourFormat:LongInt;
   begin
   New(Tex); glGENTEXTURES(1, Tex); TexBind(Tex);
   If Not Alpha
      then begin BPP:=3; ColourFormat:=GL_RGB  end
      else begin BPP:=GL_RGBA; ColourFormat:=GL_RGBA end;
   glPixelStorei(GL_UNPACK_ALIGNMENT,1);
   glTEXIMAGE2D(GL_Texture_2D, 0, BPP, Surf^.W, Surf^.H, 0,
                ColourFormat, GL_UNSIGNED_BYTE, Surf^.Pixels);
   glTEXPARAMETERi(GL_Texture_2D, GL_TEXTURE_MIN_FILTER, MinF);
   glTEXPARAMETERi(GL_Texture_2D, GL_TEXTURE_MAG_FILTER, MagF);
   Exit(Tex)
   end;

Function CreateImage(vTex:GLtex;vW,vH,vTexW,vTexH:LongWord):PImage;
   Var Img:PImage;
   begin
   New(Img);         Img^.Tex:=vTex;
   Img^.W:=vW;       Img^.H:=vH;
   Img^.TexW:=vTexW; Img^.TexH:=vTexH;
   Exit(Img)
   end;

Function ImageFromSurface(Surf: PSDL_Surface): PImage;
   Var Conv:PSDL_Surface; X,Y,TexW,TexH:LongWord; Tex:GLtex; Img:PImage;
       Src,Dst:PLongWord;
   begin
   TexW:=Surf^.W; TexH:=Surf^.H;
   If (Not NonPOT) then GetTexSize(TexW,TexH);
   If (Surf^.Format^.BytesPerPixel < 4)
      then begin
      Conv:=SDL_CreateRGBSurface(SDL_SWSurface,TexW,TexH,24,$FF,$FF00,$FF0000,0);
      SDL_BlitSurface(Surf,Nil,Conv,Nil);
      end else begin
      Conv:=SDL_CreateRGBSurface(SDL_SWSurface,TexW,TexH,32,$FF,$FF00,$FF0000,$FF000000);
      Src:=PLongWord(Surf^.Pixels); Dst:=PLongWord(Conv^.Pixels);
      Y:=0; While (Y<Surf^.H) do begin
         X:=0; While (X<Surf^.W) do begin
            Dst[Y*TexW+X]:=Src[Y*Surf^.W+X];
            X+=1 end;
         While (X<TexW) do begin
            Dst[Y*TexW+X]:=0;
            X+=1 end;
         Y+=1 end;
      While (Y<TexH) do begin
         For X:=0 to TexW-1 do Dst[Y*TexW+X]:=0;
         Y+=1 end
      end;
   Tex:=SurfaceToTex(Conv,Not (Surf^.Format^.BytesPerPixel < 4));
   Img:=CreateImage(Tex,Surf^.W,Surf^.H,TexW,TexH);
   SDL_FreeSurface(Conv);
   Exit(Img)
   end;

Function ImageFromSurface(Surf: PSDL_Surface; Col: LongWord): PImage;
   Var Conv:PSDL_Surface; TexW,TexH:LongWord; Tex:GLtex; Img:PImage;
       Pos,Len:LongWord; Pix:PLongWord;
   begin
   SwapByteOrder(Col);
   TexW:=Surf^.W; TexH:=Surf^.H;
   If (Not NonPOT) then GetTexSize(TexW,TexH);
   Conv:=SDL_CreateRGBSurface(SDL_SWSurface,TexW,TexH,32,$FF,$FF00,$FF0000,$FF000000);
   SDL_FillRect(Conv,Nil,Col);
   SDL_BlitSurface(Surf,Nil,Conv,Nil);
   SDL_LockSurface(Conv);
   Len:=(TexW*TexH)-1;
   Pix:=PLongWord(Conv^.Pixels);
   For Pos:=0 to Len do
      If ((Pix[Pos] mod $1000000)=Col)
          then Pix[Pos]:=(Pix[Pos] mod $1000000)
          else Pix[Pos]:=(Pix[Pos] + $FF000000);
   SDL_UnLockSurface(Conv);
   Tex:=SurfaceToTex(Conv,True);
   Img:=CreateImage(Tex,Surf^.W,Surf^.H,TexW,TexH);
   SDL_FreeSurface(Conv);
   Exit(Img)
   end;

Function ImageFromSurface(Surf:pSDL_Surface; R,G,B:Byte):PImage;
   Var Col:LongWord;
   begin
   Col:=(R shl 16) or (G shl 8) or (B);
   Exit(ImageFromSurface(Surf,Col))
   end;

Function LoadImage(Path:AnsiString; Col:LongWord): PImage;
   Var Load:PSDL_Surface; Img:PImage;
   begin
   Load:=IMG_Load(PChar(Path));
   If Load=NIL then Exit(Nil);
   Img:=ImageFromSurface(Load,Col);
   SDL_FreeSurface(Load);
   Exit(Img)
   end;

Function LoadImage(Path:AnsiString; R,G,B:Byte): PImage;
   Var Col:LongWord;
   begin
   Col:=(R shl 16) or (G shl 8) or (B);
   Exit(LoadImage(Path,Col))
   end;

Function LoadImage(Path:AnsiString): PImage;
   Var Load:PSDL_Surface; Img:PImage;
   begin
   Load:=IMG_Load(PChar(Path));
   If Load=NIL then Exit(Nil);
   Img:=ImageFromSurface(Load);
   SDL_FreeSurface(Load);
   Exit(Img)
   end;

Function LoadFont(Path: AnsiString; Col, ChrW, ChrH: LongWord;
                  Strt: Char=#32): PFont;
   Var Fnt:PFont; Img:PImage;
   begin
   Img:=LoadImage(Path,Col);
   If IMG=NIL then Exit(Nil);
   New(Fnt); Fnt^.Img:=Img;
   Fnt^.ChrW:=ChrW; Fnt^.ChrH:=ChrH;
   Fnt^.Start:=Ord(Strt);
   Fnt^.SpaX:=ChrW; Fnt^.SpaY:=ChrH;
   Fnt^.Scale:=1.0;
   Exit(Fnt)
   end;

Procedure SetFontSpacing(Fnt: PFont; XS, YS: LongWord);
   begin
   Fnt^.SpaX:=Fnt^.ChrW+XS;
   Fnt^.SpaY:=Fnt^.ChrH+YS
   end;

Procedure SetFontScaling(Fnt: PFont; Scala: Double);
   begin  Fnt^.Scale:=Scala end;

Procedure DrawImage(Tex:GLtex;
                    SrcXS,SrcXE,SrcYS,SrcYE:Double;
                    DstXS,DstXE,DstYS,DstYE:LongInt;
                    Col:PColour);
   begin
   TexEnable; TexBind(Tex);
   glBegin(GL_Quads);
     If Col=NIL then glColor4ub(255,255,255,255)
                else glColor4ub(Col^.R,Col^.G,Col^.B,Col^.A);
     glTexCoord2f(SrcXS,SrcYS);
     glVertex2i(DstXS,DstYS);
     glTexCoord2f(SrcXE,SrcYS);
     glVertex2i(DstXE,DstYS);
     glTexCoord2f(SrcXE,SrcYE);
     glVertex2i(DstXE,DstYE);
     glTexCoord2f(SrcXS,SrcYE);
     glVertex2i(DstXS,DstYE);
   glEnd()
   end;

Procedure DrawImage(Img: PImage; Src, Dst: PRect;Col:PColour = NIL);
   Var SrcXS,SrcXE,SrcYS,SrcYE:Double;
       DstXS,DstXE,DstYS,DstYE:LongInt;
   begin
   If (Dst=NIL) then Raise ENilPointer.Create('Sour.DrawImage: Dst cannot be NIL!');
      DstXS:=Dst^.X; DstXE:=DstXS+Dst^.W;
      DstYS:=Dst^.Y; DstYE:=DstYS+Dst^.H;
   If Src<>NIL then begin
      SrcXS:=Src^.X; SrcXE:=SrcXS+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=SrcYS+Src^.H
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H
      end;
   SrcXS:=SrcXS/Img^.TexW; SrcXE:=SrcXE/Img^.TexW;
   SrcYS:=SrcYS/Img^.TexH; SrcYE:=SrcYE/Img^.TexH;
   DrawImage(Img^.Tex,SrcXS,SrcXE,SrcYS,SrcYE,DstXS,DstXE,DstYS,DstYE,Col)
   end;

Procedure DrawImage(Img: PImage; Src: PRect; Dst: PCrd;Col:PColour = NIL);
   Var SrcXS,SrcXE,SrcYS,SrcYE:Double;
       DstXS,DstXE,DstYS,DstYE:LongInt;
   begin
   If (Dst=NIL) then Raise ENilPointer.Create('Sour.DrawImage: Dst cannot be NIL!');
      DstXS:=Dst^.X; DstYS:=Dst^.Y;
   If Src<>NIL then begin
      SrcXS:=Src^.X; SrcXE:=SrcXS+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=SrcYS+Src^.H;
      DstXE:=DstXS+Src^.W;
      DstYE:=DstYS+Src^.H
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H;
      DstXE:=DstXS+Img^.W;
      DstYE:=DstYS+Img^.H
      end;
   SrcXS:=SrcXS/Img^.TexW; SrcXE:=SrcXE/Img^.TexW;
   SrcYS:=SrcYS/Img^.TexH; SrcYE:=SrcYE/Img^.TexH;
   DrawImage(Img^.Tex,SrcXS,SrcXE,SrcYS,SrcYE,DstXS,DstXE,DstYS,DstYE,Col)
   end;

Procedure DrawImage(Img: PImage; Src: PRect;Col:PColour = NIL);
   Var SrcXS,SrcXE,SrcYS,SrcYE:Double;
       DstXS,DstXE,DstYS,DstYE:LongInt;
   begin
   DstXS:=0; DstYS:=0;
   If Src<>NIL then begin
      SrcXS:=Src^.X; SrcXE:=SrcXS+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=SrcYS+Src^.H;
      DstXE:=Src^.W;
      DstYE:=Src^.H
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H;
      DstXE:=Img^.W;
      DstYE:=Img^.H
      end;
   SrcXS:=SrcXS/Img^.TexW; SrcXE:=SrcXE/Img^.TexW;
   SrcYS:=SrcYS/Img^.TexH; SrcYE:=SrcYE/Img^.TexH;
   DrawImage(Img^.Tex,SrcXS,SrcXE,SrcYS,SrcYE,DstXS,DstXE,DstYS,DstYE,Col)
   end;

Procedure PrintText(Txt: AnsiString; Fnt: PFont; X, Y: LongWord;
                    AliH: HorizontalAlign; AliV:VerticalAlign;
                    Col: PColour=NIL);
   Var Pos:LongWord; Src,Dst:TRect;
   begin
   Src.W:=Fnt^.ChrW; Src.H:=Fnt^.ChrH; Src.Y:=0;
   Dst.W:=Trunc(Src.W*Fnt^.Scale); Dst.H:=Trunc(Src.H*Fnt^.Scale);
   If (AliH = ALIGN_LEFT)
      then Dst.X:=X
      else begin
      Dst.X:=Trunc(((Length(Txt)-1)*Fnt^.SpaX+Fnt^.ChrW)*Fnt^.Scale);
      If (AliH = ALIGN_CENTER)
         then Dst.X:=X-(Dst.X div 2)
         else Dst.X:=X-Dst.X+1
      end;
   If (AliV = ALIGN_TOP)
      then Dst.Y:=Y
      else begin
      Dst.Y:=Trunc(Fnt^.ChrH*Fnt^.Scale);
      If (AliV = ALIGN_MIDDLE)
         then Dst.Y:=Y-(Dst.Y div 2)
         else Dst.Y:=Y-Dst.Y+1
      end;
   For Pos:=1 to Length(Txt) do begin
       Src.X:=(Ord(Txt[Pos])-Fnt^.Start)*Src.W;
       DrawImage(Fnt^.Img,@Src,@Dst,Col);
       Dst.X:=Dst.X+Trunc(Fnt^.SpaX*Fnt^.Scale)
       end
   end;

Procedure PrintText(Txt: AnsiString; Fnt: PFont; X, Y: LongWord;
                    AliH: HorizontalAlign; Col: PColour=Nil);
   begin PrintText(Txt,Fnt,X,Y,AliH,ALIGN_TOP,Col) end;

Procedure PrintText(Txt: AnsiString; Fnt: PFont; X, Y: LongWord;
                    AliV: VerticalAlign; Col: PColour=Nil);
   begin PrintText(Txt,Fnt,X,Y,ALIGN_LEFT,AliV,Col) end;

Procedure PrintText(Txt: AnsiString; Fnt: PFont; X, Y: LongWord;
                    Col: PColour=Nil);
   begin PrintText(Txt,Fnt,X,Y,ALIGN_LEFT,ALIGN_TOP,Col) end;

Procedure PrintText(Txt: StrArr; Fnt: PFont; X, Y: LongWord;
                    AliH: HorizontalAlign; AliV:VerticalAlign;
                    Col: PColour=NIL);
   Var Pos,Line:LongWord; Src,Dst:TRect;
   begin
   Src.W:=Fnt^.ChrW; Src.H:=Fnt^.ChrH; Src.Y:=0;
   Dst.W:=Trunc(Src.W*Fnt^.Scale); Dst.H:=Trunc(Src.H*Fnt^.Scale);
   If (AliV = ALIGN_TOP)
      then Dst.Y:=Y
      else begin
      Dst.Y:=Trunc(((Length(Txt)-1)*Fnt^.SpaY+Fnt^.ChrH)*Fnt^.Scale);
      If (AliV = ALIGN_MIDDLE)
         then Dst.Y:=Y-(Dst.Y div 2)
         else Dst.Y:=Y-Dst.Y+1
      end;
   For Line:=Low(Txt) to High(Txt) do begin
       If (AliH = ALIGN_LEFT)
          then Dst.X:=X
          else begin
          Dst.X:=Trunc(((Length(Txt[Line])-1)*Fnt^.SpaX+Fnt^.ChrW)*Fnt^.Scale);
          If (AliH = ALIGN_CENTER)
             then Dst.X:=X-(Dst.X div 2)
             else Dst.X:=X-Dst.X+1
          end;
       For Pos:=1 to Length(Txt[Line]) do begin
           Src.X:=(Ord(Txt[Line][Pos])-Fnt^.Start)*Src.W;
           DrawImage(Fnt^.Img,@Src,@Dst,Col);
           Dst.X:=Dst.X+Trunc(Fnt^.SpaX*Fnt^.Scale)
           end;
       Dst.Y:=Dst.Y+Trunc(Fnt^.SpaY*Fnt^.Scale)
       end
   end;

Procedure PrintText(Txt: StrArr; Fnt: PFont; X, Y: LongWord;
                    AliH: HorizontalAlign; Col: PColour=Nil);
   begin PrintText(Txt,Fnt,X,Y,AliH,ALIGN_TOP,Col) end;

Procedure PrintText(Txt: StrArr; Fnt: PFont; X, Y: LongWord;
                    AliV: VerticalAlign; Col: PColour=Nil);
   begin PrintText(Txt,Fnt,X,Y,ALIGN_LEFT,AliV,Col) end;

Procedure PrintText(Txt: StrArr; Fnt: PFont; X, Y: LongWord;
                    Col: PColour=Nil);
   begin PrintText(Txt,Fnt,X,Y,ALIGN_LEFT,ALIGN_TOP,Col) end;

Procedure TexRect(Rect: PRect; Img: Sour.PImage; Col:PColour; Scale: Double);
   Var XS,YS,XE,YE:LongInt; RX,RY:Double;
   begin
   If Rect<>NIL then begin
      XS:=Rect^.X; XE:=Rect^.X+Rect^.W;
      YS:=Rect^.Y; YE:=Rect^.Y+Rect^.H
      end else begin
      XS:=Visib.X; XE:=Visib.X+Visib.W;
      YS:=Visib.Y; YE:=Visib.Y+Visib.H
      end;
   RX:=(XE-XS) / (Img^.W*Scale);
   RY:=(YE-YS) / (Img^.H*Scale);
   TexEnable; TexBind(Img^.Tex);
   glBegin(GL_Quads);
     If Col=NIL then glColor4ub(255,255,255,255)
                else glColor4ub(Col^.R,Col^.G,Col^.B,Col^.A);
     glTexCoord2f(0,0);
     glVertex2i(XS,YS);
     glTexCoord2f(RX,0);
     glVertex2i(XE,YS);
     glTexCoord2f(RX,RY);
     glVertex2i(XE,YE);
     glTexCoord2f(0,RY);
     glVertex2i(XS,YE);
   glEnd()
   end;

Procedure TexRect(Rect:PRect;Img:Sour.PImage;Scale:Double);
   begin TexRect(Rect,Img,NIL,Scale) end;

Procedure TexRect(Rect:PRect;Img:Sour.PImage;Col:PColour);
   begin TexRect(Rect,Img,Col,1) end;

Procedure TexRect(Rect:PRect;Img:Sour.PImage);
   begin TexRect(Rect,Img,NIL,1) end;

Procedure FillRect(Rect: PRect; R,G,B:Byte; A:Byte=255);
   Var XS,YS,XE,YE:LongWord;
   begin
   If Rect<>NIL then begin
      XS:=Rect^.X; XE:=Rect^.X+Rect^.W;
      YS:=Rect^.Y; YE:=Rect^.Y+Rect^.H
      end else begin
      XS:=Visib.X; XE:=Visib.X+Visib.W;
      YS:=Visib.Y; YE:=Visib.Y+Visib.H
      end;
   TexDisable;
   glBegin(GL_Quads);
     glColor4ub(R,G,B,A);
     glVertex2i(XS,YS);
     glVertex2i(XE,YS);
     glVertex2i(XE,YE);
     glVertex2i(XS,YE);
   glEnd()
   end;

Procedure FillRect(Rect: PRect; Col: PColour = nil);
   begin
   If Col<>NIL then FillRect(Rect,Col^.R,Col^.G,Col^.B,Col^.A)
               else FillRect(Rect,255,255,255,255)
   end;

Procedure FillRect(Rect:PRect;Col:LongWord);
   Var G,B,A:LongWord;
   begin
   A:=Col mod 256; Col:=Col div 256;
   B:=Col mod 256; Col:=Col div 256;
   G:=Col mod 256; Col:=Col div 256;
   FillRect(Rect,Col,G,B,A)
   end;

Procedure FillRect(Rect: PRect; Col: TColour);
   begin FillRect(Rect,Col.R,Col.G,Col.B,Col.A) end;

Procedure DrawImgRot(Img:PImage; SrcXS, SrcXE, SrcYS, SrcYE, dX, dY, dW, dH, Angle:Double;
                     AliH:HorizontalAlign; AliV:VerticalAlign; Col:PColour=Nil);
   Type TXY = record X,Y : Double end;
   Var Dist,RotSin,RotCos,Rot:Double;
       C:LongWord; Vert:Array[0..3] of TXY; BegX,BegY,fW,fH:Double;
   begin
   SrcXS:=SrcXS/Img^.TexW; SrcXE:=SrcXE/Img^.TexW;
   SrcYS:=SrcYS/Img^.TexH; SrcYE:=SrcYE/Img^.TexH;
   // ^ Calculate texture coordinates ^
   If (AliH = ALIGN_CENTER) then BegX:=dW/2 else
   If (AliH = ALIGN_LEFT)   then BegX:=0   else BegX:=dW;
   If (AliV = ALIGN_MIDDLE) then BegY:=dH/2 else
   If (AliV = ALIGN_TOP)    then BegY:=0   else BegY:=dH;
   With Vert[0] do begin X:=0;  Y:=0  end;
   With Vert[1] do begin X:=dW; Y:=0  end;
   With Vert[2] do begin X:=dW; Y:=dH end;
   With Vert[3] do begin X:=0;  Y:=dH end;
   For C:=0 to 3 do begin
       fW:=Vert[C].X-BegX; fH:=Vert[C].Y-BegY;
       Dist:=Sqrt((fW*fW)+(fH*fH));
       If (Dist > 0) then begin
          RotSin:=(fH/Dist); RotCos:=(fW/Dist);
          If (RotSin>0) then Rot:=ArcCos(RotCos)
                        else Rot:=2*Pi-ArcCos(RotCos)
          end else Rot:=0;
       Vert[C].X:=Trunc(DX+Dist*Cos(Angle+Rot));
       Vert[C].Y:=Trunc(DY+Dist*Sin(Angle+Rot));
       end;
   // ^ Calculate destination coords ^
   TexEnable; TexBind(Img^.Tex);
   glBegin(GL_Quads);
     If Col=NIL then glColor4ub(255,255,255,255)
                else glColor4ub(Col^.R,Col^.G,Col^.B,Col^.A);
     glTexCoord2f(SrcXS,SrcYS);
     glVertex2f(Vert[0].X,Vert[0].Y);
     glTexCoord2f(SrcXE,SrcYS);
     glVertex2f(Vert[1].X,Vert[1].Y);
     glTexCoord2f(SrcXE,SrcYE);
     glVertex2f(Vert[2].X,Vert[2].Y);
     glTexCoord2f(SrcXS,SrcYE);
     glVertex2f(Vert[3].X,Vert[3].Y);
   glEnd()
   end;

Procedure DrawImgRot(Img:PImage;Src:PRect;Dst:PCrd;Angle:Double;AliH:HorizontalAlign;AliV:VerticalAlign;Col:PColour=NIL);
   Var SrcXS, SrcXE, SrcYS, SrcYE, dW,dH:Double;
   begin 
   If (Dst=NIL) then Raise ENilPointer.Create('Sour.DrawImage: Dst cannot be NIL!');
   If (Src<>NIL) then begin
      SrcXS:=Src^.X; SrcXE:=Src^.X+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=Src^.Y+Src^.H;
      dW:=Src^.W; dH:=Src^.H 
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H;
      dW:=Img^.W; dH:=Img^.H
      end;
   DrawImgRot(Img,SrcXS,SrcXE,SrcYS,SrcYE,Dst^.X,Dst^.Y,dW,dH,Angle,AliH,ALIGN_MIDDLE,Col) 
   end;

Procedure DrawImgRot(Img:PImage;Src:PRect;Dst:PCrd;Angle:Double;AliH:HorizontalAlign;Col:PColour=NIL);
   Var SrcXS, SrcXE, SrcYS, SrcYE, dW,dH:Double;
   begin 
   If (Dst=NIL) then Raise ENilPointer.Create('Sour.DrawImage: Dst cannot be NIL!');
   If (Src<>NIL) then begin
      SrcXS:=Src^.X; SrcXE:=Src^.X+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=Src^.Y+Src^.H;
      dW:=Src^.W; dH:=Src^.H 
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H;
      dW:=Img^.W; dH:=Img^.H
      end;
   DrawImgRot(Img,SrcXS,SrcXE,SrcYS,SrcYE,Dst^.X,Dst^.Y,dW,dH,Angle,AliH,ALIGN_MIDDLE,Col)
   end;

Procedure DrawImgRot(Img:PImage;Src:PRect;Dst:PCrd;Angle:Double;AliV:VerticalAlign;Col:PColour=NIL);
   Var SrcXS, SrcXE, SrcYS, SrcYE, dW,dH:Double;
   begin 
   If (Dst=NIL) then Raise ENilPointer.Create('Sour.DrawImage: Dst cannot be NIL!');
   If (Src<>NIL) then begin
      SrcXS:=Src^.X; SrcXE:=Src^.X+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=Src^.Y+Src^.H;
      dW:=Src^.W; dH:=Src^.H 
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H;
      dW:=Img^.W; dH:=Img^.H
      end;
   DrawImgRot(Img,SrcXS,SrcXE,SrcYS,SrcYE,Dst^.X,Dst^.Y,dW,dH,Angle,ALIGN_CENTER,AliV,Col)
   end;

Procedure DrawImgRot(Img:PImage;Src:PRect;Dst:PCrd;Angle:Double;Col:PColour=NIL);
   Var SrcXS, SrcXE, SrcYS, SrcYE, dW,dH:Double;
   begin 
   If (Dst=NIL) then Raise ENilPointer.Create('Sour.DrawImage: Dst cannot be NIL!');
   If (Src<>NIL) then begin
      SrcXS:=Src^.X; SrcXE:=Src^.X+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=Src^.Y+Src^.H;
      dW:=Src^.W; dH:=Src^.H 
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H;
      dW:=Img^.W; dH:=Img^.H
      end;
   DrawImgRot(Img,SrcXS,SrcXE,SrcYS,SrcYE,Dst^.X,Dst^.Y,dW,dH,Angle,ALIGN_CENTER,ALIGN_MIDDLE,Col)
   end;

Procedure DrawImgRot(Img:PImage;Src,Dst:PRect;Angle:Double;AliH:HorizontalAlign;AliV:VerticalAlign;Col:PColour=NIL);
   Var SrcXS, SrcXE, SrcYS, SrcYE :Double;
   begin 
   If (Dst=NIL) then Raise ENilPointer.Create('Sour.DrawImage: Dst cannot be NIL!');
   If (Src<>NIL) then begin
      SrcXS:=Src^.X; SrcXE:=Src^.X+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=Src^.Y+Src^.H;
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H;
      end;
   DrawImgRot(Img,SrcXS,SrcXE,SrcYS,SrcYE,Dst^.X,Dst^.Y,Dst^.W,Dst^.H,Angle,AliH,AliV,Col)
   end;

Procedure DrawImgRot(Img:PImage;Src,Dst:PRect;Angle:Double;AliH:HorizontalAlign;Col:PColour=NIL);
   Var SrcXS, SrcXE, SrcYS, SrcYE :Double;
   begin 
   If (Dst=NIL) then Raise ENilPointer.Create('Sour.DrawImage: Dst cannot be NIL!');
   If (Src<>NIL) then begin
      SrcXS:=Src^.X; SrcXE:=Src^.X+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=Src^.Y+Src^.H;
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H;
      end;
   DrawImgRot(Img,SrcXS,SrcXE,SrcYS,SrcYE,Dst^.X,Dst^.Y,Dst^.W,Dst^.H,Angle,AliH,ALIGN_MIDDLE,Col)
   end;

Procedure DrawImgRot(Img:PImage;Src,Dst:PRect;Angle:Double;AliV:VerticalAlign;Col:PColour=NIL);
   Var SrcXS, SrcXE, SrcYS, SrcYE :Double;
   begin 
   If (Dst=NIL) then Raise ENilPointer.Create('Sour.DrawImage: Dst cannot be NIL!');
   If (Src<>NIL) then begin
      SrcXS:=Src^.X; SrcXE:=Src^.X+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=Src^.Y+Src^.H;
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H;
      end;
   DrawImgRot(Img,SrcXS,SrcXE,SrcYS,SrcYE,Dst^.X,Dst^.Y,Dst^.W,Dst^.H,Angle,ALIGN_CENTER,AliV,Col)
   end;

Procedure DrawImgRot(Img:PImage;Src,Dst:PRect;Angle:Double;Col:PColour=NIL);
   Var SrcXS, SrcXE, SrcYS, SrcYE :Double;
   begin 
   If (Dst=NIL) then Raise ENilPointer.Create('Sour.DrawImage: Dst cannot be NIL!');
   If (Src<>NIL) then begin
      SrcXS:=Src^.X; SrcXE:=Src^.X+Src^.W;
      SrcYS:=Src^.Y; SrcYE:=Src^.Y+Src^.H;
      end else begin
      SrcXS:=0; SrcXE:=Img^.W;
      SrcYS:=0; SrcYE:=Img^.H;
      end;
   DrawImgRot(Img,SrcXS,SrcXE,SrcYS,SrcYE,Dst^.X,Dst^.Y,Dst^.W,Dst^.H,Angle,ALIGN_CENTER,ALIGN_MIDDLE,Col)
   end;

Procedure SetCrd(Out Crd:TCrd;vX,vY:LongInt);
   begin Crd.X:=vX; Crd.Y:=vY end;

Procedure SetRect(Out Rect:TRect;vX,vY:LongInt;vW,vH:LongWord);
   begin Rect.X:=vX; Rect.Y:=vY; Rect.W:=vW; Rect.H:=vH end;

Procedure SetColour(Out Col:TColour;vR,vG,vB:Byte;vA:Byte=255);
   begin Col.R:=vR; Col.G:=vG; Col.B:=vB; Col.A:=vA end;

Procedure SetColour(Out Col:TColour;RGB:LongWord;Alpha:Boolean=False);
   begin
   If Alpha then begin
      Col.A:=RGB mod 256; RGB:=RGB div 256
      end else Col.A:=255;
   Col.B:=RGB mod 256; RGB:=RGB div 256;
   Col.G:=RGB mod 256; RGB:=RGB div 256;
   Col.R:=RGB mod 256
   end;

Function MakeCrd(vX,vY:LongInt):TCrd;
   Var Crd:TCrd;
   begin
   Crd.X:=vX; Crd.Y:=vY;
   Exit(Crd)
   end;

Function MakeRect(vX,vY:LongInt;vW,vH:LongWord):TRect;
   Var Rect:TRect;
   begin
   Rect.X:=vX; Rect.Y:=vY;
   Rect.W:=vW; Rect.H:=vH;
   Exit(Rect)
   end;

Function MakeColour(vR,vG,vB:Byte;vA:Byte=255):TColour;
   Var Col:TColour;
   begin
   Col.R:=vR; Col.G:=vG;
   Col.B:=vB; Col.A:=vA;
   Exit(Col)
   end;

Function MakeColour(Col:LongWord;Alpha:Boolean=False):TColour;
   Var Res:TColour;
   begin
   If Alpha then begin
      Res.A:=Col mod 256; Col:=Col div 256
      end else Res.A:=255;
   Res.B:=Col mod 256; Col:=Col div 256;
   Res.G:=Col mod 256; Col:=Col div 256;
   Res.R:=Col mod 256;
   Exit(Res)
   end;

Function NewCrd(vX,vY:LongInt):PCrd;
   Var Crd:PCrd;
   begin
   New(Crd);
   Crd^.X:=vX; Crd^.Y:=vY;
   Exit(Crd)
   end;

Function NewRect(vX,vY:LongInt;vW,vH:LongWord):PRect;
   Var Rect:PRect;
   begin
   New(Rect);
   Rect^.X:=vX; Rect^.Y:=vY;
   Rect^.W:=vW; Rect^.H:=vH;
   Exit(Rect)
   end;

Function NewColour(vR,vG,vB:Byte;vA:Byte=255):PColour;
   Var Col:PColour;
   begin
   New(Col);
   Col^.R:=vR; Col^.G:=vG;
   Col^.B:=vB; Col^.A:=vA;
   Exit(Col)
   end;

Function NewColour(Col:LongWord;Alpha:Boolean=False):PColour;
   Var Res:PColour;
   begin
   New(Res);
   If Alpha then begin
      Res^.A:=Col mod 256; Col:=Col div 256
      end else Res^.A:=255;
   Res^.B:=Col mod 256; Col:=Col div 256;
   Res^.G:=Col mod 256; Col:=Col div 256;
   Res^.R:=Col mod 256;
   Exit(Res)
   end;

Function RGBToCol(R,G,B:Byte):LongWord;
   begin Exit((R shl 16) or (G shl 8) or (B)) end;

Function RGBAToCol(R,G,B:Byte;A:Byte=255):LongWord;
   begin Exit((R shl 24) or (G shl 16) or (B shl 8) or (A)) end;

Procedure FreeImage(Img:PImage);
   begin
   If (TexNum^ = Img^.Tex^) then TexUnbind();
   glDeleteTextures(1, Img^.Tex);
   Dispose(Img^.Tex);
   Dispose(Img)
   end;

Procedure FreeFont(Fnt:PFont);
   begin
   FreeImage(Fnt^.Img);
   Dispose(Fnt)
   end;

Initialization
   SetRect(Visib,0,0,0,0);
   MinF := GL_NEAREST; MagF:=GL_NEAREST;
   TexOn := False; New(TexNum); TexNum^ := 0;
   NonPOT := False;

end.

