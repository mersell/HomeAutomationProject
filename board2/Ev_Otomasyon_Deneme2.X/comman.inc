;==========================================================
;   *** HARDWARE DEFINITIONS AND CONSTANTS (COMMAN.INC) ***
;		Author: Zehra Betul Turkmen
;==========================================================

#ifndef COMMAN_INC
#define COMMAN_INC

; --- STEP MOTOR (Curtain Driver) ---
; Connected to the upper 4 bits of PORTB [cite: 890-897].
#define STEP_IN1 PORTB, 4    ; Motor Coil 1 - Control pin RB4[cite: 890].
#define STEP_IN2 PORTB, 5    ; Motor Coil 2 - Control pin RB5[cite: 892].
#define STEP_IN3 PORTB, 6    ; Motor Coil 3 - Control pin RB6[cite: 894].
#define STEP_IN4 PORTB, 7    ; Motor Coil 4 - Control pin RB7[cite: 896].

; --- LDR & POTENTIOMETER (Sensors) ---
; LDR digital output for quick threshold checks [cite: 900-901].
#define LDR_DIGITAL PORTB, 0 ; Connected to RB0[cite: 900].

; Note: RA0 (LDR) and RA1 (Pot) are configured as Analog Inputs .
; They are accessed by selecting the correct ADC channel in the code.

; --- BMP180 SENSOR (I2C Communication) ---
; Standard I2C pins for communication with the BMP180 module [cite: 904-908].
#define I2C_SCL PORTC, 3     ; Serial Clock line on RC3[cite: 907].
#define I2C_SDA PORTC, 4     ; Serial Data line on RC4[cite: 904].

; --- LCD DISPLAY (HD44780) ---
; 8-bit Data Bus and Control pins for the 2x16 LCD [cite: 909-928].
#define LCD_DATA PORTD       ; Full PORTD (RD0-RD7) used for 8-bit data [cite: 909-924].
#define LCD_RS   PORTE, 0    ; Register Select on RE0 [cite: 925-926].
#define LCD_EN   PORTE, 1    ; Enable Pulse on RE1 [cite: 927-928].

; --- SYSTEM CONSTANTS ---
; Calculation: 5 full turns * 200 steps per turn = 1000 total steps[cite: 684].
#define MAX_STEPS 1000       ; Steps required for 0% to 100% curtain movement.

; Mid-point threshold for 8-bit LDR reading (0-255 range).
; If light intensity falls below this value, the curtain will close[cite: 696, 861].
#define LDR_THRESHOLD 128    ; Adjustable light sensitivity level.

#endif