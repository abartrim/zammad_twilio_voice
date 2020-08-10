#!/bin/bash

URL="http://127.0.0.1:3000/api/v1/cti/khoncwx7xNS5OT3d48vpSmAoJU8"
FROM="493055571600"
TO="491711234567890"
# FROM="14803817264"
# TO="12063098672"
CID="TEST"$(((RANDOM % 10000)+1))
USER1="Test"
USER2="User"

echo "Using CID=${CID} as the ID for the call" 
# DATA_CALL="event=newCall&from=493055571600&to=491711234567890&direction=in&callId=123456&user[]=Alice&user[]=Bob"
DATA_CALL="event=newCall&from=${FROM}&to=${TO}&direction=in&callId=${CID}&user[]=${USER1}&user[]=${USER2}"
DATA_ANSWER="event=answer&callId=${CID}&user=${USER1}+${USER2}&from=${FROM}&to=${TO}&direction=in&answeringNumber=${TO}"
DATA_HANGUP="event=hangup&cause=normalClearing&callId=${CID}&from=${FROM}&to=${TO}&direction=in&answeringNumber=${TO}"
DATA_DIAL=""

# New Call
read -p "Press enter when you want to make a call"
echo "Sending data: ${DATA_CALL}"
curl -X POST --data "${DATA_CALL}" $URL
echo ""
# Wait intil we are ready to say it's answered
read -p "Press enter when you want to send called answered"
curl -X POST --data "${DATA_ANSWER}" $URL
echo ""

# Wait for hangup
read -p "Press enter when you want to hangup"
curl -X POST --data "${DATA_HANGUP}" $URL
echo ""

