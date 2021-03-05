NAME = STRIKE
PADVAL = 0

RGBASM = rgbasm
RGBLINK = rgblink
RGBFIX = rgbfix

RM_F = rm -f

ASFLAGS = -h
LDFLAGS = -t -w -n strikethrough.sym -t
FIXFLAGS = -v -c -p $(PADVAL) -t $(NAME)

strikethrough.gb: strikethrough.o
	$(RGBLINK) $(LDFLAGS) -o $@ $^
	$(RGBFIX) $(FIXFLAGS) $@

strikethrough.o: src/main.asm
	$(RGBASM) $(ASFLAGS) -o $@ $<

.PHONY: clean
clean:
	$(RM_F) strikethrough.o strikethrough.gb