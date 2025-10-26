#!/bin/bash
# MacからRaspberry Piにファイルをデプロイするスクリプト

echo "=== デプロイスクリプト ==="
echo ""
echo "MacのIPアドレスを入力してください (例: 192.168.1.100):"
read MAC_IP

if [ -z "$MAC_IP" ]; then
    echo "エラー: IPアドレスが入力されていません"
    exit 1
fi

echo ""
echo "MacのIPアドレス: $MAC_IP"
echo ""

# car2.pyのBROKER_HOSTを更新
echo "car2.pyのBROKER_HOSTを更新中..."
sed "s/BROKER_HOST = \"192.168.1.100\"/BROKER_HOST = \"$MAC_IP\"/g" car2.py > car2_temp.py
mv car2_temp.py car2.py

# signal1.pyのBROKER_HOSTを更新
echo "signal1.pyのBROKER_HOSTを更新中..."
sed "s/BROKER_HOST = \"192.168.1.100\"/BROKER_HOST = \"$MAC_IP\"/g" signal1.py > signal1_temp.py
mv signal1_temp.py signal1.py

# car2にデプロイ
echo ""
echo "=== car2にデプロイ中 ==="
scp car2.py setup_car2.sh car2:~/
if [ $? -eq 0 ]; then
    echo "car2へのデプロイ成功"
    echo "car2でセットアップを実行中..."
    ssh car2 "chmod +x ~/setup_car2.sh && ~/setup_car2.sh"
else
    echo "car2へのデプロイ失敗"
fi

# signal1にデプロイ
echo ""
echo "=== signal1にデプロイ中 ==="
scp signal1.py setup_signal1.sh signal1:~/
if [ $? -eq 0 ]; then
    echo "signal1へのデプロイ成功"
    echo "signal1でセットアップを実行中..."
    ssh signal1 "chmod +x ~/setup_signal1.sh && ~/setup_signal1.sh"
else
    echo "signal1へのデプロイ失敗"
fi

echo ""
echo "=== デプロイ完了 ==="
echo ""
echo "次のステップ:"
echo "1. signal1で信号を起動:"
echo "   ssh signal1"
echo "   python3 ~/signal1.py"
echo ""
echo "2. car2で車を起動:"
echo "   ssh car2"
echo "   python3 ~/car2.py"
echo ""
echo "3. Macでメインプログラムを起動:"
echo "   python3 main.py"

