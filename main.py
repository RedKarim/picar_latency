import paho.mqtt.client as mqtt
import time
import csv
import threading
import subprocess
from datetime import datetime
from collections import deque

# MQTTブローカー設定
BROKER_HOST = "localhost"
BROKER_PORT = 1883

# トピック定義
TOPIC_CAR_PING = "car2/ping"
TOPIC_CAR_PONG = "car2/pong"
TOPIC_CAR_CONTROL = "car2/control"

TOPIC_SIGNAL_PING = "signal1/ping"
TOPIC_SIGNAL_PONG = "signal1/pong"
TOPIC_SIGNAL_STATUS = "signal1/status"

# レイテンシ測定用
car_latency_queue = deque()
signal_latency_queue = deque()
car_ping_times = {}
signal_ping_times = {}

# デバイスステータス
signal_status = {"color": "RED"}

# リモートプロセス
remote_processes = []

client = None

def output_reader(process, name):
    """Read and print output from remote process"""
    for line in iter(process.stdout.readline, b''):
        if line:
            print(f"[{name}] {line.decode().strip()}")

def start_remote_script(host, script_path, name):
    """Start script on remote host"""
    print(f"Starting {name} ({host})...")
    try:
        # Execute remote script via SSH
        process = subprocess.Popen(
            ['ssh', host, f'python3 -u {script_path}'],  # -u for unbuffered output
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,  # Redirect stderr to stdout
            stdin=subprocess.PIPE,
            bufsize=1
        )
        remote_processes.append((process, name, host))
        print(f"Started {name} (PID: {process.pid})")
        
        # Start thread to read output
        output_thread = threading.Thread(target=output_reader, args=(process, name), daemon=True)
        output_thread.start()
        
        return process
    except Exception as e:
        print(f"Failed to start {name}: {e}")
        return None

def stop_remote_processes():
    """Stop remote processes"""
    print("\nStopping remote processes...")
    for process, name, host in remote_processes:
        print(f"Stopping {name}...")
        try:
            # Terminate process via SSH
            subprocess.run(['ssh', host, 'pkill -f "python3.*py"'], 
                         timeout=5, capture_output=True)
        except Exception as e:
            print(f"Error stopping {name}: {e}")
        
        try:
            process.terminate()
            process.wait(timeout=3)
        except:
            process.kill()

def on_connect(client, userdata, flags, rc):
    print(f"Connected to MQTT Broker: {rc}")
    client.subscribe(TOPIC_CAR_PONG)
    client.subscribe(TOPIC_SIGNAL_PONG)
    client.subscribe(TOPIC_SIGNAL_STATUS)

def on_message(client, userdata, msg):
    global car_latency_queue, signal_latency_queue, signal_status
    
    topic = msg.topic
    payload = msg.payload.decode()
    
    if topic == TOPIC_CAR_PONG:
        ping_id = payload
        if ping_id in car_ping_times:
            latency = (time.time() - car_ping_times[ping_id]) * 1000
            car_latency_queue.append((datetime.now(), latency))
            del car_ping_times[ping_id]
            
    elif topic == TOPIC_SIGNAL_PONG:
        ping_id = payload
        if ping_id in signal_ping_times:
            latency = (time.time() - signal_ping_times[ping_id]) * 1000
            signal_latency_queue.append((datetime.now(), latency))
            del signal_ping_times[ping_id]
                    
    elif topic == TOPIC_SIGNAL_STATUS:
        signal_status["color"] = payload

def save_latency_to_csv(filename, latency_queue):
    """レイテンシデータをCSVに保存"""
    if not latency_queue:
        return
    
    file_exists = False
    try:
        with open(filename, 'r'):
            file_exists = True
    except FileNotFoundError:
        pass
    
    with open(filename, 'a', newline='') as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(['timestamp', 'latency_ms'])
        
        while latency_queue:
            timestamp, latency = latency_queue.popleft()
            writer.writerow([timestamp.isoformat(), f"{latency:.2f}"])

def latency_measurement_thread():
    """1秒ごとに3回のpingを送信してレイテンシを測定"""
    global client, car_ping_times, signal_ping_times
    
    while True:
        # 3回のpingを送信
        for i in range(3):
            # car2へのping
            ping_id = f"car_{time.time()}_{i}"
            car_ping_times[ping_id] = time.time()
            client.publish(TOPIC_CAR_PING, ping_id)
            
            # signal1へのping
            ping_id = f"signal_{time.time()}_{i}"
            signal_ping_times[ping_id] = time.time()
            client.publish(TOPIC_SIGNAL_PING, ping_id)
            
            time.sleep(0.333)  # 1秒で3回送信
        
        # CSVに保存
        save_latency_to_csv('car2_latency.csv', car_latency_queue)
        save_latency_to_csv('signal1_latency.csv', signal_latency_queue)

def control_car():
    """Car control logic"""
    global client, signal_status
    
    print("\n" + "="*50)
    print("[MAIN] Starting car control sequence")
    print("="*50)
    
    print("[MAIN] Sending forward command: forward:100")
    client.publish(TOPIC_CAR_CONTROL, "forward:100")
    print("[MAIN] Command published to topic: car2/control")
    
    # Move for ~1 second (approximately 10cm)
    print("[MAIN] Moving for 10cm (~1 second)...")
    time.sleep(1)
    
    # Stop and check signal
    print("[MAIN] Sending stop command")
    client.publish(TOPIC_CAR_CONTROL, "stop")
    print("[MAIN] Stop command published")
    print("[MAIN] Checking signal...")
    time.sleep(0.5)
    
    # Check signal
    print(f"[MAIN] Current signal: {signal_status['color']}")
    
    if signal_status['color'] in ['RED', 'YELLOW']:
        print(f"[MAIN] Signal is {signal_status['color']}. Waiting for GREEN...")
        
        # Wait for green signal
        while signal_status['color'] != 'GREEN':
            print(f"[MAIN] Still waiting... Signal is {signal_status['color']}")
            time.sleep(0.5)
        
        print("[MAIN] Signal turned GREEN! Moving forward again")
        print("[MAIN] Sending forward command: forward:100")
        client.publish(TOPIC_CAR_CONTROL, "forward:100")
        print("[MAIN] Moving for 2 seconds...")
        time.sleep(2)
        print("[MAIN] Sending stop command")
        client.publish(TOPIC_CAR_CONTROL, "stop")
        print("[MAIN] Stopped")
    else:
        print("[MAIN] Signal is GREEN. Continuing forward")
        print("[MAIN] Sending forward command: forward:100")
        client.publish(TOPIC_CAR_CONTROL, "forward:100")
        print("[MAIN] Moving for 2 seconds...")
        time.sleep(2)
        print("[MAIN] Sending stop command")
        client.publish(TOPIC_CAR_CONTROL, "stop")
        print("[MAIN] Stopped")
    
    print("="*50)
    print("[MAIN] Car control sequence complete")
    print("="*50 + "\n")

def main():
    global client
    
    print("=== Traffic Light Experiment Started ===")
    
    # Start remote scripts
    print("\n--- Starting Remote Devices ---")
    signal_proc = start_remote_script('signal1', '~/signal1.py', 'signal1 (traffic light)')
    time.sleep(2)
    car_proc = start_remote_script('car2', '~/car2.py', 'car2 (vehicle)')
    time.sleep(3)
    
    if signal_proc is None or car_proc is None:
        print("ERROR: Failed to start remote devices")
        stop_remote_processes()
        return
    
    print("\n--- Connecting to MQTT Broker ---")
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    client.connect(BROKER_HOST, BROKER_PORT, 60)
    client.loop_start()
    
    # Wait for connection
    time.sleep(2)
    
    # Start latency measurement thread
    latency_thread = threading.Thread(target=latency_measurement_thread, daemon=True)
    latency_thread.start()
    
    print("Waiting for devices to be ready...")
    time.sleep(5)
    
    # Start car control
    try:
        control_car()
        
        print("\nExperiment Complete!")
        print("Latency data saved to car2_latency.csv and signal1_latency.csv")
        
        # Continue latency measurement after experiment
        print("\nContinuing latency measurement (Press Ctrl+C to exit)")
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\nExiting experiment")
    finally:
        client.publish(TOPIC_CAR_CONTROL, "stop")
        client.loop_stop()
        client.disconnect()
        stop_remote_processes()

if __name__ == "__main__":
    main()

