XASM := fasm
SRCDIR := src
BUILDDIR := build
BINDDIR := bin
SRCEXT := asm
TARGET := ${BINDDIR}/ASMSnake.exe

SRCS := $(shell find ${SRCDIR} -type f -name *.${SRCEXT})

all: ${TARGET}

${TARGET}: ${SRCS}
	@mkdir -p ${BINDDIR}
	${XASM} $< $@

clean:
	@${RM} -rf ${TARGET} ${BINDDIR}

run: ${TARGET}
	./${TARGET}

.PHONY: all clean run
