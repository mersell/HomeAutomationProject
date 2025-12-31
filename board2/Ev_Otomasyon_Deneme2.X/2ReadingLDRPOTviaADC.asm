PROCESSOR 16F877A
    #include <xc.inc>
    #include "comman.inc"

;========================================
;   ***SENSOR READ MODULE (LDR + POT)***
;	Author: Zehra Betul Turkmen    
;========================================
;EXTERNAL VARIABLES (Import variables defined in Global.asm to use them here.)
    EXTRN light_intensity, des_curtain_status

;GLOBAL FUNCTIONS
    GLOBAL read_sensors

;LOCAL VARIABLES
PSECT udata_bank0
delay_cnt: DS 1    ; Counter variable for acquisition delay.
pot_temp:  DS 1    ; Temporary storage for POT (AN1) reading.

PSECT adcCode, class=CODE, delta=2

read_sensors:
    ;SECTION 1: LDR READING (AN0 - RA0)
    BANKSEL ADCON0
    movlw   10000001B       ; Loading 10000001B to ADCON0 means Fosc/32,
    movwf   ADCON0          ; Analog Channel 0 (AN0), and ADC module ON.
    
    call    delay_acquisition ; Wait for ADC acquisition time.
    
    BANKSEL ADCON0
    bsf     ADCON0, 2       ; Set GO/DONE bit to start ADC conversion.
    
wait_ldr:
    BANKSEL ADCON0
    btfsc   ADCON0, 2       ; Check if GO/DONE bit = 0.
    goto    wait_ldr        ; If it is still 1, wait for conversion to complete.
    
    ;READ RESULT (It is set to left justified in the main file.)
    BANKSEL ADRESH
    movf    ADRESH, W       ; Load ADRESH (upper 8 bits) into W register.
    BANKSEL light_intensity
    movwf   light_intensity ; Save light intensity value to memory to use it globally.

    ;SECTION 2: POTENTIOMETER READING (AN1 - RA1)
    BANKSEL ADCON0
    movlw   10001001B       ; Loading 10001001B to ADCON0 means Fosc/32, 
    movwf   ADCON0          ; Analog Channel 1 (AN1), and ADC module ON.
    
    call    delay_acquisition ; Wait for ADC acquisition time.
    
    BANKSEL ADCON0
    bsf     ADCON0, 2       ; Set GO/DONE bit to start ADC conversion.
    
wait_pot:
    BANKSEL ADCON0
    btfsc   ADCON0, 2       ; Check if GO/DONE bit = 0.
    goto    wait_pot        ; If it is still 1, wait for conversion to complete.
    
    BANKSEL ADRESH
    movf    ADRESH, W       ; Load ADRESH (upper 8 bits) into W register.
    BANKSEL pot_temp
    movwf   pot_temp        ; Store POT value in a temp variable for later use.

    ;SECTION 3: DARKNESS OVERRIDE LOGIC
    BANKSEL light_intensity
    movf    light_intensity, W	; The threshold value has been set to 128, which is 50%.
    sublw   128			; Compare light value with a threshold using subtraction.
    btfsc   STATUS, 0		; If Carry=1, it means light is below the threshold, meaning dark.
    goto    dark_override	; If it is dark, jump to override section.
    
    ; If bright, use the physical POT value to set curtain status
    BANKSEL pot_temp
    movf    pot_temp, W     ; Load the temporary POT value that was stored for later use.
    movwf   des_curtain_status ; Set desired curtain status.
    return

dark_override:
    ; Force curtain to fully closed state during darkness.
    BANKSEL des_curtain_status
    movlw   255             ; Load 255 (0xFF) representing Full Closed state.
    movwf   des_curtain_status ; Apply override value.
    return

; ADC ACQUISITION TIME FUNCTION
delay_acquisition:
    movlw   50              ; Load loop count.
    movwf   delay_cnt       ; Initialize counter.
delay_acq_loop:
    decfsz  delay_cnt, f    ; Decrement counter, skip if zero.
    goto    delay_acq_loop  ; Loop until delay is complete.
    return

END