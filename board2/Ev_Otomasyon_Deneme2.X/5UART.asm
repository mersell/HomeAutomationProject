; This source file was written and implemented by
; Student ID: 152120211128
; Name: Sevval Ayca Cerence
    
; This module implements the UART communication layer for the Board #2
; curtain control subsystem. It processes GET and SET commands received
; from the PC side and provides a non-blocking interface for data exchange.
; An override mechanism is used to enforce externally requested curtain
; positions independently of local control logic.

PROCESSOR 16F877A
#include <xc.inc>
#include "comman.inc"

; External variables defined in other modules of the system.
; These shared memory locations provide access to current sensor readings
; and curtain status information required by the UART protocol.

EXTRN   cur_curtain_status, des_curtain_status
EXTRN   outdoor_temp, outdoor_press, light_intensity

; Public UART routines exported for use by the main control loop
; and other system modules.

GLOBAL  uart_init, uart_process

; Local UART state variables used to track the last received command
; and to manage the override mechanism applied to the desired curtain status.

PSECT udata_bank0
u_last_cmd:      DS 1
u_override:      DS 1        ; Indicates whether an external UART override command is currently active
u_des_shadow:    DS 1        ; Shadow copy of the desired curtain value used while override is enabled

PSECT uartCode, class=CODE, delta=2

; ----------------
; uart_init
; ----------------
uart_init:
    ; RC7=RX input, RC6=TX output
    BANKSEL TRISC
    bsf     TRISC, 7
    bcf     TRISC, 6

    ; Baud: 9600 @ 4MHz, BRGH=1 => SPBRG=25 (0x19)
    BANKSEL SPBRG
    movlw   0x19
    movwf   SPBRG

    ; TXSTA: BRGH=1 (bit2), TXEN=1 (bit5), async (SYNC=0)
    BANKSEL TXSTA
    movlw   0x24            ; 0010 0100b = TXEN + BRGH
    movwf   TXSTA

    ; RCSTA: SPEN=1 (bit7), CREN=1 (bit4)
    BANKSEL RCSTA
    movlw   0x90            ; 1001 0000b
    movwf   RCSTA

    ; init override off
    BANKSEL u_override
    clrf    u_override

    BANKSEL 0
    return

; Transmits a single byte via UART using polling.
; The routine waits until the transmit buffer is ready (TXIF set)
; to guarantee reliable data transmission.

uart_send_byte:
    BANKSEL PIR1
u_tx_wait:
    btfss   PIR1, 4         ; TXIF
    goto    u_tx_wait

    BANKSEL TXREG
    movwf   TXREG
    BANKSEL 0
    return

; Main UART service routine executed periodically in the main loop.
; Operates in a non-blocking manner and applies the override logic
; even when no new UART data is received.

uart_process:

    ; If override active, keep des_curtain_status pinned each loop
    BANKSEL u_override
    movf    u_override, W
    btfsc   STATUS, 2       ; Z=1 => override=0
    goto    u_check_rx

    BANKSEL u_des_shadow
    movf    u_des_shadow, W
    BANKSEL des_curtain_status
    movwf   des_curtain_status

u_check_rx:
    ; Handle overrun error (OERR) if happens
    BANKSEL RCSTA
    btfss   RCSTA, 1        ; OERR bit1
    goto    u_rx_flag
    ; clear OERR: CREN=0 then CREN=1
    bcf     RCSTA, 4
    bsf     RCSTA, 4

u_rx_flag:
    BANKSEL PIR1
    btfss   PIR1, 5         ; RCIF
    return                  ; no data

    ; read received byte
    BANKSEL RCREG
    movf    RCREG, W
    BANKSEL u_last_cmd
    movwf   u_last_cmd

    ; If MSB=1 => SET command 0x80..0xBF
    btfsc   u_last_cmd, 7
    goto    u_handle_set

    ; ---------- GET commands ----------
    ; 0x01 desired low  -> 0 (since we store 8-bit)
    movf    u_last_cmd, W
    xorlw   0x01
    btfsc   STATUS, 2
    goto    u_send_zero

    ; 0x02 desired high -> des_curtain_status
    movf    u_last_cmd, W
    xorlw   0x02
    btfsc   STATUS, 2
    goto    u_send_des

    ; 0x03 temp low -> outdoor_temp+1
    movf    u_last_cmd, W
    xorlw   0x03
    btfsc   STATUS, 2
    goto    u_send_temp_low

    ; 0x04 temp high -> outdoor_temp
    movf    u_last_cmd, W
    xorlw   0x04
    btfsc   STATUS, 2
    goto    u_send_temp_high

    ; 0x05 press low -> outdoor_press+1
    movf    u_last_cmd, W
    xorlw   0x05
    btfsc   STATUS, 2
    goto    u_send_press_low

    ; 0x06 press high -> outdoor_press
    movf    u_last_cmd, W
    xorlw   0x06
    btfsc   STATUS, 2
    goto    u_send_press_high

    ; 0x07 light low -> 0 (8-bit)
    movf    u_last_cmd, W
    xorlw   0x07
    btfsc   STATUS, 2
    goto    u_send_zero

    ; 0x08 light high -> light_intensity
    movf    u_last_cmd, W
    xorlw   0x08
    btfsc   STATUS, 2
    goto    u_send_light
    
    ; 0x09 current curtain high -> cur_curtain_status
    movf    u_last_cmd, W
    xorlw   0x09
    btfsc   STATUS, 2
    goto    u_send_cur


    return

u_handle_set:
    ; cmd = 0x80..0xBF, lower 6 bits = 0..63
    BANKSEL u_last_cmd
    movf    u_last_cmd, W
    andlw   0x3F            ; quant 0..63 in W

    ; map 0..63 -> 0..255 (approx): value = quant * 4
    ; (0..252). Good enough & deterministic.
    movwf   u_last_cmd      ; reuse as temp
    rlf     u_last_cmd, F
    rlf     u_last_cmd, F
    movf    u_last_cmd, W

    ; store shadow + override ON
    BANKSEL u_des_shadow
    movwf   u_des_shadow
    movlw   0x01
    movwf   u_override

    ; write to real desired too
    BANKSEL des_curtain_status
    movwf   des_curtain_status
    return

; ---- send helpers ----
u_send_zero:
    movlw   0x00
    call    uart_send_byte
    return

u_send_des:
    BANKSEL des_curtain_status
    movf    des_curtain_status, W
    call    uart_send_byte
    return

u_send_temp_low:
    BANKSEL outdoor_temp
    movf    outdoor_temp+1, W
    call    uart_send_byte
    return

u_send_temp_high:
    BANKSEL outdoor_temp
    movf    outdoor_temp, W
    call    uart_send_byte
    return

u_send_press_low:
    BANKSEL outdoor_press
    movf    outdoor_press+1, W
    call    uart_send_byte
    return

u_send_press_high:
    BANKSEL outdoor_press
    movf    outdoor_press, W
    call    uart_send_byte
    return

u_send_light:
    BANKSEL light_intensity
    movf    light_intensity, W
    call    uart_send_byte
    return

u_send_cur:
    BANKSEL cur_curtain_status
    movf    cur_curtain_status, W
    call    uart_send_byte
    return


END