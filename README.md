# volt

Lightning on Urbit

VERY ALPHA EDITION
REPEAT
THIS IS ALPHA SOFTWARE

## Self-Contained Setup

To run connected to the Earthside Lightning network and be able to forward payments to and for other ships:

Follow the [LND install guide](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md) and install LND on your host.

If you're connecting LND to a local bitcoin fullnode, you must configure LND with connectivity information and credentials for the the bitcoin daemon's RPC server.

- For bitcoind, check the options [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#bitcoind-options) and [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#using-bitcoind-or-litecoind).

- For btcd, check [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#btcd-options) and [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#using-btcd).

As an alternative, you can use LND's embedded neutrino client and a connect to a node that supports `peerblockfilters`. Note that there are some security implications to doing so.

To set it up, set the following in your lnd.conf:

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

You will also need to be connected via proxy to a Bitcoin full node. You can find the proxy repo and detailed startup instructions [here](https://github.com/cyclomancer/urbit-bitcoin-rpc). If you don't have a Bitcoin node to connect to, you can connect to the blockchain via another ship over the network using dojo commands noted below.

If you want to run Volt without your own instance of LND, you can still open your own channels but you need to choose a provider ship to route multihop payments for you. (TBA ~tirrel) You can configure this in dojo as shown below, substituting the target ship for your own when running %set-provider.

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
# on the same machine, the default is localhost:10009
$ export LND_HOST="$lnd_host:$lnd_port"
$ export BTC_NETWORK=testnet
$ export SERVER_PORT=$lnd-proxy-port
$ node server.js
Proxy listening on port: $lnd-proxy-port
```

### Start the Volt Agents

``` sh
$ ./urbit ~sampel-palnet
~sampel-palnet:dojo> |install our %volt
```
If you're running the urbit-bitcoin-rpc proxy server yourself:
```sh
~sampel-palnet:dojo> :bitcoin-rpc|command [%set-credentials '$PROXY_IP' '$PROXY_PORT' %.y %testnet]
```
If you're connecting to a Bitcoin proxy owned by another ship:
```sh
~sampel-palnet:dojo> :bitcoin-rpc|command [%set-external $SHIP %testnet]
```
Then, if you're running LND and the LND proxy locally:
```sh
~sampel-palnet:dojo> :volt-provider|command [%set-url 'http://$lnd-proxy-host:$lnd-proxy-port']
```
And finally connect Volt to the provider agent, either local or on another ship:
```sh
~sampel-palnet:dojo> :volt|command [%set-provider `~sampel-palnet]
```

## Usage

* Opening Channels

You need to deposit Bitcoin in a contract with another ship to create a payment channel.

Initiate a channel contract with another ship, and get the address to deposit funds in:
```sh
~sampel-palnet:dojo> :volt|command [%open-channel ~tirrel $AMOUNT_IN_SATOSHIS 0 %testnet]
::  outputs an address to send Volt funds to deposit in the channel
> wallet-address=bcrt1qpc7sn6fk9mycmvz440pwj3g0zdxapuwrx9t2ra
```

The channel will be open for business 3 blocks (~30m on mainnet) after your funds are sent to that address.

* Creating Invoices

Sending a payment requires an invoice to target the payee node.

Generate an invoice to receive a 1000-satoshi payment:
``` sh
~sampel-palnet:dojo> :volt|command [%add-invoice amounts-sats=1.000 memo=`'coffee' network=`%testnet]
::  outputs an invoice string that anyone can use to create a payment (below)
'lnbcrt25u1pj6ae5zpp5yrq03llkcwkw95sczvrhqeen4yuea43s2ltzal69d2r88s2d3ddsdqqcqzzsxqrrsssp5yq2ldsrywpc92z08z4vctq6fu0y3lqdyqt4z6z03vea2cds948ss9qyyssqpstkw92fkmc7a538ee8wxghwe8fyug2x0e0guc89ctcm7sqjmy2r8nug7ajknfurlcu8c8xh6c79pvu575mtz8hzn67a5t8jayxddycpk22vp0'
```

* Sending Payments

Supply Volt with an invoice like the one above and, if the receiver is a known Urbit ship, their @p:
```sh
~sampel-palnet:dojo> :volt|command [%send-payment $INVOICE_STRING `~zod]
```

To transact with non-Urbit Lightning nodes, ensure that your or your provider's LND instance is connected to the greater Lightning network by its own channel(s).

There are multiple flows for doing this and LND operation is outside the scope of the readme, but this is one example:
``` sh
$ lncli newaddress p2wpkh
$ bitcoin-cli -named send \
    outputs='{"${lnd-address}" : 0.010}'
    conf_target=3 \
    estimate_mode=economical
# or via some other wallet
$ lncli openchannel $(counterparty_pubkey) ${local_amt} ${push_amt}
```

If you are running LND yourself, only it has to have a channel open for Volt to send and receive payments with any Lightning node (Volt or Earth) that's connected to the Lightning network.

* API and Integration

Clients and integrating agents use a thread-based API to handle generating and paying invoices. Copy the contents of `ted/api` into your project desk's `/ted`, or send a poke to `%khan` or `%spider` from your front-end client. `ted/api/add-invoice.hoon` will return an invoice like the example above, and `ted/api/send-payment.hoon` accepts an invoice and will return a payment success or error result.


## Resources
* [Attacks, Edge Cases and Implementation Recs](ATTACKS_EDGES.md)
