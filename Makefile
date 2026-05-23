XASM := fasm

SRCDIR := src
BUILDDIR := build
TARGET := bin/ASMSnake.exe
SRCEXT := asm

SRCS := $(shell find $(SRCDIR) -type f -name *.$(SRCEXT))
OBJS := $(patsubst $(SRCDIR)/%,$(BUILDDIR)/%,$(SRCS:.$(SRCEXT)=.obj))

all: $(TARGET)

$(TARGET): $(SRCS)
	$(XASM) $< $@

clean:
	@$(RM) -r $(BUILDDIR) $(TARGET)

.PHONY: all clean