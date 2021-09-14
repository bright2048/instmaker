#!/bin/bash
IP=$1
PORT=""
flag="used"
while [[ $flag == "used" ]]; do
	PORT=`python -c 'import random;print(random.randint(10000,60000))'`
	flag=$(echo >/dev/tcp/$IP/$PORT > /dev/null 2>&1 && echo "used" || echo "free")
done
echo $PORT
