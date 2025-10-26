# クイックスタートガイド

## 前提条件

- Mac に mosquitto がインストール済み
- car2 と signal1 に SSH 接続可能
- すべてのデバイスが同じネットワークに接続されている

## セットアップ (初回のみ)

### ステップ 1: Mac の準備

```bash
cd /Users/redkarim/Documents/picar_latency

# Python依存ライブラリをインストール
pip3 install paho-mqtt

# Mosquittoブローカーを起動
brew services start mosquitto

# MacのIPアドレスを確認
ifconfig | grep "inet " | grep -v 127.0.0.1
# 例: inet 192.168.1.100
```

### ステップ 2: 自動デプロイ

```bash
# deploy.shを実行してファイルをRaspberry Piにデプロイ
./deploy.sh

# MacのIPアドレスを入力 (例: 192.168.1.100)
# スクリプトが自動的に:
# - car2.pyとsignal1.pyのBROKER_HOSTを更新
# - 各Raspberry Piにファイルをコピー
# - 依存ライブラリをインストール
```

## 実験の実行

### ステップ 1: signal1 を起動 (別のターミナル)

```bash
ssh signal1
python3 ~/signal1.py
```

### ステップ 2: car2 を起動 (別のターミナル)

```bash
ssh car2
python3 ~/car2.py
```

### ステップ 3: メインプログラムを起動 (Mac で)

```bash
cd /Users/redkarim/Documents/picar_latency
python3 main.py
```

## 実験の流れ

1. main.py が起動すると、レイテンシ測定が開始される
2. 5 秒後、車に前進コマンドが送信される
3. 車が 10cm 移動
4. 信号の色を確認:
   - **赤または黄**: 車は停止し、緑になるまで待機
   - **緑**: そのまま前進
5. 緑信号で再び前進
6. レイテンシデータが CSV ファイルに保存される

## 結果の確認

```bash
# レイテンシデータを確認
cat car2_latency.csv
cat signal1_latency.csv

# CSVファイルをExcelなどで開いて分析可能
```

## トラブルシューティング

### "MQTT 接続エラー" が表示される

1. Mac で mosquitto が起動しているか確認:

```bash
brew services list | grep mosquitto
```

2. ファイアウォールを無効化または 1883 ポートを開く

3. Mac と Raspberry Pi が同じネットワークにいるか確認:

```bash
# Macから
ping raspberrypi.local
ping raspberrypi2.local
```

### car2 が動かない

1. Picarx の初期化を確認
2. 権限を確認:

```bash
sudo usermod -aG i2c,spi,gpio car2
sudo reboot
```

### signal1 の画面が表示されない

1. HDMI ケーブルでモニターに接続されているか確認
2. pygame がインストールされているか確認:

```bash
pip3 list | grep pygame
```

## 実験の停止

すべてのターミナルで `Ctrl+C` を押す

## 手動セットアップ (deploy.sh が使えない場合)

### car2 の手動セットアップ

```bash
# Macから
scp car2.py setup_car2.sh car2:~/

# car2で
ssh car2
chmod +x ~/setup_car2.sh
./setup_car2.sh

# BROKER_HOSTを編集
nano ~/car2.py
# BROKER_HOST = "192.168.1.100" を実際のMacのIPに変更
```

### signal1 の手動セットアップ

```bash
# Macから
scp signal1.py setup_signal1.sh signal1:~/

# signal1で
ssh signal1
chmod +x ~/setup_signal1.sh
./setup_signal1.sh

# BROKER_HOSTを編集
nano ~/signal1.py
# BROKER_HOST = "192.168.1.100" を実際のMacのIPに変更
```
