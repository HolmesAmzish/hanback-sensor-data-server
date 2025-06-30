import serial
import struct
import time
import random

# --- Configuration ---
SERIAL_PORT = '/dev/pts/9'  # Replace 'COMx' with your actual serial port (e.g., 'COM3' on Windows, '/dev/ttyUSB0' on Linux)
BAUD_RATE = 115200    # Common baud rate for embedded devices
SEND_INTERVAL_SECONDS = 3 # Send a data frame every 3 seconds

SINK_NODE_ID = 0x0001 # Example Sink Node ID
CURRENT_PACKET_SEQ = 0 # Starting sequence number

# --- Data Structure Definitions (Python equivalent) ---

# This represents the data that the sink node would receive from a sensor node
# and then use to construct the UART output frame.
# We'll simulate populating these fields.

# Inferred UartFrameStruct relevant part (24 bytes to be sent)
# Format string for struct.pack:
# <  : little-endian (common for embedded systems, but could be big-endian too)
# h  : short (int16_t)
# I  : unsigned int (uint32_t)
# H  : unsigned short (uint16_t)
# B  : unsigned char (uint8_t)
# 5s : 5 bytes (for Data array)
# Total: 2h + 2h + I + 3H + B + 5s = 2 + 2 + 4 + 2 + 2 + 2 + 1 + 5 = 20 bytes if Packet_Seq is I and Data is 5s
# Let's re-verify the structure.
# OrigiSrcAddr (2)
# TOS_NODE_ID (2)
# Dst2_for_multihop (2)
# Dst3_for_multihop (2)
# Packet_Seq (4)
# Temp (2)
# Humi (2)
# Photo (2)
# FUN (1)
# Data[5] (5)
# Total: 2+2+2+2+4+2+2+2+1+5 = 24 bytes

# Format string:
# < : Little-endian
# h : signed short (OrigiSrcAddr)
# h : signed short (TOS_NODE_ID)
# h : signed short (Dst2_for_multihop)
# h : signed short (Dst3_for_multihop)
# I : unsigned int (Packet_Seq)
# H : unsigned short (Temp)
# H : unsigned short (Humi)
# H : unsigned short (Photo)
# B : unsigned char (FUN)
# 5s: 5-byte string/bytes (Data)

# This is the full 24-byte payload that the sink would output over UART,
# assuming the `UART_Buff_len - 13` was a mistake and all copied data is sent.
# If you want the strict 11-byte output as per my detailed analysis,
# the format string would be: '<hhhhI' but then the sensor data won't be in the output.
UART_FRAME_FORMAT = '<hhhhIHHHB5s' # Total size: 2+2+2+2+4+2+2+2+1+5 = 24 bytes

def generate_data_frame():
    """Generates a synthetic data frame matching the expected UART output format."""
    global CURRENT_PACKET_SEQ

    # Simulate sensor node characteristics
    origi_src_addr = random.randint(0x0002, 0x00FF) # Example sensor node ID
    dst2_for_multihop = 0x0000 # Example placeholder
    dst3_for_multihop = 0x0000 # Example placeholder

    # Simulate sensor readings
    temp = random.randint(200, 350)  # Example: 20.0 to 35.0 C (scaled by 10)
    humi = random.randint(400, 800)  # Example: 40.0 to 80.0 %RH (scaled by 10)
    photo = random.randint(100, 1000) # Example: raw ADC value

    # Simulate FUN and Data
    fun_type = random.choice([1, 2, 3]) # 1: Photo, 2: Temp/Humi, 3: RFID
    rfid_data = b'\x00\x00\x00\x00\x00' # Default empty RFID data

    if fun_type == 1:
        # Only photo updated, temp/humi might be default or previous
        # For simplicity, we'll generate all, but FUN indicates primary update
        pass
    elif fun_type == 2:
        # Temp/Humi updated
        pass
    elif fun_type == 3:
        # RFID data updated
        rfid_data = bytes([random.randint(0, 255) for _ in range(5)]) # 5 random bytes

    # Increment packet sequence
    CURRENT_PACKET_SEQ += 1

    # Pack the data into bytes according to the format
    packed_data = struct.pack(
        UART_FRAME_FORMAT,
        origi_src_addr,
        SINK_NODE_ID,
        dst2_for_multihop,
        dst3_for_multihop,
        CURRENT_PACKET_SEQ,
        temp,
        humi,
        photo,
        fun_type,
        rfid_data
    )
    return packed_data

def main():
    """Main function to open serial port and send data frames."""
    try:
        # Open the serial port
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        print(f"Successfully opened serial port: {SERIAL_PORT} at {BAUD_RATE} baud.")
        print(f"Sending data frames every {SEND_INTERVAL_SECONDS} seconds. Press Ctrl+C to stop.")

        while True:
            data_frame = generate_data_frame()
            print(f"Sending frame ({len(data_frame)} bytes): {data_frame.hex()}")
            ser.write(data_frame)
            time.sleep(SEND_INTERVAL_SECONDS)

    except serial.SerialException as e:
        print(f"Error opening or communicating with serial port {SERIAL_PORT}: {e}")
        print("Please ensure the port is correct, not in use, and you have permissions.")
    except KeyboardInterrupt:
        print("\nSimulation stopped by user.")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Serial port closed.")

if __name__ == "__main__":
    main()