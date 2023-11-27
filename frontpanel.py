import time
import serial
import numpy as np
import subprocess
import threading


class RGBW(int):
    def __new__(self, r, g=None, b=None, w=None):
        if (g, b, w) == (None, None, None):
            return int.__new__(self, r)
        else:
            if w is None:
                w = 0
            return int.__new__(self, (w << 24) | (r << 16) | (g << 8) | b)

    @property
    def r(self):
        return (self >> 16) & 0xff

    @property
    def g(self):
        return (self >> 8) & 0xff

    @property
    def b(self):
        return (self) & 0xff

    @property
    def w(self):
        return (self >> 24) & 0xff
    
def Color(red, green, blue, white=0):
    "Convert the provided red, green, blue color to a 24-bit color value. Each color component should be a value 0-255 where 0 is the lowest intensity and 255 is the highest intensity."
    return RGBW(red, green, blue, white)

### LED Strip Configuration ###

LED_COUNT = 8 # Number of LED pixels.
MIN_DB = -40
JACK_METER_PATH = "/root/Livefeed-Encoder-Core/frontpanel/jack_meter"
JACK_METER_PARAMS = ["-n", "-f25"]
DEVICE_INPUT_LEFT = "system:capture_1"
DEVICE_INPUT_RIGHT = "system:capture_2"
DEVICE_OUTPUT_LEFT = "system:capture_1"
DEVICE_OUTPUT_RIGHT = "system:capture_2"

### Program Running / Power Indicator ###

program_running = True
not_running = True

### Ethernet Link Monitor Configuration ###
deltaTx = 0
last_valueTx = 0
currTx = 0
deltaRx = 0
last_valueRx = 0
currRx = 0
UPPER_THRESHOLD = 10

## LED MAPS and COLOURS Configuration ##

LED_MAP = {
    "program_running": 0,
    "ffmpeg": 1,
    "ch1_ip": 2,
    "ch2_ip": 3,
    "ch1_op": 4,
    "ch2_op": 5,
    "EthI": 6,
    "EthO": 7
}

## HSV Values

LED_COLOR = {
    "program_running": [[150, 100, 100]],
    "ffmpeg": [[150, 100, 100]],
    "ch1_ip": [[150, 0, 100]],
    "ch2_ip": [[150, 0, 100]],
    "ch1_op": [[150, 0, 100]],
    "ch2_op": [[150, 0, 100]],
    "EthI": [[234, 100, 88]],
    "EthO": [[150, 100, 100]]
}

##Serial port configuration##

SERIAL_PORT = '/dev/ttyS1' #Replace ttyS0 with ttyAM0 for Pi1,Pi2,Pi0. TNT0 is test virtual serial port
SERIAL_BAUDRATE = 115200
SERIAL_PARITY = serial.PARITY_NONE
SERIAL_STOPBITS = serial.STOPBITS_ONE
SERIAL_BYTESIZE = serial.EIGHTBITS
SERIAL_TIMEOUT = 1

##Color buffer global array##

colorsBuffer = np.array([Color(0,0,0)] * LED_COUNT, dtype=np.uint32)

## Functions ##

def setStripSerial(bufferArray, serialPort):
    sendBuffer = []
    for i in range(LED_COUNT):

        sendBuffer.append(bufferArray[i] & 255)
        sendBuffer.append((bufferArray[i] >> 8) & 255)
        sendBuffer.append((bufferArray[i] >> 16) & 255)

    sendBuffer.append(13)
    sendBuffer.append(10)
    serialPort.write(sendBuffer)


def get_network_bytes(interface):
    for line in open('/proc/net/dev', 'r'):
        if interface in line:
            data = line.split('%s:' % interface)[1].split()
            rx_bytes, tx_bytes = (data[0], data[8])
            return (int(rx_bytes), int(tx_bytes))


def printstats():
    global last_valueTx
    global deltaTx
    global currTx
    global last_valueRx
    global deltaRx
    global currRx

    rx_bytes, tx_bytes = get_network_bytes('eth0')
    currTx = (tx_bytes)
    currRx = (rx_bytes)
    deltaTx = currTx - last_valueTx
    deltaRx = currRx - last_valueRx
    last_valueTx = currTx
    last_valueRx = currRx
    if deltaTx < 111:
     deltaTx = 0
    if deltaRx < 68:
     deltaRx = 0

def colorWipe(bufferArray, color, wait_ms=200):
    #"Wipe color across display a pixel at a time."""
    for i in range(LED_COUNT):
        bufferArray[i] = color
        setStripSerial(bufferArray, serial1)
        time.sleep(wait_ms/2000.0)

def clear_strip(bufferArray):
    for i in range(LED_COUNT):
        bufferArray[i] = Color(0,0,0)
    setStripSerial(bufferArray, serial1)


def check_ffmpeg():
    result = subprocess.run(['sh', '/root/Livefeed-Encoder-Core/frontpanel/check_ff.sh'], stdout=subprocess.PIPE)
    st = result.stdout.decode('utf-8')
    return ("not_running" in st)

def disconnect_outputs():
    subprocess.run(['sh', '/root/Livefeed-Encoder-Core/frontpanel/disconnect_outputs.sh'])

def hsv_to_rgb(hue, sat, value):
    h = hue / 360
    s = sat / 100
    v = value / 100
    if s == 0.0:
        v *= 255
        return (v, v, v)
    i = int(h*6.)
    f = (h*6.)-i
    p, q, t = int(255*(v*(1.-s))), int(255*(v*(1.-s*f))
                                       ), int(255*(v*(1.-s*(1.-f))))
    v *= 255
    i %= 6
    if i == 0:
        return (v, t, p)
    if i == 1:
        return (q, v, p)
    if i == 2:
        return (p, v, t)
    if i == 3:
        return (p, q, v)
    if i == 4:
        return (t, p, v)
    if i == 5:
        return (v, p, q)


def set_power_led(bufferArray):
    [hue, sat, val] = LED_COLOR["program_running"][0]
    (r, g, b) = hsv_to_rgb(hue, sat, val)
    bufferArray[LED_MAP["program_running"]] = Color(int(b), int(g), int(r))


def set_lan_statusTx(bufferArray):
    [hue, sat, val] = LED_COLOR["EthO"][0]
    br = (deltaTx / UPPER_THRESHOLD)
    br = br if br < 100 else 100
    (r, g, b) = hsv_to_rgb(hue, sat, br)
    bufferArray[LED_MAP["EthO"]] = Color(int(b), int(g), int(r))

def set_lan_statusRx(bufferArray):
    [hue, sat, val] = LED_COLOR["EthI"][0]
    br = (deltaRx / UPPER_THRESHOLD)
    br = br if br < 100 else 100
    if deltaRx > 1 < 100:
     hue = 234
     sat = 100
     br = 88
     (r, g, b) = hsv_to_rgb(hue, sat, br)
     bufferArray[LED_MAP["EthI"]] = Color(int(b), int(g), int(r))
    if deltaRx < 1:
     bufferArray[LED_MAP["EthI"]] = Color(0, 0, 0)

def parse_line(b):
    try:
        return float(b)
    except ValueError:
        return 0


def map_level_to_pwm(level):
    try:
        signal = round((1 - (level / MIN_DB)) * 100)
        return min([max([signal, 0]), 100])
    except:
        return 0

def ffmpeg_thread(bufferArray):

    global program_running
 
    [hue, sat, bri] = LED_COLOR["ffmpeg"][0]
    while program_running:
        not_running = check_ffmpeg()
        if not_running:
            bufferArray[LED_MAP["ffmpeg"]] = Color(0, 0, 255)
        else:
            for i in range(0, 100, 4):
                (r, g, b) = hsv_to_rgb(hue, sat, i)
                bufferArray[LED_MAP["ffmpeg"]] = Color(int(b), int(g), int(r))
                time.sleep(0.04)
            for i in range(100, 0, -4):
                (r, g, b) = hsv_to_rgb(hue, sat, i)
                bufferArray[LED_MAP["ffmpeg"]] = Color(int(b), int(g), int(r))
                time.sleep(0.04)

def process_feed_audio(path, map_name, bufferArray):
    time.sleep(1)
    t_list = [JACK_METER_PATH, path] + JACK_METER_PARAMS
    print(t_list)
    output = subprocess.Popen(t_list, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    lastsignal = 0
    for line in output.stdout:
        level = parse_line(line)
        signal = map_level_to_pwm(level)
      
        [hue, sat, bri] = LED_COLOR[map_name][0]
      
        if signal < 33.2: ## Show green up to -20db
         hue = 150
         sat = 100

        (r, g, b) = hsv_to_rgb(hue, sat, signal)
        bufferArray[LED_MAP[map_name]] = Color(int(b), int(g), int(r))



#### Main Program ####

if __name__ == '__main__':
  
    serial1 = serial.Serial(
        port= SERIAL_PORT, 
        baudrate = SERIAL_BAUDRATE,
        parity=SERIAL_PARITY,
        stopbits=SERIAL_STOPBITS,
        bytesize=SERIAL_BYTESIZE,
        timeout=SERIAL_TIMEOUT
     )

    print('Press Ctrl-C to quit.')

    clear_strip(colorsBuffer)
    #set_power_led(strip)
    colorWipe(colorsBuffer, Color(128, 255, 64))
    x = threading.Thread(target=ffmpeg_thread, args=(colorsBuffer,))

    x_ip1 = threading.Thread(target=process_feed_audio, args=(DEVICE_INPUT_LEFT,"ch1_ip", colorsBuffer, ))
    x_ip2 = threading.Thread(target=process_feed_audio, args=(DEVICE_INPUT_RIGHT,"ch2_ip", colorsBuffer, ))
    x_op1 = threading.Thread(target=process_feed_audio, args=(DEVICE_OUTPUT_LEFT,"ch1_op", colorsBuffer, ))
    x_op2 = threading.Thread(target=process_feed_audio, args=(DEVICE_OUTPUT_RIGHT,"ch2_op", colorsBuffer, ))

    x_ip1.start()
    time.sleep(0.2)
    x_ip2.start()
    time.sleep(0.2)
    x_op1.start()
    time.sleep(0.2)
    x_op2.start()
    time.sleep(0.2)

    x.start()

    try:

       while True:
            set_power_led(colorsBuffer)
            set_lan_statusTx(colorsBuffer)
            set_lan_statusRx(colorsBuffer)
            setStripSerial(colorsBuffer, serial1)
            printstats()
            time.sleep(0.02)

    except KeyboardInterrupt:
        program_running = False
        x_ip1.join()
        x_ip2.join()
        x_op1.join()
        x_op2.join()
        x.join()
        print("Break Command Received! Clearing LEDs")
