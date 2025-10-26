# PiCar Traffic Light Experiment

交差点での信号待ちシミュレーション実験

## アーキテクチャ

- **Mac (中央サーバー)**: main.py を実行、MQTTブローカー、レイテンシ測定、車の制御判断
- **car2 (Raspberry Pi)**: car2.py を実行、Picarxを制御、MQTTクライアント
- **signal1 (Raspberry Pi)**: signal1.py を実行、信号表示、MQTTクライアント

## セットアップ

### 1. Macのセットアップ

```bash
# Mosquitto MQTTブローカーが既にインストール済み

# Python依存ライブラリをインストール
pip3 install paho-mqtt

# Macのローカルネットワークアドレスを確認
ifconfig | grep "inet "
# 例: 192.168.1.100
```

### 2. car2 (Raspberry Pi) のセットアップ

```bash
# car2にSSH接続
ssh car2

# 依存ライブラリをインストール
sudo apt-get update
sudo apt-get install -y python3-pip
pip3 install paho-mqtt

# car2.pyをコピー (scpコマンドをMacから実行)
# 戻って、Macで:
scp /Users/redkarim/Documents/picar_latency/car2.py car2:~/

# car2.pyを編集してBROKER_HOSTをMacのIPアドレスに変更
# car2で:
nano ~/car2.py
# BROKER_HOST = "192.168.1.100"  を実際のMacのIPに変更
```

### 3. signal1 (Raspberry Pi) のセットアップ

```bash
# signal1にSSH接続
ssh signal1

# 依存ライブラリをインストール
sudo apt-get update
sudo apt-get install -y python3-pip python3-pygame
pip3 install paho-mqtt

# signal1.pyをコピー (scpコマンドをMacから実行)
# 戻って、Macで:
scp /Users/redkarim/Documents/picar_latency/signal1.py signal1:~/

# signal1.pyを編集してBROKER_HOSTをMacのIPアドレスに変更
# signal1で:
nano ~/signal1.py
# BROKER_HOST = "192.168.1.100"  を実際のMacのIPに変更
```

## 実行方法

### 手順

1. **Macでmain.pyを起動** (最後に起動)
```bash
cd /Users/redkarim/Documents/picar_latency
python3 main.py
```

2. **signal1でsignal1.pyを起動**
```bash
ssh signal1
python3 ~/signal1.py
```

3. **car2でcar2.pyを起動**
```bash
ssh car2
python3 ~/car2.py
```

### 実験シナリオ

1. main.pyが起動すると、車に前進コマンドを送信 (`px.forward(100)`)
2. 車が10cm移動するのを待つ
3. 10cm移動後、信号の色をチェック:
   - **赤/黄**: 車は停止し、緑になるまで待機
   - **緑**: そのまま前進を続ける
4. 緑信号になったら、再び `px.forward(100)` で前進

### 信号サイクル

- 赤: 20秒
- 緑: 20秒
- 黄: 5秒

(このサイクルを繰り返す)

## レイテンシ測定

- 毎秒3回のping/pongメッセージを各デバイスに送信
- ラウンドトリップレイテンシを測定
- 結果をCSVファイルに保存:
  - `car2_latency.csv`
  - `signal1_latency.csv`

## トラブルシューティング

### MQTTブローカーに接続できない

```bash
# Macでmosquittoが起動しているか確認
brew services list | grep mosquitto

# 起動していない場合
brew services start mosquitto

# ファイアウォールを確認 (Macで)
# システム環境設定 > セキュリティとプライバシー > ファイアウォール
```

### car2.pyでPicarxが初期化できない

```bash
# car2で権限を確認
sudo usermod -aG i2c,spi,gpio car2

# 再起動
sudo reboot
```

### signal1でPygameが表示されない

```bash
# X11転送を有効にしてSSH接続
ssh -X signal1

# または、HDMI接続したモニターで直接実行
```

## 注意事項

- 移動距離の計算は簡易的な推定です。正確な測定にはエンコーダーが必要です。
- car2.pyの`speed_cm_per_sec`値はキャリブレーションが必要な場合があります。
- Macとラズパイが同じネットワークに接続されている必要があります。

