# volt

Lightning on Urbit

## Setup

Follow the [LND install guide](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md) and install LND on your host.

If you run a bitcoin fullnode, you must configure LND with connectivity information and credentials for the the bitcoin daemon's RPC server.

- For bitcoind, check the options [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#bitcoind-options) and [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#using-bitcoind-or-litecoind).

- For btcd, check [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#btcd-options) and [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#using-btcd).

As an alternative, you can use LND's embedded neutrino client and a connect to a node that supports `peerblockfilters`. Note that there are some security implications to doing so.

To set it up, In your lnd.conf, set the following:

``` conf
bitcoin.active=1
bitcoin.mainnet=1
bitcoin.node=neutrino
# lightning.community provides a neutrino peer
neutrino.addpeer=faucet.lightning.community
# optionally, you can add your own bitcoin node
# neutrino.addpeer=your.bitcoin.node:1337
feeurl=https://nodes.lightning.computer/fees/v1/btc-fee-estimates.json
```

The set of neutrino options is documented [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#neutrino-options).

### Start the LND Proxy Server

The proxy server `server.js` makes gRPC calls to the Lightning daemon on behalf of your ship and streams data back into it.

``` sh
# install dependencies:
$ npm install express
$ npm install grpc
$ npm install @grpc/proto-loader
# configure the
$ export SHIP_HOST=$host_of_your_ship
$ export SHIP_PORT=$http_port_of_your_ship
# on linux, the default is ~/.lnd/
$ export LND_DIR=$path_to_lnd_data_dir
# on the same machine, the default is localhost:8080
$ export LND_HOST="$lnd_host:$lnd_port"
$ export BTC_NETWORK=mainnet
$ export SERVER_PORT=$lnd-proxy-port
$ node server.js
Proxy listening on port: $lnd-proxy-port
```

### Start the Volt Agents

``` sh
$ ./urbit ~sampel-palnet
~sampel-palnet:dojo> |start %volt-provider
~sampel-palnet:dojo> :volt-provider|command [%set-url 'http://$lnd-proxy-host:$lnd-proxy-port']
~sampel-palnet:dojo> |start %volt
~sampel-palnet:dojo> :volt|command [%set-provider `~sampel-palnet]
```

## Usage

* Sending Payments:

Ensure that your lightning wallet has some satoshis in it, and that it is connected to the
greater lightning network.

``` sh
$ lncli newaddress p2wkh
$ bitcoin-cli -named send \
    outputs='{"${lnd-address}" : 0.010}'
    conf_target=3 \
    estimate_mode=economical
# or via some other wallet
$ lncli openchannel $(counterparty_pubkey) ${local_amt} ${push_amt}
```

``` sh
~sampel-palnet:dojo> :volt|send-payment ~dopzod-wanzod 250.000
```

* Sending Payment Requests:

``` sh
~sampel-palnet:dojo> :volt|send-invoice ~digpur-simmeg-dasrun-fadben 128.000 `'plz pay'
```

## Resources
* [Attacks, Edge Cases and Implementation Recs](ATTACKS_EDGES.md)

## Files
* chacha.js -- ChaCha20 JS reference for testing

``` sh
=c -build-file %/lib/chacha20/hoon
```
