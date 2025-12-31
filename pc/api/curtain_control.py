# pc/api/air_conditioner.py

# ==========================================================
# This source file was written and implemented by
# Student ID: 152120211116 
# Name: Merve Selçuk
# ==========================================================

import time
from .connection_base import HomeAutomationSystemConnection

# =========================================================================
# UART PROTOCOL CONSTANTS
# These values correspond exactly to the firmware logic in 'Board1.asm'.
# =========================================================================

# GET COMMANDS (PC -> PIC)
# When sent, the PIC responds with the requested byte.
GET_DESIRED_TEMP_LOW  = 0b00000001  # Request fractional part of target temp
GET_DESIRED_TEMP_HIGH = 0b00000010  # Request integral part of target temp
GET_AMBIENT_TEMP_LOW  = 0b00000011  # Request fractional part of sensor reading
GET_AMBIENT_TEMP_HIGH = 0b00000100  # Request integral part of sensor reading
GET_FAN_SPEED         = 0b00000101  # Request current fan speed (rps)

# SET COMMAND MASKS (PC -> PIC)
# The protocol uses the upper 2 bits to identify the command type.
# Format: [1] [Type] [Data5]...[Data0]
SET_LOW_MASK  = 0b10000000 # 10xxxxxx -> Writes to Desired Temp LOW (Fractional)
SET_HIGH_MASK = 0b11000000 # 11xxxxxx -> Writes to Desired Temp HIGH (Integral)

class AirConditionerSystemConnection(HomeAutomationSystemConnection):
    """
    API Class for Board #1 (Air Conditioner).
    Handles the specific logic for Temperature Control and Fan Monitoring.
    """
    def __init__(self, port: str, rate: int):
        super().__init__(port, rate)
        # Initialize local storage for system state
        self.desiredTemperature: float = 0.0   # Target temperature set by user
        self.ambientTemperature: float = 0.0   # Actual temperature read from LM35
        self.fanSpeed: int = 0                 # Fan speed in rotations per second

    # --- HELPER FUNCTIONS ---

    def _bytes_to_float(self, integral_byte: int, fractional_byte: int) -> float:
        """
        Reconstructs a float value from two separate bytes.
        
        Logic:
        - The PIC sends temperature as two integers: e.g., 25 and 5.
        - We mask them with 0x3F (00111111) to ensure we only take the data bits.
        - Formula: Value = Integral + (Fractional / 10.0)
        - Example: 25 + (5 / 10.0) = 25.5
        """
        integral = integral_byte & 0x3F
        fractional = fractional_byte & 0x3F
        return float(integral) + float(fractional) / 10.0

    def _read_and_process(self, command_byte: int) -> int:
        """
        Low-level transaction: Sends a request byte and waits for a response.
        Includes basic error handling for serial communication.
        """
        if self._connection and self._connection.is_open:
            try:
                # 1. Send the command (e.g., GET_AMBIENT_TEMP_LOW)
                self._connection.write(bytes([command_byte]))
                
                # 2. Block until 1 byte is received or timeout occurs
                response = self._connection.read(1)
                
                if response:
                    return response[0] # Return the integer value of the byte
            except Exception as e:
                print(f"UART Transmission Error: {e}")
        return 0 # Return 0 if failed

    # --- MAIN API METHODS ---

    def update(self) -> None:
        """
        Synchronization Routine.
        Queries the PIC for all sensor data and updates the local state.
        Called periodically by the GUI or Main Loop.
        """
        if not self._connection or not self._connection.is_open:
            return

        # --- STEP 1: Get Ambient Temperature ---
        # We read Low and High bytes separately.
        ambient_frac = self._read_and_process(GET_AMBIENT_TEMP_LOW)
        time.sleep(0.05) # Delay to let PIC process the UART interrupt
        ambient_int  = self._read_and_process(GET_AMBIENT_TEMP_HIGH)
        
        self.ambientTemperature = self._bytes_to_float(ambient_int, ambient_frac)
        time.sleep(0.05)
        
        # --- STEP 2: Get Fan Speed ---
        fan_byte = self._read_and_process(GET_FAN_SPEED)
        self.fanSpeed = fan_byte
        time.sleep(0.05)
        
        # --- STEP 3: Get Current Target Temperature ---
        # This ensures the UI stays in sync if the user used the physical Keypad.
        desired_frac = self._read_and_process(GET_DESIRED_TEMP_LOW)
        time.sleep(0.05)
        desired_int  = self._read_and_process(GET_DESIRED_TEMP_HIGH)
        
        self.desiredTemperature = self._bytes_to_float(desired_int, desired_frac)

    def setDesiredTemp(self, temp: float) -> bool:
        """
        Sends a new target temperature to the PIC.
        
        Protocol Steps:
        1. Validate range (10-50 C).
        2. Split float into Integral and Fractional integers.
        3. Apply bitmasks to create command bytes.
        4. Send Fractional part -> Wait -> Send Integral part.
        """
        if not self._connection or not self._connection.is_open:
            return False

        # Range Check
        if not (10.0 <= temp <= 50.0):
            print(f"Error: {temp}°C is out of bounds (10.0 - 50.0).")
            return False

        # Data Preparation
        integral = int(temp)
        fractional = int(round((temp - integral) * 10))

        # Create Protocol Packets
        # OR operation combines the Command Mask (e.g., 10000000) with Data (e.g., 00000101)
        integral_cmd_byte = SET_HIGH_MASK | (integral & 0x3F) 
        fractional_cmd_byte = SET_LOW_MASK | (fractional & 0x3F)

        # Transmission
        # We send the Fractional part first.
        self._connection.write(bytes([fractional_cmd_byte]))
        
        # CRITICAL TIMING DELAY:
        # The PIC main loop handles 7-Segment Multiplexing. If we send bytes too fast,
        # the UART interrupt might trigger while the PIC is busy, causing data loss.
        # 100ms gives the PIC enough cycles to process the first byte.
        time.sleep(0.1) 
        
        # Send the Integral part.
        self._connection.write(bytes([integral_cmd_byte]))
        
        # Update local state immediately for UI responsiveness
        self.desiredTemperature = temp
        print(f"Command Sent: Set Temp to {temp}°C")
        return True

    # --- GETTER METHODS ---
    
    def getAmbientTemp(self) -> float:
        return self.ambientTemperature
    
    def getFanSpeed(self) -> int:
        return self.fanSpeed

    def getDesiredTemp(self) -> float:
        return self.desiredTemperature
