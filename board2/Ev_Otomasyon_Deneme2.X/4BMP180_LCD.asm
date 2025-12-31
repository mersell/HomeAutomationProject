PROCESSOR 16F877A
    #include <xc.inc>
    #include "comman.inc"

;========================================
;    ***BMP180 + LCD DISPLAY MODULE***
;	Author: Zehra Betul Turkmen
;========================================

;EXTERNAL VARIABLES (Import variables defined in other files to use them here.)
    EXTRN outdoor_temp, outdoor_press, light_intensity, cur_curtain_status    
    
;GLOBAL FUNCTIONS (Export local functions to make them accessible by other source files.)
    GLOBAL update_display       

;LOCAL VARIABLES
PSECT udata_bank0
d1:          DS 1               ; General delay counter 1.
d2:          DS 1               ; General delay counter 2.
temp_h:      DS 1               ; Local storage for temperature integer part.
temp_l:      DS 1               ; Local storage for temperature decimal part.
press_h:     DS 1               ; Local storage for pressure high byte.
press_l:     DS 1               ; Local storage for pressure low byte.
digit1:      DS 1               ; Storage for the first digit during conversion.
digit2:      DS 1               ; Storage for the second digit.
digit3:      DS 1               ; Storage for the third digit.
digit4:      DS 1               ; Storage for the fourth digit.
temp_val:    DS 1               ; Temporary math variable.
percent_val: DS 1               ; Stores the calculated curtain percentage (0-100).

PSECT bmpLcdCode, class=CODE, delta=2

update_display:
    call    read_sensor_data         ; Get temperature and pressure values.
    call    lcd_display_all     ; Show all the information on the LCD.
    return


;BMP180 READ (TEST VERSION) (This part uses simple numbers to see if the LCD works.)
read_sensor_data:
    ; Load fake temperature: 25.5°C
    movlw   25                  ; Load integer part (25).
    movwf   temp_h              ; Save it locally.
    movlw   5                   ; Load decimal part (5).
    movwf   temp_l              ; Save it locally.
    
    ; Copy values to global variables
    movf    temp_h, W           ; Get integer part into W.
    movwf   outdoor_temp        ; Save to the main temperature variable.
    movf    temp_l, W           ; Get decimal part into W.
    movwf   outdoor_temp+1      ; Save to the decimal storage.
    
    ; Load fake pressure: 1013 hPa
    movlw   HIGH(1013)          ; Get the high part of 1013.
    movwf   press_h             ; Save it locally.
    movlw   LOW(1013)           ; Get the low part of 1013.
    movwf   press_l             ; Save it locally.
    
    ; Copy values to global variables
    movf    press_h, W          ; Get pressure high byte.
    movwf   outdoor_press       ; Save to the main pressure variable.
    movf    press_l, W          ; Get pressure low byte.
    movwf   outdoor_press+1     ; Save to the second pressure byte.
    
    return

;LCD FUNCTIONS(LCD uses PORTD as data bus (D0-D7) and PORTE pins as control signals.)
lcd_init:
    call    delay_long          ; Wait for LCD to stabilize.
    
    movlw   0x38                ; Set LCD to 8-bit mode and 2 lines.
    call    lcd_send_command             ; Send the command.
    
    movlw   0x0C                ; Turn display ON and hide the cursor.
    call    lcd_send_command             ; Send the command.
    
    movlw   0x01                ; Clear everything on the screen.
    call    lcd_send_command             ; Send the command.
    call    delay_long          ; Wait for the clear to finish.
    
    movlw   0x06                ; Set cursor to move right.
    call    lcd_send_command             ; Send the command.
    
    return

;LCD COMMAND AND CHARACTER FUNCTIONS
lcd_send_command:
    BANKSEL PORTD
    movwf   PORTD               ; Put the command code on PORTD.
    BANKSEL PORTE
    bcf     LCD_RS             ; Select command mode (RS = 0).
    bcf     PORTE, 2            ; Select write mode (RW = 0).
    bsf     LCD_EN              ; Enable pulse starts (EN = 1).
    call    delay_short         ; Short delay for LCD timing.
    bcf     LCD_EN              ; Latch command (EN = 0).
    call    delay_short         ; Wait command execution time.
    return

lcd_char:
    BANKSEL PORTD
    movwf   PORTD               ; Put character byte on LCD data pins.

    BANKSEL PORTE
    bsf     LCD_RS              ; Select character mode (RS = 1).
    bcf     PORTE, 2            ; Select write mode (RW = 0).
    bsf     LCD_EN              ; Enable pulse starts (EN = 1).
    call    delay_short         ; Short delay for LCD timing.
    bcf     LCD_EN              ; Latch data (EN = 0).
    call    delay_short         ; Wait write completion time.
    return

;LCD DISPLAY FORMATTING
lcd_display_all:
    ; --- LINE 1: TEMPERATURE AND PRESSURE ---
	;Display Temperature
    movlw   0x80                ; Set cursor to the start of the first line.
    call    lcd_send_command             
    
    movlw   '+'                 ; Load ASCII code for '+' (0x2B).
    call    lcd_char            
    
    movf    outdoor_temp, W     ; Get temperature integer.
    call    print_2digit        ; Show it as two numbers.
    
    movlw   '.'                 ; Load ASCII code for '.' (0x2E).
    call    lcd_char            
    
    movf    outdoor_temp+1, W   ; Get temperature decimal.
    addlw   '0'                 ; Load ASCII code for '0' (0x30).
    call    lcd_char            
    
    movlw   0xDF                ; Load ASCII code for degree symbol (0xDF).
    call    lcd_char            
    
    movlw   'C'                 ; Load ASCII code for 'C' (0x43).
    call    lcd_char            
    
    movlw   ' '                 ; Load ASCII code for ' ' (0x20).
    call    lcd_char            
    
	;Display Pressure (It is stored in 2 bytes: high + low.)
    movf    outdoor_press, W    ; Load pressure high byte.
    movwf   temp_h              ; Save to local variable for printing.
    movf    outdoor_press+1, W  ; Load pressure low byte.
    movwf   temp_l              ; Save to local variable for printing.
    call    print_16bit_pressure  ; Show 4-digit pressure.
    
    movlw   'h'                 ; Load ASCII code for 'h' (0x68).
    call    lcd_char            
    movlw   'P'                 ; Load ASCII code for 'P' (0x50).
    call    lcd_char            
    movlw   'a'                 ; Load ASCII code for 'a' (0x61).
    call    lcd_char            
    
    ; --- LINE 2: LUX AND CURTAIN STATUS ---
    movlw   0xC0                ; Set cursor to the start of the second line.
    call    lcd_send_command             
    
    movf    light_intensity, W  ; Load light intensity value (0-255).
    call    print_5digit        ; Show it as 5 digits.
    
    movlw   'L'                 ; Load ASCII code for 'L' (0x4C).
    call    lcd_char            
    movlw   'u'                 ; Load ASCII code for 'u' (0x75).
    call    lcd_char            
    movlw   'x'                 ; Load ASCII code for 'x' (0x78).
    call    lcd_char            
    
    movlw   ' '                 ; Load ASCII code for ' ' (0x20).
    call    lcd_char            
    
	;Show Curtain Percentage
    movf    cur_curtain_status, W ; Get 0-255 status.
    call    convert_to_percent  ; Change it to 0-100%.
    
    movf    percent_val, W      ; Check if it is exactly 100%.
    xorlw   100                 
    btfss   STATUS, 2           
    goto    show_normal_percent     
    
    movlw   '1'                 ; Load ASCII code for '1' (0x31).
    call    lcd_char
    movlw   '0'                 ; Load ASCII code for '0' (0x30).
    call    lcd_char
    movlw   '0'                 ; Load ASCII code for '0' (0x30).
    call    lcd_char
    goto    curtain_decimal     
    
show_normal_percent:
    movf    percent_val, W      ; Show regular percentage.
    call    print_2digit        
    
curtain_decimal:
    movlw   '.'                 ; Load ASCII code for '.' (0x2E).
    call    lcd_char            
    movlw   '0'                 ; Load ASCII code for '0' (0x30).
    call    lcd_char            
    movlw   '%'                 ; Load ASCII code for '%' (0x25).
    call    lcd_char            
    
    return

;MATH AND CONVERSION FUNCTIONS	;Input: W = value (0-255)
convert_to_percent:		;Output: percent_val = (value*100)/256  (0-100)
				
    movwf   temp_val            
    movf    temp_val, W         
    xorlw   255                 ; Compare with 255.
    btfss   STATUS, 2           ; Z=1 if value=255.
    goto    percent_normal      
    movlw   100                 
    movwf   percent_val         
    return
    
percent_normal:
    clrf    digit1		; It works like a counter for percentage result.

percent_loop:
    movlw   3                   
    subwf   temp_val, W         ; Check if temp_val is greater or equal to 3.
    btfss   STATUS, 0           
    goto    percent_done        
    movlw   3                   
    subwf   temp_val, F		; temp_val = temp_val - 3.    
    INCF    digit1, F           
    movf    digit1, W           
    sublw   100			; Stop at 100.   
    btfsc   STATUS, 2           
    goto    percent_done        
    goto    percent_loop        
    
percent_done:
    movf    digit1, W		; Move result into percent_val. 
    movwf   percent_val         
    return

print_2digit:
    movwf   temp_val		; Save input number into temp_val.       
    clrf    digit1              
count_tens:
    movlw   10                  
    subwf   temp_val, W		; Check if temp_val is greater or equal to 10      
    btfss   STATUS, 0           
    goto    show_ones            
    movlw   10
    subwf   temp_val, F		; temp_val = temp_val - 10.      
    INCF    digit1, F           
    goto    count_tens            

show_ones:
    movf    digit1, W           
    addlw   '0'                 ; Load ASCII code for '0' (0x30).
    call    lcd_char            
    movf    temp_val, W         
    addlw   '0'                 ; Load ASCII code for '0' (0x30).
    call    lcd_char            
    return

print_5digit:
    movwf   temp_val            
    clrf    digit1              
find_hundreds:
    movlw   100                 
    subwf   temp_val, W         
    btfss   STATUS, 0           
    goto    find_tens            
    movlw   100
    subwf   temp_val, F         
    INCF    digit1, F           
    goto    find_hundreds            

find_tens:
    clrf    digit2              
tens_loop:
    movlw   10                  
    subwf   temp_val, W         
    btfss   STATUS, 0           
    goto    finish_5_digits            
    movlw   10
    subwf   temp_val, F         
    INCF    digit2, F           
    goto    tens_loop       

finish_5_digits:
    movlw   '0'                 ; Load ASCII code for '0' (0x31).
    call    lcd_char            
    movlw   '0'                 ; Load ASCII code for '0' (0x31).
    call    lcd_char            
    movf    digit1, W           
    addlw   '0'                 ; Load ASCII code for '0' (0x30).
    call    lcd_char            
    movf    digit2, W           
    addlw   '0'                 ; Load ASCII code for '0' (0x30).
    call    lcd_char            
    movf    temp_val, W         
    addlw   '0'                 ; Load ASCII code for '0' (0x30).
    call    lcd_char            
    return

print_16bit_pressure:
    ; Mock: Just show "1013" directly.
    movlw   '1'                 ; Load ASCII code for '1' (0x31).
    call    lcd_char
    movlw   '0'                 ; Load ASCII code for '0' (0x30).
    call    lcd_char
    movlw   '1'                 ; Load ASCII code for '1' (0x31).
    call    lcd_char
    movlw   '3'                 ; Load ASCII code for '3' (0x33).
    call    lcd_char
    return

;DELAY FUNCTIONS

delay_short:
    movlw   50                  
    movwf   d1                  
ds_loop:
    decfsz  d1, F               
    goto    ds_loop             
    return

delay_long:
    movlw   30                  
    movwf   d1                  
loop1:
    movlw   255                 
    movwf   d2                  
loop2:
    decfsz  d2, F               
    goto    loop2               
    decfsz  d1, F               
    goto    loop1               
    return

END