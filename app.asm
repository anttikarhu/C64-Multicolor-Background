; ALLOWS ONE TO START THE APPLICATION WITH RUN
; SYS 2064
*=$0801 
         BYTE $0C, $8, $0A, $00, $9E, $20, $32, $30, $36, $34, $00, $00, $00, $00, $00

CHMEMPTR        = $D018 ; CHARACTER MEMORY POINTER TO $3000
CHMAPMEM        = $3000 ; CHARACTER MEMORY POINTER

CPUPORT         = $0001 ; PROCESSOR PORT FLAGS

SCRCTRL2        = $D016
BGCOLOR0        = $D021
BGCOLOR1        = $D022
BGCOLOR2        = $D023

SCRMEM          = $0400

SPR_ENABLE      = $D015 ; FLAGS FOR SPRITE ENABLING
SPR_MSBX        = $D010 ; FLAGS TO REPRESENT X VALUES LARGER THAN 255
SPR_COLORMODE   = $D01C ; FLAGS TO SET COLOR MODES (0 = HIGH RES/2-COLOR, 1 = MULTICOLOR/4-COLOR)
SPR_COLOR0      = $D025 ; SHARED SPRITE COLOR 0
SPR_COLOR1      = $D026 ; SHARED SPRITE COLOR 1

SPR0_PTR        = $07F8 ; SPRITE 0 DATA POINTER
SPR0_ADDR       = #$0D  ; SPRITE 0 POINTER VALUE
SPR0_DATA       = $0340 ; SPRITE 0 DATA ADDRESS (POINTER VALUE * $40)
SPR0_X          = $D000 ; SPRITE 0 X COORDINATE
SPR0_Y          = $D001 ; SPRITE 0 Y COORDINATE
SPR0_COLOR      = $D027 ; SPRITE 0 COLOR

SPR1_PTR        = $07F9 ; SPRITE 1 DATA POINTER
SPR1_ADDR       = #$0D  ; SPRITE 1 POINTER VALUE, SAME DATA AS FOR 0
SPR1_DATA       = $0340 ; SPRITE 1 DATA ADDRESS, SAME DATA AS FOR 0
SPR1_X          = $D002 ; SPRITE 1 X COORDINATE
SPR1_Y          = $D003 ; SPRITE 1 Y COORDINATE
SPR1_COLOR      = $D028 ; SPRITE 1 COLOR

SPR2_PTR        = $07FA ; SPRITE 2 DATA POINTER
SPR2_ADDR       = #$0E  ; SPRITE 2 POINTER VALUE
SPR2_DATA       = $0380 ; SPRITE 2 DATA ADDRESS
SPR2_X          = $D004 ; SPRITE 2 X COORDINATE
SPR2_Y          = $D005 ; SPRITE 2 Y COORDINATE
SPR2_COLOR      = $D029 ; SPRITE 2 COLORS

SPR3_PTR        = $07FB ; SPRITE 3 DATA POINTER
SPR3_ADDR       = #$0E  ; SPRITE 3 POINTER VALUE, SAME DATA AS FOR 2
SPR3_DATA       = $0380 ; SPRITE 3 DATA ADDRESS, SAME DATA AS FOR 2
SPR3_X          = $D006 ; SPRITE 3 X COORDINATE
SPR3_Y          = $D007 ; SPRITE 3 Y COORDINATE
SPR3_COLOR      = $D02A ; SPRITE 3 COLOR


        ; DISABLED INTERRUPTS
        SEI

        ; TURN CHARACTER ROM VISIBLE AT $D000
        LDA CPUPORT
        AND #%11111011
        STA CPUPORT

        ; DEFINE CHAR RAM START $3000
        LDA #$00
        STA $FA
        LDA #$30
        STA $FB

        ; DEFINE CHAR ROM START $D000
        LDA #$00
        STA $FC
        LDA #$D0
        STA $FD

        ; COPY CHARACTERS ROM -> RAM
        LDY #0          ; Y ACTS AS A READ/WRITE LSB OFFSET
CPYLOOP
        LDA ($FC),Y     ; READ BYTE FROM ROM (TO ADDRESS *FD+*FC+Y)
        STA ($FA),Y     ; WRITE BYTE TO RAM (TO ADDRESS *FB+*FA+Y)
        INY             ; WRITE UNTIL Y OVERFLOWS BACK TO ZERO
        BNE CPYLOOP

        INC $FD         ; INCREMENT ROM READ MSB
        LDX $FB         ; INCREMENT RAM WRITE MSB
        INX
        STX $FB
        CPX #$38        ; KEEP COPYING UNTIL AT THE END OF CHAR RAM
        BNE CPYLOOP

        ; TURN I/O BACK VISIBLE AT $D000
        LDA CPUPORT
        ORA #%00000100
        STA CPUPORT

        ; SET CHARACTER MEMORY POINTER
        LDA CHMEMPTR
        AND #%11110000
        ORA #%00001100
        STA CHMEMPTR

        ; MULTICOLOR MODE
        LDA SCRCTRL2
        ORA #%00010000
        STA SCRCTRL2

        ; DEFINE BACKGROUD COLOR AND 2 SHARED CHAR COLORS
        LDA #5
        STA BGCOLOR0
        LDA #11
        STA BGCOLOR1
        LDA #1
        STA BGCOLOR2

        ; RE-ENABLE INTERRUPTS
        CLI

        ; LOAD CUSTOM CHARACTER SET
        LDX #0
LDCHMAP LDA CHMAP,X
        STA CHMAPMEM,X
        INX
        CPX #72
        BNE LDCHMAP

        ; LOAD SCREEN
        ; DEFINE SCREEN RAM START $0400
        LDA #$00
        STA $FA
        LDA #$04
        STA $FB

        ; DEFINE SCREEN DATA START
        LDA #<SCREEN
        STA $FC
        LDA #>SCREEN
        STA $FD

        ; COPY SCREEN TO RAM
        LDY #0          ; Y ACTS AS A READ/WRITE LSB OFFSET
CPLOOP2
        LDA ($FC),Y     ; READ BYTE (TO ADDRESS *FD+*FC+Y)
        STA ($FA),Y     ; WRITE BYTE (TO ADDRESS *FB+*FA+Y)

        LDX $FB         ; READ UNTIL AT THE END OF SCREEN RAM ($07E7)
        CPX #$07
        BNE CONTCPY     ; (NOT AT THE LAST CHUNK OF 256 BYTES)
        CPY #$E7
        BEQ CPYEND      ; COPY DONE

CONTCPY INY             ; WRITE UNTIL Y OVERFLOWS BACK TO ZERO
        BNE CPLOOP2

        INC $FD         ; INCREMENT READ MSB
        INC $FB         ; INCREMENT WRITE MSB
        JMP CPLOOP2     ; KEEP COPYING
CPYEND

        ; LOAD COLORS
        ; DEFINE COLOR RAM START $D800
        LDA #$00
        STA $FA
        LDA #$D8
        STA $FB

        ; DEFINE COLOR DATA START
        LDA #<COLORS
        STA $FC
        LDA #>COLORS
        STA $FD

        ; COPY COLORS TO RAM
        LDY #0          ; Y ACTS AS A READ/WRITE LSB OFFSET
CPLOOP3
        LDA ($FC),Y     ; READ BYTE (TO ADDRESS *FD+*FC+Y)
        STA ($FA),Y     ; WRITE BYTE (TO ADDRESS *FB+*FA+Y)

        LDX $FB         ; READ UNTIL AT THE END OF COLOR RAM ($DBE7)
        CPX #$DB
        BNE CONTCP2     ; (NOT AT THE LAST CHUNK OF 256 BYTES)
        CPY #$E7
        BEQ CPYEND2     ; COPY DONE

CONTCP2 INY             ; WRITE UNTIL Y OVERFLOWS BACK TO ZERO
        BNE CPLOOP3

        INC $FD         ; INCREMENT READ MSB
        INC $FB         ; INCREMENT WRITE MSB
        JMP CPLOOP3     ; KEEP COPYING
CPYEND2

        ; DRAW COUPLE OF SPRITES OVER THE BACKGROUND FOR EXTRA FUN
        ; ENABLE SPRITES
        LDA #%00001111
        STA SPR_ENABLE

        ; SET COLOR MODES
        LDA #%00000011
        STA SPR_COLORMODE

        ; SET SPRITE COLORS
        LDA #4
        STA SPR0_COLOR
        LDA #14
        STA SPR1_COLOR
        LDA #0
        STA SPR2_COLOR
        LDA #0
        STA SPR3_COLOR

        LDA #0
        STA SPR_COLOR0
        LDA #1
        STA SPR_COLOR1
   

        ; SET SPRITE X
        LDX #%00000000
        STX SPR_MSBX
        LDX #170
        STX SPR0_X
        LDX #100
        STX SPR1_X
        LDX #170
        STX SPR2_X
        LDX #100
        STX SPR3_X

        ; SET SPRITE Y
        LDY #104
        STY SPR0_Y
        LDY #120
        STY SPR1_Y
        LDY #104
        STY SPR2_Y
        LDY #120
        STY SPR3_Y


        ; SET SPRITE POINTER
        LDA SPR0_ADDR
        STA SPR0_PTR
        LDA SPR1_ADDR
        STA SPR1_PTR
        LDA SPR2_ADDR
        STA SPR2_PTR
        LDA SPR3_ADDR
        STA SPR3_PTR


        ; LOAD SPRITES
        LDX #0
LDSPR1  LDA SPR1,X
        STA SPR0_DATA,X
        INX
        CPX #128        ; 2 SPRITES
        BNE LDSPR1

        ; MAIN LOOP
LOOP    JMP LOOP

CHMAP   BYTE    $55,$55,$55,$55,$55,$55,$55,$55
        BYTE    $55,$AA,$AA,$AA,$55,$55,$55,$55
        BYTE    $55,$55,$AA,$AA,$AA,$AA,$55,$55
        BYTE    $55,$55,$55,$55,$AA,$AA,$AA,$55
        BYTE    $3C,$3C,$FF,$C3,$C3,$FF,$3C,$3C
        BYTE    $55,$55,$55,$F7,$FF,$55,$55,$55
        BYTE    $55,$55,$55,$F5,$7F,$5D,$55,$55
        BYTE    $55,$55,$F5,$7F,$5D,$55,$55,$55
        BYTE    $22,$AA,$AA,$EA,$5A,$56,$74,$58

SCREEN  BYTE    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $08,$08,$08,$08,$08,$08,$08,$20,$20,$08,$08,$08,$08,$08,$08,$20,$20,$20,$08,$08,$08,$08,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20
        BYTE    $20,$08,$08,$20,$20,$20,$20,$04,$20,$20,$20,$20,$04,$20,$20,$20,$04,$20,$20,$08,$08,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$04,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$04,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
        BYTE    $00,$00,$00,$00,$00,$00,$00,$05,$06,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$06,$07,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02,$00,$00,$00,$02,$02,$02
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$05,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$04,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20
        BYTE    $20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$04,$20,$20,$20,$04,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$04,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20

COLORS  BYTE    $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $07,$07,$07,$07,$07,$07,$07,$00,$00,$07,$07,$07,$07,$07,$07,$00,$00,$00,$07,$07,$07,$07,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$0A,$00,$00,$00,$00,$00
        BYTE    $00,$07,$07,$00,$00,$00,$00,$03,$00,$00,$00,$00,$03,$00,$00,$00,$07,$00,$00,$07,$07,$00,$0A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$0A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$03,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$0A,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
        BYTE    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
        BYTE    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
        BYTE    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
        BYTE    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
        BYTE    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
        BYTE    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
        BYTE    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
        BYTE    $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$07,$00,$00,$03,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00
        BYTE    $00,$00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$0A,$00,$00,$00,$03,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

SPR1    BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$15,$40
        BYTE $00,$7E,$91
        BYTE $00,$7E,$91
        BYTE $01,$FE,$A5
        BYTE $15,$FE,$A4
        BYTE $5A,$AA,$A9
        BYTE $6A,$AA,$A9
        BYTE $6A,$AA,$A9
        BYTE $69,$AA,$99
        BYTE $65,$6A,$55
        BYTE $17,$55,$74
        BYTE $05,$40,$54
        BYTE $01,$00,$10
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00

SPR2    BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $2A,$AA,$AA
        BYTE $15,$55,$54
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00
