import paho.mqtt.client as mqtt
import time
import threading
try:
    import pygame
except ImportError:
    print("pygame not installed. No visual signal display")
    pygame = None

# MQTTブローカー設定 (Mac)
BROKER_HOST = "10.21.89.67"  # Macのローカルネットワークアドレス
BROKER_PORT = 1883

# トピック定義
TOPIC_SIGNAL_PING = "signal1/ping"
TOPIC_SIGNAL_PONG = "signal1/pong"
TOPIC_SIGNAL_STATUS = "signal1/status"

# 信号の状態
current_signal = "RED"
client = None

# 信号サイクル設定 (秒)
SIGNAL_CYCLE = [
    ("RED", 20),
    ("GREEN", 20),
    ("YELLOW", 5)
]

def on_connect(client, userdata, flags, rc):
    print(f"Connected to MQTT Broker: {rc}")
    client.subscribe(TOPIC_SIGNAL_PING)

def on_message(client, userdata, msg):
    topic = msg.topic
    payload = msg.payload.decode()
    
    if topic == TOPIC_SIGNAL_PING:
        # pingに即座にpongで応答
        client.publish(TOPIC_SIGNAL_PONG, payload)

def status_publisher_thread():
    """Periodically publish status"""
    global client, current_signal
    
    while True:
        client.publish(TOPIC_SIGNAL_STATUS, current_signal)
        time.sleep(0.1)  # Send every 100ms

def signal_cycle_thread():
    """Manage signal cycle"""
    global current_signal
    
    while True:
        for signal_color, duration in SIGNAL_CYCLE:
            current_signal = signal_color
            print(f"Signal: {signal_color} ({duration}s)")
            time.sleep(duration)

def display_signal_pygame():
    """Display signal visually with Pygame"""
    global current_signal
    
    if pygame is None:
        print("Pygame not available")
        return
    
    pygame.init()
    
    # フルスクリーン設定
    screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
    width, height = screen.get_size()
    pygame.display.set_caption("Traffic Signal")
    
    # 色定義
    colors = {
        "RED": (255, 0, 0),
        "GREEN": (0, 255, 0),
        "YELLOW": (255, 255, 0),
        "OFF": (50, 50, 50)
    }
    
    clock = pygame.time.Clock()
    
    try:
        running = True
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE or event.key == pygame.K_q:
                        running = False
            
            # 背景を黒に
            screen.fill((0, 0, 0))
            
            # 信号の円を描画
            circle_radius = min(width, height) // 6
            spacing = circle_radius * 2 + 50
            center_x = width // 2
            start_y = height // 2 - spacing
            
            # 赤信号
            red_color = colors["RED"] if current_signal == "RED" else colors["OFF"]
            pygame.draw.circle(screen, red_color, (center_x, start_y), circle_radius)
            
            # 黄信号
            yellow_color = colors["YELLOW"] if current_signal == "YELLOW" else colors["OFF"]
            pygame.draw.circle(screen, yellow_color, (center_x, start_y + spacing), circle_radius)
            
            # 緑信号
            green_color = colors["GREEN"] if current_signal == "GREEN" else colors["OFF"]
            pygame.draw.circle(screen, green_color, (center_x, start_y + spacing * 2), circle_radius)
            
            # テキスト表示
            font = pygame.font.Font(None, 72)
            text = font.render(current_signal, True, (255, 255, 255))
            text_rect = text.get_rect(center=(center_x, height - 100))
            screen.blit(text, text_rect)
            
            pygame.display.flip()
            clock.tick(30)  # 30 FPS
            
    except KeyboardInterrupt:
        pass
    finally:
        pygame.quit()

def display_signal_console():
    """Display signal in console"""
    global current_signal
    
    while True:
        print(f"\rCurrent signal: {current_signal}   ", end='', flush=True)
        time.sleep(0.5)

def main():
    global client
    
    print("=== Signal1 Starting ===")
    
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
    
    # Start background threads
    status_thread = threading.Thread(target=status_publisher_thread, daemon=True)
    status_thread.start()
    
    cycle_thread = threading.Thread(target=signal_cycle_thread, daemon=True)
    cycle_thread.start()
    
    print("Ready. Starting signal cycle...")
    time.sleep(1)
    
    # Display mode selection
    if pygame is not None:
        try:
            display_signal_pygame()
        except Exception as e:
            print(f"Pygame display error: {e}")
            print("Switching to console mode")
            try:
                while True:
                    display_signal_console()
            except KeyboardInterrupt:
                print("\nExiting")
    else:
        # Console display if no Pygame
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nExiting")
    
    client.loop_stop()
    client.disconnect()

if __name__ == "__main__":
    main()

