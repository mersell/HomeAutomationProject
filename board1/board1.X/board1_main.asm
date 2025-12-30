; ==========================================================
; Board 1 - Air Conditioner System (PIC16F877A)
; Toolchain: MPLAB X 6.25, XC8 (pic-as)
;AUTHOR:GAN?ME YALCIN 15220222139 && EYÜP TÜMER ZENG?N 
; PURPOSE:
;   This program implements a minimal air-conditioner controller:
;   - Reads ambient temperature from LM35 via ADC (AN0).
;   - Accepts desired temperature from keypad using a simple protocol.
;   - Drives HEATER (RD0) and FAN/COOLER (RD1) based on DES vs AMB.
;   - Refreshes a 7-seg display using multiplexing (demo "  25").
;
; PIN MAPPING (YOUR PINS):
;   Heater          RD0
;   Fan/Cooler      RD1
;   LM35 Temp       RA0 / AN0
;   Keypad Rows     RB1-RB4  (INPUT + pull-up)
;   Keypad Cols     RB5,RB6,RB7,RC5 (OUTPUT scanning, active-low)
;
; Key format (minimal version): A D1 D2 #  (example: A25#)
; DESIGN NOTES
;   - Cooperative scheduling: modules are called sequentially in MAIN_LOOP.
;   - DISP_SHOW is called frequently to maintain 7-seg multiplex persistence.
;   - Keypad input uses debounce + "one event per press" lock (KEY_HELD).
;   - ADC is configured for right-justified 10-bit reads (ADRESH:ADRESL).
; ==========================================================
; ==========================================================

        PROCESSOR   16F877A
        #include    <xc.inc>
         ; ==========================================================
        ; CONFIGURATION BITS (stability-oriented settings)
        ;   FOSC=XT:   External crystal/resonator mode (typ. 4 MHz).
        ;   WDTE=OFF:  Disable watchdog for deterministic timing.
        ;   PWRTE=ON:  Improves power-up stability.
        ;   BOREN=ON:  Brown-out reset to avoid undefined states.
        ;   LVP=OFF:   Disable low-voltage programming.
        ; ==========================================================
        CONFIG  FOSC=XT, WDTE=OFF, PWRTE=ON, BOREN=ON, LVP=OFF, CPD=OFF, WRT=OFF, CP=OFF

; -----------------------
; RAM variables (BANK0)
; -----------------------
        PSECT   udata_bank0

DES_TEMP_H:     ds 1        ; Desired temperature integer (0..99)
AMB_TEMP_H:     ds 1        ; Ambient temperature (demo-scaled from ADC, 0..255)
AMB_TEMP_L:     ds 1        ; Fractional/unused in this minimal version

TMP:            ds 1        ; General-purpose temporary register
TEMP_RAW:       ds 1        ; Raw value holder (e.g., key code)
TEMP_WORK:      ds 1        ; Work register for delays/operations

 ; --- ADC result bytes (10-bit = ADRESH:ADRESL) ---
ADC_H:          ds 1
ADC_L:          ds 1

; --- Keypad FSM / debounce ---
KEY_STATE:      ds 1        ; 0=IDLE, 1=WAIT_D1, 2=WAIT_D2_OR_HASH
KEY_D1:         ds 1        ; First digit
KEY_D2:         ds 1        ; Second digit
KEY_HELD:       ds 1        ; 0=ready, 1=ignore until stable release
DB_CNT:         ds 1        ; Debounce/release counter
; --- Arithmetic scratch for DES=10*D1+D2 (shift-add) ---
TMP8:           ds 1
TMP8_H:         ds 1
TMP2:           ds 1
TMP2_H:         ds 1
PART1:          ds 1
; --- Display delay ---
DISP_CNT:       ds 1
   

; -----------------------
; Constants / defs
; -----------------------
HEATER_BIT      EQU 0        ; RD0 controls heater
FAN_BIT         EQU 1        ; RD1 controls fan/cooler

KEY_A_ASC       EQU 0x41     ; ASCII 'A'
KEY_HASH_ASC    EQU 0x23     ; ASCII '#'
KP_NONE         EQU 0xFF     ; No key sentinel

DB_DELAY        EQU 20       ; Debounce acceptance threshold
REL_DELAY       EQU 20       ; Release threshold before unlocking KEY_HELD

            ; ==========================================================
        ; RESET VECTOR
        ; Design rationale:
        ;   A single, explicit reset entry ensures initialization always
        ;   runs before the main application loop.
        ; ==========================================================
        PSECT   resetVector,class=CODE,delta=2
        ORG     0x0000
        goto    INIT

        PSECT   code,class=CODE,delta=2

; ==========================================================
; INIT
; Design rationale:
;   - Keypad rows RB1..RB4 are inputs: enable weak pull-ups for stable idle.
;   - Configure TRIS once; clear all PORTs to avoid startup glitches.
;   - Set keypad columns idle HIGH; scanning will pull one column LOW at a time.
; ==========================================================
; ==========================================================
INIT:
        ; Enable PORTB weak pull-ups
        banksel OPTION_REG
        bcf     OPTION_REG, 7        ; RBPU=0 => pull-ups enabled

        ; TRISA: RA0 input (AN0)
        banksel TRISA
        movlw   0b00000001
        movwf   TRISA

        ; TRISB: RB1..RB4 input, RB5..RB7 output (RB0 input/unused)
        banksel TRISB
        movlw   0b00011111          ; RB0..RB4 in, RB5..RB7 out
        movwf   TRISB

        ; TRISC: RC5 output (col4), RC7 input optional
        banksel TRISC
        movlw   0b10000000
        movwf   TRISC

        ; TRISD: all outputs (RD0/RD1 actuators; RD2..RD7 may drive 7-seg segments)
        banksel TRISD
        clrf    TRISD

        ; Clear ports
        banksel PORTA
        clrf    PORTA
        banksel PORTB
        clrf    PORTB
        banksel PORTC
        clrf    PORTC
        banksel PORTD
        clrf    PORTD

        ; Keypad columns idle HIGH
        banksel PORTB
        bsf     PORTB, 5
        bsf     PORTB, 6
        bsf     PORTB, 7
        banksel PORTC
        bsf     PORTC, 5

        ; Initialize variables
        banksel DES_TEMP_H
        movlw   25
        movwf   DES_TEMP_H
        clrf    AMB_TEMP_H
        clrf    AMB_TEMP_L

	; Initialize keypad FSM and debounce lock
        clrf    KEY_STATE
        movlw   KP_NONE
        movwf   KEY_D1
        movwf   KEY_D2
        clrf    KEY_HELD
        clrf    DB_CNT
        ; Initialize ADC hardware
        call    ADC_INIT
	
; ==========================================================
; MAIN LOOP
; Design rationale:
;   Cooperative scheduling:
;     - DISP_SHOW keeps multiplex display refreshed.
;     - KEYPAD_TASK_MIN updates DES_TEMP_H when a full entry is committed.
;     - READ_AMBIENT_FROM_ADC updates AMB_TEMP_H.
;     - CONTROL_LOGIC drives RD0/RD1 based on DES vs AMB.
; ==========================================================

MAIN_LOOP:
    call    DISP_SHOW
    call    KEYPAD_TASK_MIN      ; A25# -> DES_TEMP_H updates
    call    DISP_SHOW
    call    READ_AMBIENT_FROM_ADC
    call    DISP_SHOW
    call    CONTROL_LOGIC        ; DES vs AMB -> RD0/RD1
    call    DISP_SHOW
    goto    MAIN_LOOP


; ==========================================================
; ADC_INIT
; Design rationale:
;   - Right-justified result (ADFM=1) simplifies combining ADRESH:ADRESL.
;   - PCFG=1110 makes only AN0 analog, avoiding unintended analog behavior.
;   - ADCS=Fosc/32 selected for stable conversion timing at XT frequency.
; ==========================================================
ADC_INIT:
        banksel ADCON1
        movlw   0b10001110           ; ADFM=1, PCFG=1110 -> only AN0 is analog
        movwf   ADCON1

        banksel ADCON0
        movlw   0b10000001           ; ADCS=10 (Fosc/32), CHS=000, ADON=1
        movwf   ADCON0
        return


; ==========================================================
; READ_AMBIENT_FROM_ADC
; Design rationale:
;   - Uses a short acquisition delay to let the ADC sample capacitor settle.
;   - Reads full 10-bit ADC result, then applies a simple scale (>>1) to
;     generate a stable varying value in simulation (demo representation).
; ==========================================================
READ_AMBIENT_FROM_ADC:
        ; acquisition delay
        movlw   30
        banksel TEMP_WORK
        movwf   TEMP_WORK
ACQ:
        decfsz  TEMP_WORK, F
        goto    ACQ

        ; start ADC conversion
        banksel ADCON0
        bsf     ADCON0, 2            ; GO/DONE=1
WAIT_ADC:
        btfsc   ADCON0, 2            ; Wait until GO/DONE clears
        goto    WAIT_ADC

        ; read ADC result bytes
        banksel ADRESH
        movf    ADRESH, W
        banksel ADC_H
        movwf   ADC_H

        banksel ADRESL
        movf    ADRESL, W
        banksel ADC_L
        movwf   ADC_L

        ;Scale:(ADC_H:ADC_L) >> 1
        banksel ADC_H
        rrf     ADC_H, F
        banksel ADC_L
        rrf     ADC_L, F

         ; Store demo ambient value in AMB_TEMP_H
        banksel ADC_L
        movf    ADC_L, W
        banksel AMB_TEMP_H
        movwf   AMB_TEMP_H
        clrf    AMB_TEMP_L
        return


; ==========================================================
; CONTROL_LOGIC
; Design rationale:
;   Compare AMB and DES using subtraction and STATUS flags:
;     movf DES, W
;     subwf AMB, W   => W = AMB - DES
;   Interpretation:
;     Z=1:  AMB == DES  -> both outputs OFF
;     C=1:  AMB >= DES  -> COOL mode (fan ON)
;     C=0:  AMB <  DES  -> HEAT mode (heater ON)
; ==========================================================
CONTROL_LOGIC:
        banksel DES_TEMP_H
        movf    DES_TEMP_H, W
        subwf   AMB_TEMP_H, W        ; W = AMB - DES

        btfsc   STATUS, 2            ; Z => equal
        goto    TCL_EQUAL

        btfsc   STATUS, 0            ; C=1 => AMB >= DES (AMB>DES)
        goto    TCL_COOL

        goto    TCL_HEAT             ; Otherwise AMB < DES => HEAT

TCL_COOL:
        banksel PORTD
        bcf     PORTD, HEATER_BIT     ; Heater OFF
        bsf     PORTD, FAN_BIT       ; Fan/Cooler ON
        return

TCL_HEAT:
        banksel PORTD
        bsf     PORTD, HEATER_BIT  ; Heater ON
        bcf     PORTD, FAN_BIT     ; Fan/Cooler OFF
        return

TCL_EQUAL:
        banksel PORTD
        bcf     PORTD, HEATER_BIT    ; Both OFF at setpoin
        bcf     PORTD, FAN_BIT      
        return


; ==========================================================
; KEYPAD_TASK_MIN  (A D1 D2 #)
; Design rationale:
;   - Debounce eliminates false triggers due to contact bounce.
;   - KEY_HELD enforces one event per press; next event is accepted only
;     after a stable release period (REL_DELAY).
;
; FSM diagram (minimal protocol):
;   [S0 IDLE] -- 'A' --> [S1 WAIT_D1] -- digit --> [S2 WAIT_D2_OR_HASH]
;   [S2] -- digit --> store D2 (stay in S2)
;   [S2] -- '#'   --> COMMIT (if D1 and D2 exist) -> RESET -> S0
; ==========================================================
KEYPAD_TASK_MIN:
        call    KEYPAD_SCAN
        movwf   TEMP_RAW

         ; ------------------------
        ; No key detected path
        ; ------------------------
        movf    TEMP_RAW, W
        xorlw   KP_NONE
        btfss   STATUS, 2
        goto    KT_HAS_KEY

        ; release debounce
        banksel KEY_HELD
        movf    KEY_HELD, F
        btfsc   STATUS, 2
        return

        banksel DB_CNT
        incf    DB_CNT, F
        movf    DB_CNT, W
        sublw   REL_DELAY
        btfss   STATUS, 0
        goto    KT_RELEASED
        return

KT_RELEASED:
         ; Clear held lock and counter, allowing next press event
        clrf    KEY_HELD
        clrf    DB_CNT
        return

KT_HAS_KEY:
        ; if held -> ignore until release
        banksel KEY_HELD
        movf    KEY_HELD, F
        btfss   STATUS, 2
        return

        ; press debounce counter
        banksel DB_CNT
        incf    DB_CNT, F
        movf    DB_CNT, W
        sublw   DB_DELAY
        btfss   STATUS, 0
        goto    KT_ACCEPT
        return

KT_ACCEPT:
         ; Accept press -> lock until release
        clrf    DB_CNT
        banksel KEY_HELD
        movlw   1
        movwf   KEY_HELD

        ; ---- process key ----
        banksel TEMP_RAW
        movf    TEMP_RAW, W

        ; state machine:
        ; state0: wait 'A'
        ; state1: read D1
        ; state2: read D2, then wait '#'
        banksel KEY_STATE
        movf    KEY_STATE, W
        btfsc   STATUS, 2
        goto    S0_IDLE

        xorlw   1
        btfsc   STATUS, 2
        goto    S1_D1

        banksel KEY_STATE
        movf    KEY_STATE, W
        xorlw   2
        btfsc   STATUS, 2
        goto    S2_D2_OR_HASH
        return

S0_IDLE:
        ; expect 'A'
        banksel TEMP_RAW
        movf    TEMP_RAW, W
        xorlw   KEY_A_ASC
        btfss   STATUS, 2
        return

        banksel KEY_STATE
        movlw   1
        movwf   KEY_STATE
        movlw   KP_NONE
        movwf   KEY_D1
        movwf   KEY_D2
        return

S1_D1:
        ; expect digit 0..9
        banksel TEMP_RAW
        movf    TEMP_RAW, W
        movwf   TMP
        movlw   10
        subwf   TMP, W
        btfsc   STATUS, 0            ; TMP >= 10 => de?il
        return

        banksel TEMP_RAW
        movf    TEMP_RAW, W
        banksel KEY_D1
        movwf   KEY_D1

        banksel KEY_STATE
        movlw   2
        movwf   KEY_STATE
        return

S2_D2_OR_HASH:
        ; if '#': commit only if D2 exists (2 digit)
        banksel TEMP_RAW
        movf    TEMP_RAW, W
        xorlw   KEY_HASH_ASC
        btfsc   STATUS, 2
        goto    COMMIT

        ; else expect digit for D2
        banksel TEMP_RAW
        movf    TEMP_RAW, W
        movwf   TMP
        movlw   10
        subwf   TMP, W
        btfsc   STATUS, 0
        return

        banksel TEMP_RAW
        movf    TEMP_RAW, W
        banksel KEY_D2
        movwf   KEY_D2
        return

COMMIT:
        ; require both digits
        banksel KEY_D1
        movf    KEY_D1, W
        xorlw   KP_NONE
        btfsc   STATUS, 2
        goto    RESET_KEYPAD
        banksel KEY_D2
        movf    KEY_D2, W
        xorlw   KP_NONE
        btfsc   STATUS, 2
        goto    RESET_KEYPAD

        ; DES = 10*D1 + D2  (x8 + x2)
        banksel KEY_D1
        movf    KEY_D1, W
        movwf   TMP8
        clrf    TMP8_H

        ; x8
        rlf     TMP8, F
        rlf     TMP8_H, F
        rlf     TMP8, F
        rlf     TMP8_H, F
        rlf     TMP8, F
        rlf     TMP8_H, F

        ; tmp2 = D1*2
        banksel KEY_D1
        movf    KEY_D1, W
        movwf   TMP2
        clrf    TMP2_H
        rlf     TMP2, F
        rlf     TMP2_H, F

        ; PART = x8 + x2
        banksel TMP8
        movf    TMP8, W
        movwf   PART1
        banksel TMP2
        movf    TMP2, W
        addwf   PART1, F

        ; + D2
        banksel PART1
        movf    PART1, W
        banksel DES_TEMP_H
        movwf   DES_TEMP_H
        banksel KEY_D2
        movf    KEY_D2, W
        banksel DES_TEMP_H
        addwf   DES_TEMP_H, F

RESET_KEYPAD:
        banksel KEY_STATE
        clrf    KEY_STATE
        movlw   KP_NONE
        movwf   KEY_D1
        movwf   KEY_D2
        return


; ==========================================================
; KEYPAD_SCAN (YOUR PIN MAPPING)
; Design rationale:
;   - Column scanning drives exactly one column LOW at a time (active-low),
;     while the others remain HIGH. This uniquely identifies a key press.
;   - Rows use pull-ups: pressed key pulls the row line LOW.
;
; Rows: RB1..RB4 (pressed => 0)
; Cols: RB5,RB6,RB7,RC5 (active LOW scanning)
;
; Returns in W:
;   - digits 0..9
;   - 'A' (0x41)
;   - '#' (0x23)
;   - '*' (0x2A)
;   - none 0xFF
; ==========================================================
KEYPAD_SCAN:
        ; COL1: RB5 low => 1,4,7,*
        banksel PORTB
        bcf     PORTB, 5
        bsf     PORTB, 6
        bsf     PORTB, 7
        banksel PORTC
        bsf     PORTC, 5
        call    READ_ROWS_COL1
        xorlw   KP_NONE
        btfss   STATUS, 2
        goto    KS_RET

        ; COL2: RB6 low => 2,5,8,0
        banksel PORTB
        bsf     PORTB, 5
        bcf     PORTB, 6
        bsf     PORTB, 7
        banksel PORTC
        bsf     PORTC, 5
        call    READ_ROWS_COL2
        xorlw   KP_NONE
        btfss   STATUS, 2
        goto    KS_RET

        ; COL3: RB7 low => 3,6,9,#
        banksel PORTB
        bsf     PORTB, 5
        bsf     PORTB, 6
        bcf     PORTB, 7
        banksel PORTC
        bsf     PORTC, 5
        call    READ_ROWS_COL3
        xorlw   KP_NONE
        btfss   STATUS, 2
        goto    KS_RET

        ; COL4: RC5 low => A,B,C,D
        banksel PORTB
        bsf     PORTB, 5
        bsf     PORTB, 6
        bsf     PORTB, 7
        banksel PORTC
        bcf     PORTC, 5
        call    READ_ROWS_COL4
        xorlw   KP_NONE
        btfss   STATUS, 2
        goto    KS_RET

        ; restore all HIGH
        banksel PORTB
        bsf     PORTB, 5
        bsf     PORTB, 6
        bsf     PORTB, 7
        banksel PORTC
        bsf     PORTC, 5

        movlw   KP_NONE
        return

KS_RET:
        xorlw   KP_NONE
        return
; ----------------------------------------------------------
; READ_ROWS_COLx helpers:
;   Each routine checks RB1..RB4 (active-low) and returns the
;   corresponding key code for that column.
; ----------------------------------------------------------
READ_ROWS_COL1:
        banksel PORTB
        btfss   PORTB, 1
        goto    K_1
        btfss   PORTB, 2
        goto    K_4
        btfss   PORTB, 3
        goto    K_7
        btfss   PORTB, 4
        goto    K_STAR
        movlw   KP_NONE
        return

READ_ROWS_COL2:
        banksel PORTB
        btfss   PORTB, 1
        goto    K_2
        btfss   PORTB, 2
        goto    K_5
        btfss   PORTB, 3
        goto    K_8
        btfss   PORTB, 4
        goto    K_0
        movlw   KP_NONE
        return

READ_ROWS_COL3:
        banksel PORTB
        btfss   PORTB, 1
        goto    K_3
        btfss   PORTB, 2
        goto    K_6
        btfss   PORTB, 3
        goto    K_9
        btfss   PORTB, 4
        goto    K_HASH
        movlw   KP_NONE
        return

READ_ROWS_COL4:
        banksel PORTB
        btfss   PORTB, 1
        goto    K_A
        movlw   KP_NONE
        return

K_0:    movlw   0
        return
K_1:    movlw   1
        return
K_2:    movlw   2
        return
K_3:    movlw   3
        return
K_4:    movlw   4
        return
K_5:    movlw   5
        return
K_6:    movlw   6
        return
K_7:    movlw   7
        return
K_8:    movlw   8
        return
K_9:    movlw   9
        return
K_A:    movlw   KEY_A_ASC        ;'A'
        return
K_HASH: movlw   KEY_HASH_ASC     ;'#'
        return
K_STAR: movlw   0x2A              ;'*'
        return

    
; ==========================================================
; 7-SEGMENT DISPLAY (DEMO "  25")
; Design rationale:
;   - Multiplexing drives one digit at a time to reduce I/O usage.
;   - DISP_SET preserves RD0/RD1 so actuator outputs are never corrupted
;     when updating segment outputs on PORTD.
;
; Electrical assumptions:
;   - Segments are Active-LOW:
;       a..f = RD2..RD7, g = RE0, dp = RE1
;   - Digit enables are Active-HIGH:
;       D1..D4 = RC0..RC3
; ==========================================================
DISP_INIT:
         ; Configure RE0, RE1 as outputs (g and dp)
        banksel TRISE
        bcf     TRISE,0
        bcf     TRISE,1

        ; Turn g and dp OFF (active-low -> 1 means OFF)
        banksel PORTE
        bsf     PORTE,0
        bsf     PORTE,1

        call    DISP_DIGITS_OFF      ; Disable all digits initially
        return

DISP_SHOW:
       ; Digit 1: blank (all segments off)
        call    DISP_DIGITS_OFF
        movlw   0xFF               ; Active-low: 0xFF => all segments OFF
        call    DISP_SET
        bsf     PORTC,0             ; Enable D1
        call    DISP_DELAY

         ; Digit 2: blank
        call    DISP_DIGITS_OFF
        movlw   0xFF
        call    DISP_SET
        bsf     PORTC,1              ; Enable D2
        call    DISP_DELAY

         ; Digit 3: show '2'
        call    DISP_DIGITS_OFF
        movlw   0xA4                  ; Pattern for '2' (active-low
        call    DISP_SET
        bsf     PORTC,2                ; Enable D3
        call    DISP_DELAY

        ; Digit 4: show '5'
        call    DISP_DIGITS_OFF
        movlw   0x92                  ; Pattern for '5' (active-low)
        call    DISP_SET
        bsf     PORTC,3                ; Enable D4
        call    DISP_DELAY

        return

DISP_DIGITS_OFF:
        ; Disable all digits to prevent ghosting during segment updates
        banksel PORTC
        bcf     PORTC,0
        bcf     PORTC,1
        bcf     PORTC,2
        bcf     PORTC,3
        return

; ==========================================================
; DISP_SET
; Input: W = segment pattern (active-low) for a..g,dp
; Mapping:
;   bits 0..5 (a..f) -> RD2..RD7 (shift left by 2)
;   bit 6   (g)      -> RE0
;   bit 7   (dp)     -> RE1
;
; Critical detail:
;   RD0 and RD1 must be preserved (heater/fan outputs).
; ==========================================================


DISP_SET:
        ; W = pattern (active-low)
        movwf   TMP             ; Save pattern

        
        ; Preserve RD0..RD1 (actuators); clear other bits for segment update
        banksel PORTD
        movf    PORTD, W
        andlw   0x03           ; Keep only bits 0..1
        movwf   TEMP_WORK

        ; a..f bits 0..5 -> RD2..RD7 (<<2)
        banksel TMP
        movf    TMP, W
        andlw   0x3F             ; Keep bits 0..5
        movwf   TEMP_RAW        ;  TEMP_RAW (1 byte)
        
	; TEMP_RAW <<= 2 (move a..f into RD2..RD7 positions)
        rlf     TEMP_RAW, F     ; <<1
        rlf     TEMP_RAW, F     ; <<2

        banksel TEMP_WORK
        movf    TEMP_RAW, W
        iorwf   TEMP_WORK, F

        banksel PORTD
        movf    TEMP_WORK, W
        movwf   PORTD

        ; g (bit6) -> RE0
        banksel PORTE
        banksel TMP
        btfsc   TMP,6
        bsf     PORTE,0
        btfss   TMP,6
        bcf     PORTE,0

        ; dp (bit7) -> RE1
        btfsc   TMP,7
        bsf     PORTE,1
        btfss   TMP,7
        bcf     PORTE,1

        return

DISP_DELAY:
       ; Short delay to create persistence for multiplexed digits
        banksel DISP_CNT
        movlw     80
        movwf   DISP_CNT
DLY1:
        decfsz  DISP_CNT, F
        goto    DLY1
        return


    END