PROCESSOR 16F877A
#include <xc.inc>

;========================================
;    ***GLOBAL VARIABLES MODULE***
;     Author: Zehra Betul Turkmen
;========================================    
 
;GLOBAL VARIABLES
; Export these variables so they can be accessed by all other source files.
    GLOBAL cur_curtain_status, des_curtain_status, outdoor_temp, outdoor_press, light_intensity

;VARIABLE DEFINITIONS
; This section allocates memory space (RAM) for the shared variables.
PSECT udata_bank0
cur_curtain_status:   DS 1      ; Current position of the curtain (0 to 255).
des_curtain_status:   DS 1      ; Target position where the curtain should go.
outdoor_temp:         DS 2      ; Outdoor temperature (2 bytes: one for integer, one for decimal).
outdoor_press:        DS 2      ; Barometric pressure (2 bytes to store the 16-bit value).
light_intensity:      DS 1      ; Light level read from the LDR sensor.

END
