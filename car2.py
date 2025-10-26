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
    print(f"Connected to MQTT Broker: {rc}")
    client.subscribe(TOPIC_CAR_PING)
    client.subscribe(TOPIC_CAR_CONTROL)

def on_message(client, userdata, msg):
    global px
    
    topic = msg.topic
    payload = msg.payload.decode()
    
    if topic == TOPIC_CAR_PING:
        # Respond with pong immediately
        client.publish(TOPIC_CAR_PONG, payload)
        
    elif topic == TOPIC_CAR_CONTROL:
        # Control commands: "forward:speed", "stop", "backward:speed"
        if payload.startswith("forward:"):
            speed = int(payload.split(':')[1])
            print(f"Moving forward: speed={speed}")
            px.forward(speed)
            
        elif payload == "stop":
            print("Stopped")
            px.stop()
            
        elif payload.startswith("backward:"):
            speed = int(payload.split(':')[1])
            print(f"Moving backward: speed={speed}")
            px.backward(speed)

def main():
    global px, client
    
    print("=== Car2 Starting ===")
    
    # Initialize Picarx
    try:
        px = Picarx()
        print("Picarx initialized")
    except Exception as e:
        print(f"Picarx initialization error: {e}")
        return
    
    # MQTT connection
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    print(f"Connecting to MQTT Broker: {BROKER_HOST}:{BROKER_PORT}")
    try:
        client.connect(BROKER_HOST, BROKER_PORT, 60)
    except Exception as e:
        print(f"MQTT connection error: {e}")
        print("Please change BROKER_HOST to your Mac's IP address")
        return
    
    client.loop_start()
    
    print("Ready. Waiting for MQTT messages...")
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nExiting")
    finally:
        px.stop()
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    main()

