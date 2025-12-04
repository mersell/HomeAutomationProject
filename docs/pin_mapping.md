# PICSimLab Pin Mapping
## Microcontroller: PIC16F877A

---

## BOARD #1 – Home Air Conditioner System

| Module | Signal | PIC Pin | Port | Type |
|--------|--------|---------|------|------|
| Temperature System | Heater | RD0 | PORTD.0 | Digital Output |
| Temperature System | Cooler (Fan) | RD1 | PORTD.1 | Digital Output |
| Temperature System | LM35 Temp | RA0 | AN0 | Analog Input |
| Temperature System | Tachometer | RB0 | RB0/INT | Timer Input |
| UART | RX | RC7 | RX | UART |
| UART | TX | RC6 | TX | UART |
| 7-Segment | Segment a | RD2 | PORTD.2 | Digital Output |
| 7-Segment | Segment b | RD3 | PORTD.3 | Digital Output |
| 7-Segment | Segment c | RD4 | PORTD.4 | Digital Output |
| 7-Segment | Segment d | RD5 | PORTD.5 | Digital Output |
| 7-Segment | Segment e | RD6 | PORTD.6 | Digital Output |
| 7-Segment | Segment f | RD7 | PORTD.7 | Digital Output |
| 7-Segment | Segment g | RE0 | PORTE.0 | Digital Output |
| 7-Segment | DP | RE1 | PORTE.1 | Digital Output |
| 7-Segment | Digit D1 | RC0 | PORTC.0 | Digital Output |
| 7-Segment | Digit D2 | RC1 | PORTC.1 | Digital Output |
| 7-Segment | Digit D3 | RC2 | PORTC.2 | Digital Output |
| 7-Segment | Digit D4 | RC3 | PORTC.3 | Digital Output |
| Keypad | Row 1 | RB1 | PORTB.1 | Digital Input |
| Keypad | Row 2 | RB2 | PORTB.2 | Digital Input |
| Keypad | Row 3 | RB3 | PORTB.3 | Digital Input |
| Keypad | Row 4 | RB4 | PORTB.4 | Digital Input |
| Keypad | Column 1 | RB5 | PORTB.5 | Digital Output |
| Keypad | Column 2 | RB6 | PORTB.6 | Digital Output |
| Keypad | Column 3 | RB7 | PORTB.7 | Digital Output |
| Keypad | Column 4 | RC5 | PORTC.5 | Digital Output |

---

## BOARD #2 – Curtain Control System

| Module | Signal | PIC Pin | Port | Type |
|--------|--------|---------|------|------|
| Step Motor | IN1 | RD0 | PORTD.0 | Digital Output |
| Step Motor | IN2 | RD1 | PORTD.1 | Digital Output |
| Step Motor | IN3 | RD2 | PORTD.2 | Digital Output |
| Step Motor | IN4 | RD3 | PORTD.3 | Digital Output |
| LDR Sensor | A0 | RA0 | AN0 | Analog Input |
| LDR Sensor | D0 | RB0 | PORTB.0 | Digital Input |
| Potentiometer | POT1 | RA1 | AN1 | Analog Input |
| BMP180 | SDA | RC4 | SDA | I2C Data |
| BMP180 | SCL | RC3 | SCL | I2C Clock |
| LCD | D0 | RD0 | PORTD.0 | Digital Output |
| LCD | D1 | RD1 | PORTD.1 | Digital Output |
| LCD | D2 | RD2 | PORTD.2 | Digital Output |
| LCD | D3 | RD3 | PORTD.3 | Digital Output |
| LCD | D4 | RD4 | PORTD.4 | Digital Output |
| LCD | D5 | RD5 | PORTD.5 | Digital Output |
| LCD | D6 | RD6 | PORTD.6 | Digital Output |
| LCD | D7 | RD7 | PORTD.7 | Digital Output |
| LCD | RS | RE0 | PORTE.0 | Digital Output |
| LCD | EN | RE1 | PORTE.1 | Digital Output |
| UART | RX | RC7 | RX | UART |
| UART | TX | RC6 | TX | UART |
