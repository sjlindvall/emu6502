program emu6502;

uses
  SysUtils, emu6502comp;

var
  Mem: TMem;
  CPU: TCPU;
  
  procedure Hellorld;
  begin
    WriteLn('╭―――――――――――――――――――――╮');
    WriteLn('│  Hellorld! emu6502  │');
    WriteLn('╰―――――――――――――――――――――╯');
  end;

begin
  Hellorld;
  WriteLn;
  Mem.Init;
  Mem.WriteByte($FFFC, $10);
  Mem.WriteByte($FFFD, $00);
  Mem.WriteByte($1000, OPC_LDA_IM);
  Mem.WriteByte($1001, $42);
  Mem.WriteByte($1002, OPC_NOP);
  Mem.WriteByte($1003, $41);
  Mem.WriteByte($1004, $43);
  Mem.WriteByte($1005, $44);
  Mem.WriteByte($1006, $45);
  Mem.WriteByte($1007, $46);
  Mem.WriteByte($1008, $47);
  Mem.WriteByte($1009, $48);
  Mem.WriteByte($100A, $49);
  Mem.WriteByte($100B, $4A);
  Mem.WriteByte($100C, $4B);
  Mem.WriteByte($100D, $4C);
  Mem.WriteByte($100E, $4D);
  Mem.WriteByte($100F, $4E);
  Mem.Show($1000, $20);

  WriteLn;
  CPU.Reset(Mem);
  CPU.Execute(Mem);
  CPU.ShowBoxedRegs(True);
  CPU.ShowBoxedFlags;
end.
