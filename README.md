# HomeAutomationProject

## About the Project
HomeAutomationProject focuses on the design
and development of an integrated home automation system. The system consists of
a PC-based application, communication APIs, two microcontroller boards
(Board 1 and Board 2), sensors, and a user interface.

UART-based communication between the PC and the microcontroller boards was
successfully implemented. Sensor data were acquired, and user commands were
processed and applied on the hardware side.

This README documents the system architecture, task assignments,
project structure, and GitHub usage standards.

---

## Task Assignments

| Student ID | Team Member | Role / Responsibility | Detailed Description |
|------------|------------|----------------------|----------------------|
| 152120211116 | Merve Selçuk | PC Application & Board 1 UART Integration | • Developed the PC-side user application.<br>• Implemented UART communication with Board 1.<br>• Sent control commands and received sensor data.<br>• Handled data formatting and command parsing.<br>• Performed end-to-end UART communication tests. |
| 152120211128 | Şevval Ayça Çerence | PC Interface & Board 2 UART Communication | • Designed the user interface for system monitoring.<br>• Managed UART communication with Board 2.<br>• Received curtain and sensor data from the microcontroller.<br>• Ensured stable data transmission and error handling.<br>• Organized project files and documentation. |
| 151220222139 | Ganime Yalçın | Board 1 – Temperature & Fan Control Module | • Read temperature data using the LM35 sensor.<br>• Measured fan speed using a tachometer input.<br>• Controlled fan and heater operation based on temperature logic.<br>• Configured ADC settings for accurate analog readings.<br>• Shared sensor data via global variables. |
| 151220222064 | Eyüp Tümer Zengin | Board 1 – Keypad & Display Module | • Implemented keypad scanning and user input handling.<br>• Controlled seven-segment display multiplexing.<br>• Displayed system values visually.<br>• Integrated keypad inputs with system logic. |
| 151220222133 | Zehra Betül Türkmen | Board 2 – Curtain, Sensor & LCD Module | • Controlled curtain movement using a step motor.<br>• Read light intensity via the LDR sensor.<br>• Interfaced with the BMP180 sensor using the I²C protocol.<br>• Displayed temperature, pressure, and light data on the LCD.<br>• Implemented sensor-based automation logic. |

---

## Hardware Components

The main hardware components used in the project are listed below:

- PIC16F877A microcontroller
- LM35 temperature sensor
- LDR (light intensity sensor)
- BMP180 temperature and pressure sensor
- Step motor for curtain control
- 4x4 matrix keypad
- Seven-segment display
- LCD display


## System Overview

The system operates on a distributed architecture where the PC application
acts as the central controller. Communication between the PC and the
microcontroller boards is achieved using UART-based serial communication.

- **Board 1** handles temperature measurement, fan speed control,
  keypad input, and seven-segment display output.
- **Board 2** manages curtain control, environmental sensors,
  and LCD-based data visualization.
- The PC application provides real-time monitoring and user interaction.

---

## Project Status

- All software and hardware modules have been implemented.
- UART communication between the PC and both boards is fully operational.
- Sensor readings and actuator controls function as expected.
- Integration and functional tests have been completed.
- Documentation and repository structure have been finalized.

---

## Software and Tools Used

The following software tools and environments were used during the
development and testing phases of the project:

- MPLAB X IDE
- XC8 (pic-as assembler)
- PICSimLab
- Python
- Git and GitHub
  

