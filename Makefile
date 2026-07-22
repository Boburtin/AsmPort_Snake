XASM := fasm

SRCDIR := src
BUILDDIR := build
TARGET := bin/ASMSnake.exe
SRCEXT := asm

SRCS := $(shell find $(SRCDIR) -type f -name *.$(SRCEXT))

all: $(TARGET)

$(TARGET): $(SRCS)
	$(XASM) $< $@

clean:
	@$(RM) -r $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
