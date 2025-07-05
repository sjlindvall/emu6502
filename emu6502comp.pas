unit emu6502comp;

{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch arrayoperators}

interface

uses
  SysUtils;

const
  MAX_MEM     = 1024 * 64;
  OPC_LDA_IM  = $A9;
  OPC_NOP     = $EA;

type
  TMem = record
  private
    Data: array[0..MAX_MEM-1] of Byte;
  public
    function ReadByte(addr: Word): Byte;
    procedure WriteByte(addr: Word; value: Byte);
    procedure Show(addr : Word; cnt: Word);
    procedure Init;
  end;

  TStat = bitpacked record
    C,Z,I,D,B,X,V,N : Boolean;
  end;

  TCPU = record
    A, X, Y: Byte;
    PC, SP: Word;

    procedure Reset(ram : TMem);
    procedure Execute(memory : TMem);
    procedure ShowRegs;
    procedure ShowFlags;
    procedure ShowBoxedRegs(compact : Boolean);
    procedure ShowBoxedFlags;
    function RegStat : String;

    case Integer of 
      0 : (SR : Byte);
      1 : (Flags : TStat);
  end;

  TCycleTracker = class
  private
    FCycles: Integer;
  public
    procedure Tick(Count: Integer);
    procedure Reset;
    function GetCycles: Integer;
  end;

function GetCyclesForOpcode(OpCode: Byte): Integer;
procedure DebuggerBreakpoint(Tracker: TCycleTracker);
procedure ExecuteInstruction(OpCode: Byte; Tracker: TCycleTracker);
function ByteArr2AscStr(const Bytes: array of Byte): string;

implementation

{ TMem }
function TMem.ReadByte(addr: Word): Byte;
begin
  Result := Data[addr];
end;

procedure TMem.WriteByte(addr: Word; value: Byte);
begin
  Data[addr] := value;
end;

procedure TMem.Init;
var i: Word;
begin
  for i := 0 to MAX_MEM - 1 do
    Data[i] := 0;
end;

procedure TMem.Show(addr : Word; cnt: Word);
var 
  l,i : Word;
  byteArray : array[0..15] of Byte;
begin
  l := 0;
  WriteLn('Memory hex dump');
  WriteLn('━━━━┯━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┯━━━━━━━━━━━━━━━━');
  WriteLn('Addr┆ 00 01 02 03 04 05 06 07 - 08 09 0A 0B 0C 0D 0E 0F┆ASCII data');
  WriteLn('━━━━┿━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┿━━━━━━━━━━━━━━━━');
  for i:=addr to addr+cnt-1 do
  begin
    byteArray[l] := ReadByte(i);
    if l = 0 then Write(Format('%4.4x┆',[i]));
    if l = 15 then
    begin
      WriteLn(Format(' %2.2x┆%s',[ReadByte(i), ByteArr2AscStr(byteArray)]));
      l := 0;   
    end else 
    begin
      l := l + 1; 
      Write(Format(' %2.2x',[ReadByte(i)]));
    end;
    if l = 8 then Write(' -');
  end;
  WriteLn('━━━━┷━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┷━━━━━━━━━━━━━━━━');
end;

{ TCPU }
procedure TCPU.Reset(ram : TMem);
begin
  A := $00;
  X := $00;
  Y := $00;
  SR := $34;
  PC := ram.ReadByte($FFFC) or (ram.ReadByte($FFFD) shl 8);
  SP := $00FD;
end;

procedure TCPU.Execute(memory : TMem);
var 
  instruction : Byte;
  cycles : Byte;
begin
  while cycles > 0 do
  begin
    instruction := memory.ReadByte(PC);
    Inc(PC);
    Dec(cycles);

    case instruction of 
      OPC_LDA_IM:
        begin
          A := memory.ReadByte(PC);
          Inc(PC);
          Flags.Z := (A = 0);
          Flags.N := (A and $80) <> 0;
          WriteLn(Format('LDA #%x',[A]));
        end;
      OPC_NOP: WriteLn('NOP');
    end;
  end;
end;

procedure TCPU.ShowRegs;
begin
  WriteLn('CPU.Regstat ⇨ ' + RegStat);
end;

procedure TCPU.ShowFlags;
var f: array[0..7] of integer;
begin
  f[7] := Ord(Flags.N);
  f[6] := Ord(Flags.V);
  f[5] := Ord(Flags.X);
  f[4] := Ord(Flags.B);
  f[3] := Ord(Flags.D);
  f[2] := Ord(Flags.I);
  f[1] := Ord(Flags.Z);
  f[0] := Ord(Flags.C);
  WriteLn('Flags: ', Format('%d%d%d%d%d%d%d%d', [f[7],f[6],f[5],f[4],f[3],f[2],f[1],f[0]]));
end;

procedure TCPU.ShowBoxedRegs(compact : Boolean);
begin
{
├ ┝ ┞ ┟ ┠ ┡ ┢ ┣ ┤ ┥ ┦ ┧ ┨ ┩ ┪ ┫ ┬ ┭ ┮ ┯ ┰ ┱ ┲ ┳ ┴ ┵ ┶ ┷ ┸ ┹ ┺ ┻ ┼ ┽ ┾ ┿ ╀ ╁ ╂ ╃ ╄ ╅ ╆ ╇ ╈ ╉ ╊ ╋
┌ ┍ ┎ ┏ ┐ ┑ ┒ ┓ └ ┕ ┖ ┗ ┘ ┙ ┚ ┛
― ⍽ ⎸ ⎹ ␣ ─ ━ │ ┃
╭ ╮ ╯ ╰ ╱ ╲ ╳
═ ║ ╒ ╓ ╔ ╕ ╖ ╗ ╘ ╙ ╚ ╛ ╜ ╝ ╞ ╟ ╠ ╡ ╢ ╣ ╤ ╥ ╦ ╧ ╨ ╩ ╪ ╫ ╬
╭――――――――――――――――――╮
│                  │
│                  │
│                  │
╰――――――――――――――――――╯
┄ ┅ ┆ ┇ ┈ ┉ ┊ ┋╌ ╍ ╎ ╏
☐ ☑ ☒ ⫍ ⫎ ⮹ ⮽ ⺆ ⼌ ⼐ ⼕
← ↑ → ↓ ↔ ↕ ↖ ↗ ↘ ↙ ↚ ↛ ↜ ↝ ↞ ↟ ↠ ↡ ↢ ↣ ↤ ↥ ↦ ↧ ↨ ↩ ↪ ↫ ↬ ↭ ↮ ↯ 
↰ ↱ ↲ ↳ ↴ ↵ ↶ ↷ ↸ ↹ ↺ ↻ ⇄ ⇅ ⇆ ⇇ ⇈ ⇉ ⇊ ⇍ ⇎ ⇏ ⇐ ⇑ ⇒ ⇓ ⇔ ⇕ ⇖ ⇗ ⇘ ⇙ 
⇚ ⇛ ⇜ ⇝ ⇞ ⇟ ⇠ ⇡ ⇢ ⇣ ⇤ ⇥ ⇦ ⇧ ⇨ ⇩ ⇪
}
  if (compact) then
  begin  
    WriteLn(       'CPU registers index                 programcounter stackpointer');  
    WriteLn(       '╓――╥―――――╖   ╓――╥―――――╖ ╓――╥―――――╖    ╓――╥―――――――╖ ╓――╥―――――――╖');
    WriteLn(Format('║A ║ $%0:2.2x ║   ║X ║ $%1:2.2x ║ ║Y ║ $%2:2.2x ║    ║PC║ $%3:4.4x ║ ║SP║ $%4:4.4x ║',[A,X,Y,PC,SP]));
    WriteLn(       '╙――╨―――――╜   ╙――╨―――――╜ ╙――╨―――――╜    ╙――╨―――――――╜ ╙――╨―――――――╜');
  end else
  begin
    WriteLn(' ');
    WriteLn(       'CPU registers');
    WriteLn(       'accumulator index');
    WriteLn(       '╔═════╗   ╔═════╗ ╔═════╗');
    WriteLn(       '║  A  ║   ║  X  ║ ║  Y  ║');
    WriteLn(       '╟―――――╢   ╟―――――╢ ╟―――――╢');
    WriteLn(Format('║ $%0:2.2x ║   ║ $%1:2.2x ║ ║ $%2:2.2x ║',[A,X,Y]));
    WriteLn(       '╚═════╝   ╚═════╝ ╚═════╝');
    WriteLn(       'program counter  stack pointer');
    WriteLn(       '╔═══════╗  ╔═══════╗');
    WriteLn(       '║  PC   ║  ║  SP   ║');
    WriteLn(       '╟―――――――╢  ╟―――――――╢');
    WriteLn(Format('║ $%0:4.4x ║  ║ $%1:4.4x ║',[PC,SP]));
    WriteLn(       '╚═══════╝  ╚═══════╝');
  end;
end;

procedure TCPU.ShowBoxedFlags;
var 
  f : array[0..7] of integer;
begin 
    f[0] := 0;
  if (Flags.N) then f[7] := 1 else f[7] := 0;
  if (Flags.V) then f[6] := 1 else f[6] := 0;
  if (Flags.X) then f[5] := 1 else f[5] := 0;
  if (Flags.B) then f[4] := 1 else f[4] := 0;
  if (Flags.D) then f[3] := 1 else f[3] := 0;
  if (Flags.I) then f[2] := 1 else f[2] := 0;
  if (Flags.Z) then f[1] := 1 else f[1] := 0;
  if (Flags.C) then f[0] := 1 else f[0] := 0;
  WriteLn(' ');
  WriteLn(       'B7      Status Register        B0');
  WriteLn(       '╓―――╥―――╥―――╥―――╥―――╥―――╥―――╥―――╖ ');
  WriteLn(       '║ N ║ V ║ 1 ║ B ║ D ║ I ║ Z ║ C ║');
  WriteLn(       '╟―――╫―――╫―――╫―――╫―――╫―――╫―――╫―――╢');
  WriteLn(Format('║ %d ║ %d ║ %d ║ %d ║ %d ║ %d ║ %d ║ %d ║',
                  {[sr.N,sr.V,sr.X,sr.B,sr.D,sr.I,sr.Z,sr.C]}
                  [ f[7],f[6],f[5],f[4],f[3],f[2],f[1],f[0] ]
              )
         );
  WriteLn(       '╙―――╨―――╨―――╨―――╨―――╨―――╨―――╨―――╜');
end;


function TCPU.RegStat : String;
begin
  Result := Format('A=$%0:2.2x X=$%1:2.2x Y=$%2:2.2x PC=$%3:4.4x SP=$%4:4.4x St=$%5:2.2x', [A, X, Y, PC, SP, SR]);
end;

{ TCycleTracker }
procedure TCycleTracker.Tick(Count: Integer);
begin
  Inc(FCycles, Count);
end;

procedure TCycleTracker.Reset;
begin
  FCycles := 0;
end;

function TCycleTracker.GetCycles: Integer;
begin
  Result := FCycles;
end;

{ Utility Procedures }
function GetCyclesForOpcode(OpCode: Byte): Integer;
begin
  case OpCode of
    $A9, $AA: Result := 2;
    else Result := 1;
  end;
end;

procedure DebuggerBreakpoint(Tracker: TCycleTracker);
begin
  Writeln('🔍 Breakpoint hit at cycle: ', Tracker.GetCycles);
end;

procedure ExecuteInstruction(OpCode: Byte; Tracker: TCycleTracker);
begin
  case OpCode of
    $00: DebuggerBreakpoint(Tracker);
    else Tracker.Tick(GetCyclesForOpcode(OpCode));
  end;
end;

function ByteArr2AscStr(const Bytes: array of Byte): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 0 to High(Bytes) do
  begin
    c := Chr(Bytes[i]);
    if (c in ['a'..'z']) or (c in ['A'..'Z']) or (c in ['0'..'9']) then
      Result := Result + c
    else
      Result := Result + '.';
  end;
end;

end.
