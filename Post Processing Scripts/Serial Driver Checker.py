import serial
import serial.tools.list_ports as list_ports 

STM_VID = 1155
SERIAL_COMM_BAUD_RATE = int(5e6)

for port_info in list_ports.comports():
    print(f'Port Info: {port_info.vid}')
    print(f'Manufacturer: {port_info.manufacturer}')
    print(f'Serial Number: {port_info.serial_number}')
    print(f'Description: {port_info.description}')
    print(f'Hardware ID: {port_info.hwid}')
    print(f'Product: {port_info.product}')
    # if port_info.vid == STM_VID:
    #     serial_conn = serial.Serial(
    #     port=port_info.name,
    #     baudrate=SERIAL_COMM_BAUD_RATE,
    #     bytesize=8,
    #     timeout=0,
    #     stopbits=serial.STOPBITS_ONE,
    # )
    # break

#%%
import struct
foo = struct.pack("<i", 996000)
for byte in foo:
    print(byte)