# ==========================================================
# This source file was written and implemented by
# Student ID: 152120211116 
# Name: Merve Selçuk
# ==========================================================

import serial 

class HomeAutomationSystemConnection:
    """
    Base class for all system connections. 
    Manages the low-level Serial Port settings and physical connection to the hardware.
    
    Responsibilities:
    1. Manage COM Port and Baud Rate configurations.
    2. Open/Close the physical UART connection using pySerial.
    3. Define the interface for derived classes (AirConditioner, CurtainControl).
    """

    def __init__(self, port: str, rate: int):
        """
        Constructor: Initializes the connection parameters.
        
        Args:
            port (str): The name of the COM port (e.g., 'COM1', '/dev/ttyUSB0').
            rate (int): The communication speed in bits per second (bps).
        """
        self.comPort = port          # Stores the selected COM port
        self.baudRate = rate         # Stores the baud rate (must match PIC settings)
        self._connection = None      # Placeholder for the actual serial object (initially None)

    def setComPort(self, port: str) -> None:
        """
        Updates the target COM port.
        Useful if the user changes the port from the GUI before connecting.
        """
        self.comPort = port

    def setBaudRate(self, rate: int) -> None:
        """
        Updates the target Baud Rate.
        The default is usually 9600 bps for this project.
        """
        self.baudRate = rate

    # --- MAIN CONNECTION METHODS ---

    def open(self) -> bool:
        """
        Establishes the UART connection with the specific hardware settings.
        
        Configuration Details (8N1):
        - Baudrate: As configured (9600)
        - Byte Size: 8 Bits (Standard ASCII/Binary data)
        - Parity: None (No error checking bit, simpler overhead)
        - Stop Bits: 1 (Standard end-of-frame signal)
        - Timeout: 5.0 seconds (Prevents the PC app from freezing if PIC doesn't respond)
        
        Returns:
            bool: True if connection is successful, False otherwise.
        """
        try:
            # Create a new Serial instance with the specified parameters
            self._connection = serial.Serial(
                self.comPort, 
                self.baudRate, 
                parity=serial.PARITY_NONE,    # Matches PIC TXSTA setup
                stopbits=serial.STOPBITS_ONE, # Matches PIC TXSTA setup
                bytesize=serial.EIGHTBITS,    # Standard data size
                timeout=5.0                   # Read timeout
            )
            print(f"[{self.comPort}] Connection ESTABLISHED successfully.")
            return True
            
        except serial.SerialException as e:
            # Catch errors like "Port busy", "Port not found", or "Permission denied"
            print(f"[{self.comPort}] Connection ERROR: {e}")
            self._connection = None
            return False

    def close(self) -> bool:
        """
        Terminates the active serial connection.
        It is important to release the COM port so other applications can use it.
        """
        if self._connection and self._connection.is_open:
            self._connection.close()
            print(f"[{self.comPort}] Connection CLOSED.")
            return True
        return False

    def update(self):
        """
        Abstract method to be overridden by subclasses.
        
        Design Pattern:
        This enforces a common interface. Both AirConditioner and CurtainControl
        systems MUST implement their own logic to fetch data from the PIC.
        """
        raise NotImplementedError("The update() method must be implemented by the subclass.")
