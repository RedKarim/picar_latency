#!/bin/bash
# 実験を一発で起動するスクリプト

cd /Users/redkarim/Documents/picar_latency

echo "=== 交差点実験 ==="
echo ""
echo "mosquittoブローカーを確認中..."
brew services list | grep mosquitto | grep started > /dev/null
if [ $? -ne 0 ]; then
    echo "mosquittoを起動中..."
    brew services start mosquitto
    sleep 2
fi

echo "実験を開始します..."
echo "Ctrl+Cで終了します"
echo ""

python3 main.py

