# PICSimLab Pin Mapping
## Microcontroller: PIC16F877a

---

## BOARD #1 – Home Air Conditioner System


| Modül / Sinyal            | PIC Bacağı | Port Bit | Yön    | Not                      |
| ------------------------- | ---------: | -------: | ------ | ------------------------ |
| **LM35 (Sıcaklık ADC)**   |  RA0 / AN0 |  PORTA.0 | Input  | Analog giriş             |
| **Heater (Isıtıcı)**      |        RD0 |  PORTD.0 | Output | Dijital çıkış            |
| **Fan/Cooler (Soğutma)**  |        RD1 |  PORTD.1 | Output | Dijital çıkış            |
| **Keypad Row 1**          |        RB1 |  PORTB.1 | Input  | Pull-up aktif, basınca 0 |
| **Keypad Row 2**          |        RB2 |  PORTB.2 | Input  | Pull-up aktif, basınca 0 |
| **Keypad Row 3**          |        RB3 |  PORTB.3 | Input  | Pull-up aktif, basınca 0 |
| **Keypad Row 4**          |        RB4 |  PORTB.4 | Input  | Pull-up aktif, basınca 0 |
| **Keypad Col 1**          |        RB5 |  PORTB.5 | Output | Tarama: aktif-LOW        |
| **Keypad Col 2**          |        RB6 |  PORTB.6 | Output | Tarama: aktif-LOW        |
| **Keypad Col 3**          |        RB7 |  PORTB.7 | Output | Tarama: aktif-LOW        |
| **Keypad Col 4**          |        RC5 |  PORTC.5 | Output | Tarama: aktif-LOW        |
| **7-Seg Segment a**       |        RD2 |  PORTD.2 | Output | Active-LOW (0=yanar)     |
| **7-Seg Segment b**       |        RD3 |  PORTD.3 | Output | Active-LOW               |
| **7-Seg Segment c**       |        RD4 |  PORTD.4 | Output | Active-LOW               |
| **7-Seg Segment d**       |        RD5 |  PORTD.5 | Output | Active-LOW               |
| **7-Seg Segment e**       |        RD6 |  PORTD.6 | Output | Active-LOW               |
| **7-Seg Segment f**       |        RD7 |  PORTD.7 | Output | Active-LOW               |
| **7-Seg Segment g**       |        RE0 |  PORTE.0 | Output | Active-LOW               |
| **7-Seg dp**              |        RE1 |  PORTE.1 | Output | Active-LOW               |
| **7-Seg Digit Enable D1** |        RC0 |  PORTC.0 | Output | Active-HIGH (1=aktif)    |
| **7-Seg Digit Enable D2** |        RC1 |  PORTC.1 | Output | Active-HIGH              |
| **7-Seg Digit Enable D3** |        RC2 |  PORTC.2 | Output | Active-HIGH              |
| **7-Seg Digit Enable D4** |        RC3 |  PORTC.3 | Output | Active-HIGH              |


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
