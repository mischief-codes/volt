# volt

Lightning on Urbit

ALPHA EDITION
REPEAT
THIS IS ALPHA SOFTWARE
Testnet coins and small mainnet amounts are strongly advised until further notice. Currently the allowed channel capacity is hardcoded between 60.000 satoshis (60 ksats, 0.0006 BTC) and 300ks, or approximately 40-200USD at time of writing.

## Quickstart

1. Install from ~dister-dozzod-tirrel
2. If you want to use testnet coins, use the Set Provider menu in the UI to change your routing provider to ~TBD
3. Use the Open Channel menu to initiate a payment channel with your routing provider. By default that's ~falfer-docres-dozzod-tirrel (for mainnet Bitcoin routing). If you changed it in step 2, open your channel to that ship instead.
4. Send the exact amount displayed (chosen capacity + estimated L1 transaction fee) to the generated Bitcoin (L1) address. You can do this from any Bitcoin wallet, just make sure testnet coins go to testnet channels and mainnet coins go to mainnet channels, and that you send the correct amount. This L1 address is a hot wallet on your ship, so if you mess up the funds can be recovered, but currently that is a very manual process.
<PAUSE HERE>
5. The channel will be open in 4 blocks, approximately 40 minutes.

## Basics

_Get paid_: Use the Add Invoice menu (UI) or %add-invoice command (dojo) to generate an 'invoice' or 'payreq' that's used to route a payment to your ship. The UI will display string and QR representations, dojo naturally only string. This invoice can be used by any Lightning user on Earth or Mars to send a payment to your ship.
_Send a payment using an invoice_: Send Payment menu or %send-payment command. If you received the invoice from an Urbit operator and know their @p, include that field for best routing efficiency in some cases.
_Send a payment to an Urbit ship, no invoice needed_:
_Open another channel with a frequent recipient, or for additional routing liquidity with your provider_: You can open a channel with any Volt node. Currently only providers route indirect payments, but if you transact with another ship regularly, or want to do so with full privacy, you can open a dedicated channel with them. You can also open more channels with your provider to increase your capacity to send payments.

## Not-so-quickstart

To run connected to the Earthside Lightning network and be able to forward payments for other ships:

Follow the [LND install guide](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md) and install LND on your host.

If you're connecting LND to a local bitcoin fullnode, you must configure LND with connectivity information and credentials for the the bitcoin daemon's RPC server.

- For bitcoind, check the options [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#bitcoind-options) and [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#using-bitcoind-or-litecoind).

- For btcd, check [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#btcd-options) and [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#using-btcd).

You will also need to be connected via proxy to a Bitcoin full node. You can find the proxy repo and startup instructions [here](https://github.com/cyclomancer/urbit-bitcoin-rpc). If you don't have a Bitcoin node to connect to, you can connect to the blockchain via another ship over the network using dojo commands noted below.

Finally, your LND node will also 

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

The channel will be open for business 4 blocks (~40m on mainnet) after your funds are sent to that address.

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
