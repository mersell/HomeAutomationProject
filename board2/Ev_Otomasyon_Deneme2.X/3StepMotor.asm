PROCESSOR 16F877A
    #include <xc.inc>
    #include "comman.inc"

;========================================
;   ***STEP MOTOR CONTROL MODULE***
;     Author: Zehra Betul Turkmen
;========================================    
    
;EXTERNAL VARIABLES (Import variables defined in Global.asm to use them here.)
    EXTRN cur_curtain_status, des_curtain_status

;GLOBAL FUNCTIONS (Export local functions to make them accessible by other source files.)
    GLOBAL process_curtain

;LOCAL VARIABLES
PSECT udata_bank0
delay_cnt: DS 1			    ; Counter variable by motor delay loop.

PSECT motorCode, class=CODE, delta=2

process_curtain:
;1. COMPARISON: Check if Desired status = Current status
    BANKSEL des_curtain_status
    movf    des_curtain_status, W ; Load desired status into W.
    BANKSEL cur_curtain_status
    subwf   cur_curtain_status, W ; Subtract desired status from current status.
    btfsc   STATUS, 2             ; If Zero bit is set, values are equal.
    return                        ; No movement required if they are equal.

; 2. DIRECTION LOGIC: Determine CW or CCW movement
    ;If des > cur => Close (CCW) , If des < cur => Open (CW)
    BANKSEL cur_curtain_status
    movf    cur_curtain_status, W ; Load current status into W.
    BANKSEL des_curtain_status
    subwf   des_curtain_status, W ; Subtract desired status from current status.
    btfss   STATUS, 0             ; If Carry bit is clear, then des < cur (open direction)
    goto    open_curtain          ; Jump to opening sequence (CW).

close_curtain:			  ; Counter-Clockwise (CCW) movement to close the curtain.
    BANKSEL cur_curtain_status
    INCF    cur_curtain_status, W ; W = cur + 1 (Test for overflow).
    btfsc   STATUS, 2             ; If Zero bit is set, cur was 255 and overflow happened.
    return                        ; Fully closed, stop incrementing.

    call    step_ccw              ; Execute one step in CCW direction.
    BANKSEL cur_curtain_status
    INCF    cur_curtain_status, f ; Increment current position in memory.
    return

open_curtain:			  ; Clockwise (CW) movement to open the curtain.
    BANKSEL cur_curtain_status
    movf    cur_curtain_status, W ; Load current status into W.
    btfsc   STATUS, 2             ; If Zero bit is set , cur is 0.
    return                        ; Fully open, stop decrementing.

    call    step_cw               ; Execute one step in CW direction.
    BANKSEL cur_curtain_status
    decf    cur_curtain_status, f ; Decrement current position in memory.
    return

;STEP MOTOR SEQUENCES
; Full Step Sequence <RB7:4>: 1000, 0100, 0010, 0001 for CW.

step_cw:
    ; Clockwise (CW) - Sequence to turn the motor step by step.
    BANKSEL PORTB
    
    ; Step 1: Turn on the pin RB7
    movlw   10000000B             ; Set RB7 to high to start the move.
    movwf   PORTB                 ; Send the signal to the motor.
    call    delay_motor           ; Wait for the motor to turn.
    
    ; Step 2: Turn on the pin RB6
    movlw   01000000B             ; Set RB6 to high.
    movwf   PORTB                 ; Send the signal to the motor.
    call    delay_motor           ; Wait for the motor to turn.
    
    ; Step 3: Turn on the pin RB5
    movlw   00100000B             ; Set RB5 to high.
    movwf   PORTB                 ; Send the signal to the motor.
    call    delay_motor           ; Wait for the motor to turn.
    
    ; Step 4: Turn on the pin RB4
    movlw   00010000B             ; Set RB4 to high.
    movwf   PORTB                 ; Send the signal to the motor.
    call    delay_motor           ; Wait for the motor to turn.
    
    ; STOP MOTOR: Turn off the motor pins to save energy.
    BANKSEL PORTB
    movf    PORTB, W              ; Get the current status of all pins on PORTB.
    andlw   0x0F                  ; Set pins RB4-RB7 to 0 and keep the others as they are.
    movwf   PORTB                 ; Send the new values to PORTB to stop the motor.
    
    return

step_ccw:
    ; Counter-Clockwise (CCW) - Sequence to turn the motor the step by step but in reverse direction.
    BANKSEL PORTB
    
    ; Step 1: Turn on pin RB4
    movlw   00010000B             ; Set RB4 to high to start moving backward.
    movwf   PORTB                 ; Send the signal to the motor.
    call    delay_motor           ; Wait for the motor to turn.
    
    ; Step 2: Turn on pin RB5
    movlw   00100000B             ; Set RB5 to high.
    movwf   PORTB                 ; Send the signal to the motor.
    call    delay_motor           ; Wait for the motor to turn.
    
    ; Step 3: Turn on pin RB6
    movlw   01000000B             ; Set RB6 to high.
    movwf   PORTB                 ; Send the signal to the motor.
    call    delay_motor           ; Wait for the motor to turn.
    
    ; Step 4: Turn on pin RB7
    movlw   10000000B             ; Set RB7 to high.
    movwf   PORTB                 ; Send the signal to the motor.
    call    delay_motor           ; Wait for the motor to turn.
    
    ; STOP MOTOR: Turn off the motor pins to save energy.
    BANKSEL PORTB
    movf    PORTB, W              ; Get the current status of all pins on PORTB.
    andlw   0x0F                  ; Set pins RB4-RB7 to 0 and keep the others as they are.
    movwf   PORTB                 ; Send the new values to PORTB to stop the motor.

    return

; STEP MOTOR TIME FUNCTION
delay_motor:                      ; Delay to slow down stepping speed
    movlw   100                   ; Load loop count. It determines the step speed.
    movwf   delay_cnt            
d_loop:
    decfsz  delay_cnt, f          ; Decrement counter, stop when it reaches 0.
    goto    d_loop                ; Wait until delay_cnt becomes zero.
    return

END