# Project configuration
TARGET = emu6502
UNITS = emu6502core.pas
SRC = emu6502.pas

# FPC options
FPC = fpc
FPCFLAGS = -Mobjfpc -Scgi -O2

# Default target
all: $(TARGET)

$(TARGET): $(SRC) $(UNITS)
	$(FPC) $(FPCFLAGS) $(SRC)

clean:
	@echo Cleaning up...
	@rm -f *.o *.ppu $(TARGET)

.PHONY: all clean
