import paho.mqtt.client as mqtt
import time
import csv
import threading
from datetime import datetime
from collections import deque

# MQTTブローカー設定
BROKER_HOST = "localhost"
BROKER_PORT = 1883

# トピック定義
TOPIC_CAR_PING = "car2/ping"
TOPIC_CAR_PONG = "car2/pong"
TOPIC_CAR_CONTROL = "car2/control"
TOPIC_CAR_STATUS = "car2/status"

TOPIC_SIGNAL_PING = "signal1/ping"
TOPIC_SIGNAL_PONG = "signal1/pong"
TOPIC_SIGNAL_STATUS = "signal1/status"

# レイテンシ測定用
car_latency_queue = deque()
signal_latency_queue = deque()
car_ping_times = {}
signal_ping_times = {}

# デバイスステータス
car_status = {"distance": 0, "moving": False}
signal_status = {"color": "RED"}

# 制御フラグ
car_moved_first_10cm = False
waiting_for_green = False

client = None

def on_connect(client, userdata, flags, rc):
    print(f"MQTTブローカーに接続: {rc}")
    client.subscribe(TOPIC_CAR_PONG)
    client.subscribe(TOPIC_CAR_STATUS)
    client.subscribe(TOPIC_SIGNAL_PONG)
    client.subscribe(TOPIC_SIGNAL_STATUS)

def on_message(client, userdata, msg):
    global car_latency_queue, signal_latency_queue
    global car_status, signal_status
    
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
            
    elif topic == TOPIC_CAR_STATUS:
        # ステータス: "distance:XX,moving:true/false"
        parts = payload.split(',')
        for part in parts:
            if ':' in part:
                key, value = part.split(':', 1)
                if key == "distance":
                    car_status["distance"] = float(value)
                elif key == "moving":
                    car_status["moving"] = value.lower() == "true"
                    
    elif topic == TOPIC_SIGNAL_STATUS:
        # ステータス: "RED", "GREEN", "YELLOW"
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
    """車の制御ロジック"""
    global client, car_moved_first_10cm, waiting_for_green
    global car_status, signal_status
    
    print("車を前進させます (10cm)")
    client.publish(TOPIC_CAR_CONTROL, "forward:100")
    
    # 10cm移動を待つ
    start_time = time.time()
    timeout = 30
    
    while time.time() - start_time < timeout:
        if car_status["distance"] >= 10:
            print(f"10cm移動完了 (実際: {car_status['distance']:.2f}cm)")
            car_moved_first_10cm = True
            break
        time.sleep(0.1)
    
    if not car_moved_first_10cm:
        print("タイムアウト: 10cm移動が確認できませんでした")
        return
    
    # 信号をチェック
    print(f"現在の信号: {signal_status['color']}")
    
    if signal_status['color'] in ['RED', 'YELLOW']:
        print(f"信号が{signal_status['color']}です。緑になるまで待機します...")
        waiting_for_green = True
        
        # 緑信号を待つ
        while waiting_for_green:
            if signal_status['color'] == 'GREEN':
                print("信号が緑になりました！再び前進します")
                client.publish(TOPIC_CAR_CONTROL, "forward:100")
                waiting_for_green = False
                time.sleep(2)  # 前進時間
                client.publish(TOPIC_CAR_CONTROL, "stop")
                break
            time.sleep(0.1)
    else:
        print("信号が緑です。そのまま前進を続けます")
        time.sleep(2)  # 前進時間
        client.publish(TOPIC_CAR_CONTROL, "stop")

def main():
    global client
    
    print("=== 交差点実験開始 ===")
    print("MQTTブローカーに接続中...")
    
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    client.connect(BROKER_HOST, BROKER_PORT, 60)
    client.loop_start()
    
    # 接続待機
    time.sleep(2)
    
    # レイテンシ測定スレッド開始
    latency_thread = threading.Thread(target=latency_measurement_thread, daemon=True)
    latency_thread.start()
    
    print("デバイスの準備を待っています...")
    time.sleep(5)
    
    # 車の制御開始
    try:
        control_car()
        
        print("\n実験完了！")
        print("レイテンシデータは car2_latency.csv と signal1_latency.csv に保存されました")
        
        # 実験終了後もレイテンシ測定を続ける
        print("\nレイテンシ測定を継続します (Ctrl+Cで終了)")
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n実験を終了します")
    finally:
        client.publish(TOPIC_CAR_CONTROL, "stop")
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    main()

