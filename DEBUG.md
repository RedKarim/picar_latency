# Debug Guide

## Added Comprehensive Logging

### What's Changed

1. **car2.py** - Added detailed logging with `[CAR2]` prefix:
   - Connection status
   - Message received on topics
   - Command processing steps
   - Motor and servo commands
   - Heartbeat every 5 seconds
   - Error tracebacks

2. **main.py** - Added real-time SSH output capture:
   - All car2 and signal1 logs now appear in main terminal
   - Added `[MAIN]` prefix for main controller logs
   - Shows MQTT publish confirmations
   - Command sequence tracking

## How to Debug

### Run the experiment:
```bash
cd /Users/redkarim/Documents/picar_latency
python3 main.py
```

### What to Look For

#### 1. Car2 Initialization
You should see:
```
[car2] ================================================== 
[car2] [CAR2] Starting Car2 Controller
[car2] ==================================================
[car2] [CAR2] Initializing Picarx...
[car2] [CAR2] ✓ Picarx initialized successfully
[car2] [CAR2] Connecting to MQTT Broker: 10.21.89.67:1883
[car2] [CAR2] ✓ Connection initiated
[car2] [CAR2] Connected to MQTT Broker: 0
[car2] [CAR2] Subscribed to: car2/ping, car2/control
```

#### 2. Command Reception
When forward command is sent:
```
[MAIN] Sending forward command: forward:100
[MAIN] Command published to topic: car2/control
[car2] [CAR2] Received message on topic 'car2/control': forward:100
[car2] [CAR2] Processing control command: forward:100
[car2] [CAR2] >> Setting direction to 0 (straight)
[car2] [CAR2] >> Moving forward with speed=100
[car2] [CAR2] >> Forward command executed
```

#### 3. Ping/Pong for Latency
```
[car2] [CAR2] Received message on topic 'car2/ping': car_1234567890_0
[car2] [CAR2] Responding to ping: car_1234567890_0
[car2] [CAR2] Pong sent
```

## Common Issues to Check

### Issue: No car2 logs appear
**Problem**: car2 didn't start or crashed
**Check**: 
- Is car2 Raspberry Pi powered on?
- Can you ping it? `ping raspberrypi.local`
- Try manual SSH: `ssh car2` then `python3 ~/car2.py`

### Issue: car2 connects but no messages received
**Problem**: MQTT broker or topic mismatch
**Look for**: 
- `[CAR2] Subscribed to:` message
- If you see ping messages but no control messages, topics may be wrong

### Issue: Picarx initialization fails
**Problem**: Hardware or permission issue
**Check**:
- Run `groups` on car2 - should include: i2c, spi, gpio
- Try: `sudo usermod -aG i2c,spi,gpio car2 && sudo reboot`

### Issue: Commands received but car doesn't move
**Look for**:
- Does `[CAR2] >> Forward command executed` appear?
- If yes, this is a hardware/picar issue
- If no, Python exception should be logged

## Manual Test on car2

SSH to car2 and test picarx directly:
```bash
ssh car2
python3 << 'EOF'
from picarx import Picarx
import time

px = Picarx()
print("Testing forward...")
px.set_dir_servo_angle(0)
px.forward(100)
time.sleep(2)
px.forward(0)
print("Done")
EOF
```

If this doesn't move the car, the issue is with picarx hardware/setup, not our code.

## Logs Location

- **Console**: All logs appear in main.py terminal
- **CSV**: Latency data in `car2_latency.csv` and `signal1_latency.csv`
- **Remote**: SSH to see original logs: `ssh car2` then check if process is running: `ps aux | grep python`

