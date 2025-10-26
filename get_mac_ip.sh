#!/bin/bash
# MacのローカルネットワークIPアドレスを取得

echo "=== MacのIPアドレス ==="
echo ""

# en0 (通常はWi-Fi) のIPv4アドレスを取得
IP=$(ifconfig en0 | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')

if [ -n "$IP" ]; then
    echo "Wi-Fi (en0): $IP"
else
    echo "Wi-Fiに接続されていません"
fi

# en1 (イーサネットの場合がある) も確認
IP_EN1=$(ifconfig en1 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
if [ -n "$IP_EN1" ]; then
    echo "イーサネット (en1): $IP_EN1"
fi

echo ""
echo "このIPアドレスをcar2.pyとsignal1.pyのBROKER_HOSTに設定してください"

