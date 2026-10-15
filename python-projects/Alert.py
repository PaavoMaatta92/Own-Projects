import socket
import winsound
import serial
import time
import csv
import datetime
import os

# --------------------
# ASETUKSET
# --------------------
UDP_PORT = 9000
LINUX_IP = "..."   
LINUX_PORT = 9000

SERIAL_PORT = "COM5"    
BAUDRATE = 115200

# --------------------
# UART
# --------------------
ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=1)

flag = 0
round_start_time = 0
start_time = 0


# --------------------
# UDP
# --------------------
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("", UDP_PORT))
sock.settimeout(3.0)

def send_freq_change(letter):
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.sendto(letter.encode(), (LINUX_IP, LINUX_PORT))


print("Windows alert hub käynnissä")
print("UART:", SERIAL_PORT)

date_now = datetime.datetime.now()

file_path = r'c:\Users\paavo\Desktop\läppäri\python\Halytys_log.csv'

file_exists = os.path.isfile(file_path)

with open(file_path, mode='a', newline='', encoding='utf-8') as log_file:
    fieldnames = ["Hälytys käynnistetty", "Aika", "kellonaika"]
    log_writer = csv.DictWriter(log_file, fieldnames=fieldnames)


    if not file_exists:
        log_writer.writeheader()

    log_writer.writerow({
        "Hälytys käynnistetty": "Hälytys käynnistetty",
        "Aika": date_now.strftime("%Y-%m-%d %H:%M:%S")
    })

# --------------------
while True:

    data = ser.read(1)  
    if data:
        print(f"RX byte: 0x{data[0]:02X}")
        send_freq_change(data.decode())
    
    data = None

    round_end_time = time.time()
    total_round_time = round_end_time - round_start_time
    if total_round_time > 25 and flag == 1:
        flag = 0
        end_time = time.time()
        total_time = round((end_time - start_time) - 25, 1) 
        print(total_time, "sekuntia")
        with open(file_path, mode='a', newline='', encoding='utf-8') as log_file:
            fieldnames = ["Hälytys käynnistetty", "Aika", "Kellonaika", "Taajuus"]
            log_writer = csv.DictWriter(log_file, fieldnames=fieldnames)

   
            if not file_exists:
                log_writer.writeheader()

            log_writer.writerow({
                "Hälytys käynnistetty": "Hälytyksen kesto",
                "Aika": total_time, "Kellonaika": datetime.datetime.now().strftime("%H:%M:%S"),
                "Taajuus": float(msg)
            })
    try:
        data, addr = sock.recvfrom(1024)
    except socket.timeout:
        continue
    if flag == 0:        
        start_time = time.time()
        flag = 1

    round_start_time = time.time()    
    msg = data.decode().strip()
    print("HÄLYTYS:", msg)

    # äänihälytys
    # winsound.Beep(1500, 800)

    # lähetä FPGA:lle
    ser.write(b"A")  
    time.sleep(0.05)
