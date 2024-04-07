#!/bin/bash

export SHIP_HOST=127.0.0.1
export SHIP_PORT=8081
export LND_DIR=/home/armitage/.lnd
export LND_HOST="127.0.0.1:10009"
export BTC_NETWORK=regtest
export SERVER_PORT=8088

node ./server.js
