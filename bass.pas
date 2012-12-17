{$IFDEF LINUX} {$INCLUDE bass-linux.pas} {$ELSE}
{$IFDEF WINDOWS} {$INCLUDE bass-win32.pas} {$ELSE}
{$FATAL Unknown platform!} {$ENDIF} {$ENDIF}
