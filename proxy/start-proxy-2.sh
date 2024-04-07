#!/bin/bash

export SHIP_HOST=127.0.0.1
export SHIP_PORT=8082
export LND_DIR=/home/armitage/lnd2
export LND_HOST="127.0.0.1:10010"
export BTC_NETWORK=regtest
export SERVER_PORT=8089

node ./server.js
