STRIKETHROUGH_START_X EQU 23
STRIKETHROUGH_START_Y EQU $54

OAM_START_OFFSET      EQU 28
OAM_DATA_ADD_OFFSET   EQU 2
OAM_DATA_VAL_OFFSET   EQU $FF

INCLUDE "inc/hardware.inc"
INCLUDE "src/dma.asm"
INCLUDE "src/functions.asm"

SECTION "Vectors", ROM0[$0]
    ds $48 - @

STATVector::
    jp STATHandler

    ds $100 - @

SECTION "Test", ROM0[$100]
    di
    jp InitTest
    ds $150 - @

InitTest::
    ; Wait for VBlank, disable LCD
	ldh a, [rLY]
	cp SCRN_Y
	jr c, InitTest
    xor a
    ld [rLCDC], a

    ; Initialize DMG Palettes
    ld a, %11111100
    ldh [rBGP], a
    ldh [rOBP0], a
    ldh [rOBP1], a

    ; Initialize CGB Palettes (yes this is garbage)
    ld a, BCPSF_AUTOINC
    ldh [rBCPS], a
    ldh [rOCPS], a
    xor a
    ldh [rBCPD], a
    ldh [rBCPD], a
    dec a
    ldh [rBCPD], a
    ldh [rBCPD], a
    ldh [rBCPD], a
    ldh [rBCPD], a
    ldh [rBCPD], a
    ldh [rBCPD], a
    ldh [rOCPD], a
    ldh [rOCPD], a
    ldh [rOCPD], a
    ldh [rOCPD], a
    ldh [rOCPD], a
    ldh [rOCPD], a
    ldh [rOCPD], a
    ldh [rOCPD], a

    ; Initialize OAM DMA routine
    call CopyDMARoutine

    ; Clear VRAM
    ld hl, $9800
    ld bc, $9C00 - $9800
.clearVramLoop
    xor a
    dec a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .clearVramLoop

    ; Initialize Blocky tile data
    ld hl, $8010
    ld bc, ($8200 - $8010) / 16
.blockInitLoop
    xor a
REPT 16
    ld [hli], a
ENDR
    dec bc
    ld a, b
    or c
    jr nz, .blockInitLoop

    ; Initialize tile data
    ld bc, $0010
    ld de, StrikethroughTile
    ld hl, $8000
    call Memcpy
    ld bc, FontTilesEnd - FontTiles
    ld de, FontTiles
    ld hl, $8000 + (16 * "!")
    call Memcpy

    ; Initialize background string
    ld de, strBackground
    ld hl, $9902
    call Strcpy
    dec hl
    ld a, $FF
    ld [hl], a

    ; Initialize OAM
    ld hl, wShadowOAM
    ld b, 40
    ld c, STRIKETHROUGH_START_X
.initLoopOAM
    ld a, STRIKETHROUGH_START_Y
    ld [hli], a
    ld a, c
    ld [hli], a
    add 8
    ld c, a
    xor a
    ld [hli], a
    ld [hli], a
    dec b
    jr nz, .initLoopOAM

    ; Call DMA
    ld a, HIGH(wShadowOAM)
    call hOAMDMA

    ; Initialize interrupts
    ld a, IEF_LCDC
    ldh [rIE], a
    ld a, STATF_LYC
    ldh [rSTAT], a
    ld a, STRIKETHROUGH_START_Y - $11
    ldh [rLYC], a
    xor a
    ldh [rIF], a
    ei
    
    ; Enable LCD
    ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BGON | LCDCF_OBJON
    ldh [rLCDC], a

RunTest::
    ; Load test OAM
    ld hl, wShadowOAM
    ld de, TransferOAM
    ld bc, EndTransferOAM - TransferOAM
    call Memcpy

    halt

    ; Wait for VBlank
.waitVBL
    ldh a, [rSTAT]
    and 3
    dec a
    jr nz, .waitVBL

    ; Reload original OAM
    ld hl, wShadowOAM
    ld de, InitOAM
    ld bc, EndInitOAM - InitOAM
    call Memcpy

    ; Call DMA
    ld a, HIGH(wShadowOAM)
    call hOAMDMA

    jr RunTest

STATHandler::
    ; Wait for HBlank
    ldh a, [rSTAT]
    and 3
    jr nz, STATHandler

REPT OAM_START_OFFSET
    nop
ENDR

    ; Call DMA
    ld a, HIGH(wShadowOAM)
    call hOAMDMA
    reti

SECTION "Binary Data", ROM0
strBackground: db "Everything is OK!", 0

FontTiles:
INCBIN "inc/font.chr"
FontTilesEnd:

; This can probably be done better but oh well
InitOAM:
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (0*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (1*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (2*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (3*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (4*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (5*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (6*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (7*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (8*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (9*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (10*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (11*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (12*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (13*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (14*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (15*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (16*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (17*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (18*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (19*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (20*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (21*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (22*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (23*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (24*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (25*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (26*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (27*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (28*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (29*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (30*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (31*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (32*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (33*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (34*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (35*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (36*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (37*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (38*8)) % 256, $00, $00
db STRIKETHROUGH_START_Y, (STRIKETHROUGH_START_X + (39*8)) % 256, $00, $00
EndInitOAM:

TransferOAM:
db $63, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
; End of OAM Scan (?)
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $00, $01 ; The $00 byte in this line seems to affect the tile number of the sprite thats shown
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
db $01, $01, $01, $01
EndTransferOAM:

StrikethroughTile:
db $FF, $FF
db $00, $00
db $00, $00
db $00, $00
db $00, $00
db $00, $00
db $00, $00
db $00, $00