import paho.mqtt.client as mqtt
from picarx import Picarx
import time

# MQTTブローカー設定 (Mac)
BROKER_HOST = "10.21.89.67"  # Macのローカルネットワークアドレス
BROKER_PORT = 1883

# トピック定義
TOPIC_CAR_PING = "car2/ping"
TOPIC_CAR_PONG = "car2/pong"
TOPIC_CAR_CONTROL = "car2/control"

px = None
client = None

def on_connect(client, userdata, flags, rc):
    print(f"[CAR2] Connected to MQTT Broker: {rc}")
    if rc == 0:
        print(f"[CAR2] Subscribing to topics...")
        client.subscribe(TOPIC_CAR_PING)
        client.subscribe(TOPIC_CAR_CONTROL)
        print(f"[CAR2] Subscribed to: {TOPIC_CAR_PING}, {TOPIC_CAR_CONTROL}")
    else:
        print(f"[CAR2] Connection failed with code: {rc}")

def on_message(client, userdata, msg):
    global px
    
    topic = msg.topic
    payload = msg.payload.decode()
    
    print(f"[CAR2] Received message on topic '{topic}': {payload}")
    
    if topic == TOPIC_CAR_PING:
        # Respond with pong immediately
        print(f"[CAR2] Responding to ping: {payload}")
        client.publish(TOPIC_CAR_PONG, payload)
        print(f"[CAR2] Pong sent")
        
    elif topic == TOPIC_CAR_CONTROL:
        # Control commands: "forward:speed", "stop", "backward:speed"
        print(f"[CAR2] Processing control command: {payload}")
        
        if payload.startswith("forward:"):
            speed = int(payload.split(':')[1])
            print(f"[CAR2] >> Setting direction to 0 (straight)")
            px.set_dir_servo_angle(0)  # Set straight direction
            print(f"[CAR2] >> Moving forward with speed={speed}")
            px.forward(speed)
            print(f"[CAR2] >> Forward command executed")
            
        elif payload == "stop":
            print(f"[CAR2] >> Stopping car (setting speed to 0)")
            px.forward(0)  # Stop by setting speed to 0
            print(f"[CAR2] >> Car stopped")
            
        elif payload.startswith("backward:"):
            speed = int(payload.split(':')[1])
            print(f"[CAR2] >> Setting direction to 0 (straight)")
            px.set_dir_servo_angle(0)  # Set straight direction
            print(f"[CAR2] >> Moving backward with speed={speed}")
            px.backward(speed)
            print(f"[CAR2] >> Backward command executed")
        else:
            print(f"[CAR2] >> Unknown command: {payload}")

def main():
    global px, client
    
    print("=" * 50)
    print("[CAR2] Starting Car2 Controller")
    print("=" * 50)
    
    # Initialize Picarx
    print("[CAR2] Initializing Picarx...")
    try:
        px = Picarx()
        print("[CAR2] ✓ Picarx initialized successfully")
    except Exception as e:
        print(f"[CAR2] ✗ Picarx initialization error: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # MQTT connection
    print("[CAR2] Setting up MQTT client...")
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    print(f"[CAR2] Connecting to MQTT Broker: {BROKER_HOST}:{BROKER_PORT}")
    try:
        client.connect(BROKER_HOST, BROKER_PORT, 60)
        print("[CAR2] ✓ Connection initiated")
    except Exception as e:
        print(f"[CAR2] ✗ MQTT connection error: {e}")
        print("[CAR2] Please change BROKER_HOST to your Mac's IP address")
        import traceback
        traceback.print_exc()
        return
    
    print("[CAR2] Starting MQTT loop...")
    client.loop_start()
    
    print("[CAR2] " + "=" * 50)
    print("[CAR2] Ready. Waiting for MQTT messages...")
    print("[CAR2] " + "=" * 50)
    
    try:
        counter = 0
        while True:
            time.sleep(5)
            counter += 1
            print(f"[CAR2] Heartbeat {counter} - Still running and waiting for commands...")
    except KeyboardInterrupt:
        print("\n[CAR2] Exiting...")
    finally:
        print("[CAR2] Cleanup: Stopping car...")
        px.forward(0)  # Stop the car
        px.set_dir_servo_angle(0)  # Reset direction
        time.sleep(0.2)
        print("[CAR2] Cleanup: Disconnecting MQTT...")
        client.loop_stop()
        client.disconnect()
        print("[CAR2] Goodbye!")

if __name__ == "__main__":
    main()

