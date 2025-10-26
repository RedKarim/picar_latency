#!/bin/bash
# car2 (Raspberry Pi)のセットアップスクリプト

echo "=== car2セットアップ開始 ==="

# 依存ライブラリのインストール
echo "依存ライブラリをインストール中..."
sudo apt-get update
sudo apt-get install -y python3-pip

echo "paho-mqttをインストール中..."
pip3 install paho-mqtt

echo "=== セットアップ完了 ==="
echo ""
echo "次のステップ:"
echo "1. car2.pyを編集してBROKER_HOSTをMacのIPアドレスに変更"
echo "   nano ~/car2.py"
echo "2. car2.pyを実行"
echo "   python3 ~/car2.py"

