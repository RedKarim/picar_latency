import paho.mqtt.client as mqtt
from picarx import Picarx
import time
import threading

# MQTTブローカー設定 (Mac)
BROKER_HOST = "192.168.1.100"  # Macのローカルネットワークアドレスに変更
BROKER_PORT = 1883

# トピック定義
TOPIC_CAR_PING = "car2/ping"
TOPIC_CAR_PONG = "car2/pong"
TOPIC_CAR_CONTROL = "car2/control"
TOPIC_CAR_STATUS = "car2/status"

# 車の状態
car_distance = 0
car_moving = False
px = None
client = None

def on_connect(client, userdata, flags, rc):
    print(f"MQTTブローカーに接続: {rc}")
    client.subscribe(TOPIC_CAR_PING)
    client.subscribe(TOPIC_CAR_CONTROL)

def on_message(client, userdata, msg):
    global car_distance, car_moving, px
    
    topic = msg.topic
    payload = msg.payload.decode()
    
    if topic == TOPIC_CAR_PING:
        # pingに即座にpongで応答
        client.publish(TOPIC_CAR_PONG, payload)
        
    elif topic == TOPIC_CAR_CONTROL:
        # 制御コマンド: "forward:speed", "stop", "backward:speed"
        if payload.startswith("forward:"):
            speed = int(payload.split(':')[1])
            print(f"前進開始: speed={speed}")
            px.forward(speed)
            car_moving = True
            
        elif payload == "stop":
            print("停止")
            px.stop()
            car_moving = False
            
        elif payload.startswith("backward:"):
            speed = int(payload.split(':')[1])
            print(f"後進開始: speed={speed}")
            px.backward(speed)
            car_moving = True

def status_publisher_thread():
    """定期的にステータスを送信"""
    global client, car_distance, car_moving
    
    while True:
        status = f"distance:{car_distance:.2f},moving:{car_moving}"
        client.publish(TOPIC_CAR_STATUS, status)
        time.sleep(0.1)  # 100msごとに送信

def distance_tracker_thread():
    """移動距離を追跡 (簡易的な推定)"""
    global car_distance, car_moving
    
    # 速度100で約4cm/秒の移動と仮定 (要キャリブレーション)
    speed_cm_per_sec = 4.0
    
    while True:
        if car_moving:
            car_distance += speed_cm_per_sec * 0.1
        time.sleep(0.1)

def main():
    global px, client
    
    print("=== Car2 起動 ===")
    
    # Picarx初期化
    try:
        px = Picarx()
        print("Picarx初期化完了")
    except Exception as e:
        print(f"Picarx初期化エラー: {e}")
        return
    
    # MQTT接続
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    
    print(f"MQTTブローカーに接続中: {BROKER_HOST}:{BROKER_PORT}")
    try:
        client.connect(BROKER_HOST, BROKER_PORT, 60)
    except Exception as e:
        print(f"MQTT接続エラー: {e}")
        print("BROKER_HOSTをMacのIPアドレスに変更してください")
        return
    
    client.loop_start()
    
    # バックグラウンドスレッド起動
    status_thread = threading.Thread(target=status_publisher_thread, daemon=True)
    status_thread.start()
    
    distance_thread = threading.Thread(target=distance_tracker_thread, daemon=True)
    distance_thread.start()
    
    print("準備完了。MQTTメッセージを待機中...")
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n終了します")
    finally:
        px.stop()
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    main()

