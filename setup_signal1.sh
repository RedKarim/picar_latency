#!/bin/bash
# signal1 (Raspberry Pi)のセットアップスクリプト

echo "=== signal1セットアップ開始 ==="

# 依存ライブラリのインストール
echo "依存ライブラリをインストール中..."
sudo apt-get update
sudo apt-get install -y python3-pip python3-pygame

echo "paho-mqttをインストール中..."
pip3 install paho-mqtt

echo "=== セットアップ完了 ==="
echo ""
echo "次のステップ:"
echo "1. signal1.pyを編集してBROKER_HOSTをMacのIPアドレスに変更"
echo "   nano ~/signal1.py"
echo "2. signal1.pyを実行"
echo "   python3 ~/signal1.py"

