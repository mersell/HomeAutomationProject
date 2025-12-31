;================================================
;   *** MAIN SYSTEM CONTROL MODULE ***
;   PIC16F877A - Smart Home Automation Project
;	Author: Zehra Betul Turkmen
;================================================
    PROCESSOR 16F877A
    #include <xc.inc>
    #include "comman.inc"

;CONFIGURATION BITS (High-Speed Crystal and Power Management)
CONFIG  FOSC=HS, WDTE=OFF, PWRTE=ON, BOREN=ON, LVP=OFF, CPD=OFF, WRT=OFF, CP=OFF

;EXTERNAL VARIABLES (Import variables defined in Global.asm to use them here.)
    EXTRN   cur_curtain_status, des_curtain_status
    EXTRN   outdoor_temp, outdoor_press, light_intensity

;EXTERNAL FUNCTIONS (Import functions from other modules to call them in the main loop.) 
    EXTRN   read_sensors
    EXTRN   process_curtain
    EXTRN   uart_init
    EXTRN   uart_process

;LOCAL VARIABLES
PSECT   udata_bank0
d1:             DS 1            ; General delay counter 1.
d2:             DS 1            ; General delay counter 2.
temp_val:       DS 1            ; Temporary storage for calculations.
digit1:         DS 1            ; First digit for display conversion.
digit2:         DS 1            ; Second digit for display conversion.
percent_val:    DS 1            ; Stores curtain percentage (0-100).

PSECT   resetVector, class=CODE, delta=2 ;(Program starts here after power-up or reset.)
resetVec:
    PAGESEL main            ; Select page for main function.
    goto    main            ; Start execution at main label.

PSECT   mainCode, class=CODE, delta=2
main:
;PORT + ADC CONFIGURATION
    BANKSEL ADCON1
    movlw   0x04		; AN0, AN1, and AN3 selected as analog.
    movwf   ADCON1

    BANKSEL TRISB
    movlw   0x0F		; Set RB0-RB3 as inputs, RB4-RB7 as outputs.
    movwf   TRISB

    BANKSEL TRISA
    movlw   0x03		; Set RA0 and RA1 as inputs.
    movwf   TRISA

    BANKSEL TRISD
    clrf    TRISD		; Set all bits of PORTD as output for LCD data.
    BANKSEL TRISE
    clrf    TRISE		; Set all bits of PORTE as output for LCD control.

    BANKSEL TRISC
    movlw   0x98		; Binary 10011000b for UART and I2C.
    movwf   TRISC		; RC7(RX) input, RC6(TX) output, RC3/4 I2C.

    BANKSEL cur_curtain_status	;Initialization of global variables.
    clrf    cur_curtain_status	
    clrf    des_curtain_status

;TESTING VALUES FOR LCD/UART
    BANKSEL outdoor_temp
    movlw   25              ; Set temperature integer part to 25.
    movwf   outdoor_temp
    movlw   5               ; Set temperature decimal part to 5.
    movwf   outdoor_temp+1

    BANKSEL outdoor_press
    movlw   HIGH(1013)      ; Set high byte of 1013 hPa.
    movwf   outdoor_press
    movlw   LOW(1013)       ; Set low byte of 1013 hPa.
    movwf   outdoor_press+1

;INITIALIZATION OF PERIPHERAL MODULES
    call    delay_long      ; Wait for LCD stabilization.
    call    lcd_init        ; Setup LCD screen (8-bit, 2-line).
    
    PAGESEL uart_init
    call    uart_init       ; Setup UART communication.

main_loop:
    ; Step A: Process incoming UART data.
    PAGESEL uart_process
    call    uart_process    ; Process any received UART command if available.

    ; Step B: Read sensors (LDR and POT via ADC).
    PAGESEL read_sensors
    call    read_sensors    ; Update light_intensity + desired curtain (POT or dark override).

    ; Step C: Re-process UART to handle any sensor overrides.
    PAGESEL uart_process
    call    uart_process    ; Keeps override stable even after sensors update the desired value.

;LCD DISPLAY FORMATTING    
    ; --- LCD LINE 1: Display Temp and Pressure ---
    movlw   0x80            ; Set LCD cursor to Line 1, Position 1.
    call    lcd_cmd

    movlw   '+'             ; Load ASCII code for '+' (0x2B).
    call    lcd_char

    BANKSEL outdoor_temp
    movf    outdoor_temp, W ; Get integer part of temperature.
    call    print_2digit    ; Show it as 2 digits.

    movlw   '.'             ; Load ASCII code for '.' (0x2E).
    call    lcd_char

    BANKSEL outdoor_temp
    movf    outdoor_temp+1, W ; Get decimal part of temperature.
    addlw   '0'             ; Load ASCII code for '0' (0x30).
    call    lcd_char

    movlw   0xDF            ; Load ASCII code for degree symbol (0xDF).
    call    lcd_char
    movlw   'C'             ; Load ASCII code for 'C' (0x43).
    call    lcd_char
    movlw   ' '             ; Load ASCII code for ' ' (0x20).
    call    lcd_char

    ; --- LCD LINE 1: Display Constant Pressure --- (Representative Value)
    movlw   '1'             ; Load ASCII code for '1' (0x31).
    call    lcd_char
    movlw   '0'             ; Load ASCII code for '0' (0x30).
    call    lcd_char
    movlw   '1'             ; Load ASCII code for '1' (0x31).
    call    lcd_char
    movlw   '3'             ; Load ASCII code for '3' (0x33).
    call    lcd_char
    movlw   'h'             ; Load ASCII code for 'h' (0x68).
    call    lcd_char
    movlw   'P'             ; Load ASCII code for 'P' (0x50).
    call    lcd_char
    movlw   'a'             ; Load ASCII code for 'a' (0x61).
    call    lcd_char

    ; --- LCD LINE 2: Display Lux and Percentage ---
    movlw   0xC0            ; Set LCD cursor to Line 2, Position 1.
    call    lcd_cmd
    
    ; Show the LDR value on LCD (If it gets too high, just display 255).
    BANKSEL light_intensity
    movf    light_intensity, W	; Get current LDR value.
    movwf   temp_val
    movlw   250             
    subwf   temp_val, W		; Compare: temp_val - 250.
    btfss   STATUS, 0		; If Carry is 0, temp_val < 250.
    goto    check_lux_finished
    movlw   255			; If >= 250, set to 255 for display.
    movwf   temp_val
	
check_lux_finished:
    movf    temp_val, W
    call    print_5digit	; Show 5-digit Lux value.

    movlw   'L'			; Load ASCII code for 'L' (0x4C).
    call    lcd_char
    movlw   'u'			; Load ASCII code for 'u' (0x75).
    call    lcd_char
    movlw   'x'			; Load ASCII code for 'x' (0x78).
    call    lcd_char
    movlw   ' '			; Load ASCII code for ' ' (0x20).
    call    lcd_char

;CURTAIN PERCENTAE CALCULATION (0..255 to 0..100%)
    BANKSEL cur_curtain_status
    movf    cur_curtain_status, W   ; Get current motor position.
    call    convert_255_to_100

    BANKSEL percent_val
    movf    percent_val, W
    xorlw   100			    ; Compare with 100.
    btfss   STATUS, 2		    ; If Zero bit is not set, it's not 100.
    goto    show_regular_percent    ; Compute percent_val.

    ; Case: Exactly 100%
    movlw   '1'			; Load ASCII code for '1' (0x31).
    call    lcd_char
    movlw   '0'			; Load ASCII code for '0' (0x30).
    call    lcd_char
    movlw   '0'			; Load ASCII code for '0' (0x30).
    call    lcd_char
    goto    show_percent_sign

show_regular_percent:
    BANKSEL percent_val
    movf    percent_val, W
    call    print_2digit	; Show as 2 digits.

show_percent_sign:
    movlw   '.'			; Load ASCII code for '.' (0x2E).
    call    lcd_char
    movlw   '0'			; Load ASCII code for '0' (0x30).
    call    lcd_char
    movlw   '%'			; Load ASCII code for '%' (0x25).
    call    lcd_char

    ; Step D: Execute curtain movement logic.
    PAGESEL process_curtain
    call    process_curtain	; Move the motor one step if desired is not equal to current.

    call    delay_short		; Wait before next loop.
    goto    main_loop		; Repeat indefinitely.

;CONVERSION FROM (0-255) TO (0-100) FUNCTION
convert_255_to_100:
    BANKSEL temp_val
    movwf   temp_val

    ; If input is exactly 255, set to 100% manually.
    movf    temp_val, W
    xorlw   0xFF		; Make a comperison.
    btfss   STATUS, 2		; If value equals 255, Zero flag becomes 1.
    goto    calculate_percentage
    movlw   100
    movwf   percent_val
    return

calculate_percentage:		; percent = (value * 100) / 256
    clrf    digit1		; Stores high byte of result.
    clrf    digit2		; Stores low byte.
    movlw   100
    movwf   d1			; Multiply loop counter.
multiply_loop:
    movf    temp_val, W
    addwf   digit2, F		; Add value to low byte.
    btfsc   STATUS, 0		; Check for carry into high byte.
    INCF    digit1, F
    decfsz  d1, F		; Repeat 100 times.
    goto    multiply_loop

    movf    digit1, W		; The high byte is our percentage result.
    movwf   percent_val

    ; Safety Clamp: Don't allow values above 100.
    movlw   101
    subwf   percent_val, W
    btfss   STATUS, 0        ; If percent_val < 101, it's safe.
    return
    movlw   100
    movwf   percent_val      ; Else, force to 100.
    return

;LCD FUNCTIONS
lcd_init:
    movlw   0x38            ; 8-bit mode, 2-line.
    call    lcd_cmd
    movlw   0x0C            ; Display ON, No cursor.
    call    lcd_cmd
    movlw   0x01            ; Clear LCD screen.
    call    lcd_cmd
    call    delay_long      ; Wait for clear to finish.
    movlw   0x06            ; Increment cursor automatically.
    call    lcd_cmd
    return

lcd_cmd:
    BANKSEL PORTD
    movwf   PORTD           ; Load command to PORTD.
    BANKSEL PORTE
    bcf     PORTE, 0        ; RS=0 for Command mode.
    bsf     PORTE, 1        ; Enable Pulse ON.
    call    delay_short
    bcf     PORTE, 1        ; Enable Pulse OFF.
    call    delay_short
    return

lcd_char:
    BANKSEL PORTD
    movwf   PORTD           ; Load character to PORTD.
    BANKSEL PORTE
    bsf     PORTE, 0        ; RS=1 for Data mode.
    bsf     PORTE, 1        ; Enable Pulse ON.
    call    delay_short
    bcf     PORTE, 1        ; Enable Pulse OFF.
    call    delay_short
    return

;PRINTING FUNCTIONS
print_2digit:
    BANKSEL temp_val
    movwf   temp_val
    clrf    digit1          ; Tens counter.
count_tens:
    movlw   10
    subwf   temp_val, W     ; Try subtracting 10.
    btfss   STATUS, 0       ; If negative, stop counting tens.
    goto    show_ones
    movlw   10
    subwf   temp_val, F     ; Apply subtraction.
    INCF    digit1, F       ; Increment tens digit.
    goto    count_tens
show_ones:
    movf    digit1, W
    addlw   '0'             ; Load ASCII code for '0' (0x30).
    call    lcd_char
    movf    temp_val, W
    addlw   '0'             ; Load ASCII code for '0' (0x30).
    call    lcd_char
    return

print_5digit:
    BANKSEL temp_val
    movwf   temp_val
    movlw   '0'             ; Load ASCII code for '0' (0x30).
    call    lcd_char
    movlw   '0'             ; Load ASCII code for '0' (0x30).
    call    lcd_char

    clrf    digit1          ; Hundreds counter.
count_hundreds:
    movlw   100
    subwf   temp_val, W
    btfss   STATUS, 0       ; If negative, stop counting hundreds.
    goto    count_tens_digit
    movlw   100
    subwf   temp_val, F
    INCF    digit1, F
    goto    count_hundreds
count_tens_digit:
    movf    digit1, W
    addlw   '0'             ; Load ASCII code for '0' (0x30).
    call    lcd_char

    clrf    digit2          ; Tens counter.
loop_tens:
    movlw   10
    subwf   temp_val, W
    btfss   STATUS, 0
    goto    show_ones_digit
    movlw   10
    subwf   temp_val, F
    INCF    digit2, F
    goto    loop_tens
show_ones_digit:
    movf    digit2, W
    addlw   '0'             ; Load ASCII code for '0' (0x30).
    call    lcd_char
    movf    temp_val, W
    addlw   '0'             ; Load ASCII code for '0' (0x30).
    call    lcd_char
    return

;DELAY FUNCTIONS
delay_short:
    movlw   50              ; Load count for short delay.
    movwf   d1
short_delay_loop:
    decfsz  d1, F           ; Decrement; skip if zero.
    goto    short_delay_loop
    return

delay_long:
    movlw   200             ; Outer loop start value.
    movwf   d1
outer_delay_loop:
    movlw   200             ; Inner loop start value.
    movwf   d2
inner_delay_loop:
    decfsz  d2, F           ; Decrement inner counter.
    goto    inner_delay_loop
    decfsz  d1, F           ; Decrement outer counter.
    goto    outer_delay_loop
    return

    END resetVec