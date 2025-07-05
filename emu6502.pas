program EMU6502;

uses
  SysUtils, EMU6502Core;

var
  Mem: TMem;
  CPU: TCPU;
  
  procedure Hellorld;
  begin
    WriteLn('╭―――――――――――――――――――――╮');
    WriteLn('│  Hellorld emu6502!  │');
    WriteLn('╰―――――――――――――――――――――╯');
  end;

begin
  Hellorld;
  Mem.Init;
  Mem.WriteByte($FFFC, $10);
  Mem.WriteByte($FFFD, $00);
  Mem.WriteByte($1000, OPC_LDA_IM);
  Mem.WriteByte($1001, $42);
  Mem.WriteByte($1002, OPC_NOP);
  Mem.Show($1000, $20);

  CPU.Reset(Mem);
  CPU.Execute(2, Mem);
  CPU.ShowBoxedRegs;
  CPU.ShowBoxedFlags;
end.
