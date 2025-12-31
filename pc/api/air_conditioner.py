## ==========================================================
# This source file was written and implemented by
# Student ID: 152120211116 
# Name: Merve Selçuk
# ==========================================================
#  pc/api/air_conditioner.py
import time
from .connection_base import HomeAutomationSystemConnection

# =========================================================================
# UART COMMAND DEFINITIONS
# These constants define the protocol used to communicate with Board #1.
# Matches the Assembly definitions in 'Board1.asm'.
# =========================================================================

# GET Commands: 0b00000xxx (Requests data from PIC)
GET_DESIRED_TEMP_LOW  = 0b00000001
GET_DESIRED_TEMP_HIGH = 0b00000010
GET_AMBIENT_TEMP_LOW  = 0b00000011 # Request Ambient Temp Fractional Part
GET_AMBIENT_TEMP_HIGH = 0b00000100 # Request Ambient Temp Integral Part
GET_FAN_SPEED         = 0b00000101 # Request Fan Speed (rps)

# SET Commands: Bitmasks for sending data to PIC
# Format: 10xxxxxx (Low Byte) and 11xxxxxx (High Byte)
SET_LOW_MASK  = 0b10000000 # Mask for Fractional Part (Bit 7=1, Bit 6=0)
SET_HIGH_MASK = 0b11000000 # Mask for Integral Part   (Bit 7=1, Bit 6=1)

class AirConditionerSystemConnection(HomeAutomationSystemConnection):
    """
    Manages communication with Board #1 (Air Conditioner System).
    Implements requirements [R2.3-1] and handles the specific UART protocol.
    """
    def __init__(self, port: str, rate: int):
        super().__init__(port, rate)
        # Initialize member variables [R2.1.1 Data Structures]
        self.desiredTemperature: float = 0.0   # Holds the target temperature
        self.ambientTemperature: float = 0.0   # Holds the current sensor reading
        self.fanSpeed: int = 0                 # Holds the current fan speed in rps

    # --- HELPER FUNCTIONS ---

    def _bytes_to_float(self, integral_byte: int, fractional_byte: int) -> float:
        """
        Converts two separate bytes received from the PIC into a single float value.
        
        Logic:
        - The PIC sends data in two parts: Integral (Integer) and Fractional.
        - Each part is stored in the lower 6 bits (0-63).
        - Example: 29.5 -> Integral: 29, Fractional: 5
        """
        integral = integral_byte & 0x3F     # Extract lower 6 bits
        fractional = fractional_byte & 0x3F # Extract lower 6 bits
        
        # Combine: Integral + (Fractional / 10.0)
        return float(integral) + float(fractional) / 10.0

    def _read_and_process(self, command_byte: int) -> int:
        """
        Sends a single command byte to the PIC and waits for a single byte response.
        Used for all GET operations.
        """
        if self._connection and self._connection.is_open:
            try:
                self._connection.write(bytes([command_byte]))
                response = self._connection.read(1) # Blocking read with timeout
                if response:
                    return response[0]
            except Exception as e:
                print(f"UART Error: {e}")
        return 0

    # --- MAIN API FUNCTIONS ---

    def update(self) -> None:
        """
        Polls Board #1 to retrieve the latest system status.
        Updates Ambient Temperature, Fan Speed, and current Desired Temperature.
        Implements [R2.3-1 - update].
        """
        if not self._connection or not self._connection.is_open:
            return

        # 1. Retrieve Ambient Temperature (Low and High bytes)
        ambient_frac = self._read_and_process(GET_AMBIENT_TEMP_LOW)
        time.sleep(0.05) # Short delay to ensure stable UART transmission
        ambient_int  = self._read_and_process(GET_AMBIENT_TEMP_HIGH)
        
        # Convert raw bytes to float and store
        self.ambientTemperature = self._bytes_to_float(ambient_int, ambient_frac)
        time.sleep(0.05)
        
        # 2. Retrieve Fan Speed
        fan_byte = self._read_and_process(GET_FAN_SPEED)
        self.fanSpeed = fan_byte # Fan speed is a direct byte value (rps)
        time.sleep(0.05)
        
        # 3. Retrieve Desired Temperature (Sync check with GUI)
        desired_frac = self._read_and_process(GET_DESIRED_TEMP_LOW)
        time.sleep(0.05)
        desired_int  = self._read_and_process(GET_DESIRED_TEMP_HIGH)
        
        self.desiredTemperature = self._bytes_to_float(desired_int, desired_frac)

    def setDesiredTemp(self, temp: float) -> bool:
        """
        Sends a new target temperature to Board #1 using the SET protocol.
        Implements [R2.3-1 - setDesiredTemp].
        """
        if not self._connection or not self._connection.is_open:
            return False

        # Validation: Ensure temperature is within the sensor/system range (10.0 - 50.0)
        if not (10.0 <= temp <= 50.0):
            print(f"Error: Temperature {temp}°C is out of valid range (10.0-50.0).")
            return False

        # Split the float value into Integral and Fractional parts
        integral = int(temp)
        fractional = int(round((temp - integral) * 10))

        # Prepare Command Bytes using Bitmasks
        # High Byte Command: 11xxxxxx | Low Byte Command: 10xxxxxx
        integral_cmd_byte = SET_HIGH_MASK | (integral & 0x3F) 
        fractional_cmd_byte = SET_LOW_MASK | (fractional & 0x3F)

        # --- TRANSMISSION SEQUENCE ---
        
        # 1. Send the Fractional Part (Low Byte) first
        self._connection.write(bytes([fractional_cmd_byte]))
        
        # CRITICAL DELAY: 
        # The PIC firmware uses a polling loop inside the main loop (multiplexing).
        # We must pause briefly to allow the PIC to process the first byte 
        # before sending the second one.
        time.sleep(0.1)  # 100ms delay
        
        # 2. Send the Integral Part (High Byte)
        self._connection.write(bytes([integral_cmd_byte]))
        # -----------------------------
        
        self.desiredTemperature = temp
        print(f"Set Desired Temp: {temp}°C (Commands Sent).")
        return True

    # --- GETTERS (Retrieve locally stored values) ---
    
    def getAmbientTemp(self) -> float:
        """Returns the last known Ambient Temperature."""
        return self.ambientTemperature
    
    def getFanSpeed(self) -> int:
        """Returns the last known Fan Speed."""
        return self.fanSpeed

    def getDesiredTemp(self) -> float:
        """Returns the last known Desired Temperature."""
        return self.desiredTemperature
