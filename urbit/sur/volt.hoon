::  sur/volt.hoon
::
/-  bc=bitcoin, bolt
|%
+$  pubkey    pubkey:bolt
+$  txid      hexb:bc
+$  hash      hexb:bc
+$  preimage  hexb:bc
::
+$  msats    msats:bolt
+$  chan-id  id:bolt
+$  htlc-id  htlc-id:bolt
::
+$  circuit-key
  $:  =chan-id
      =htlc-id
  ==
::
+$  node-info
  $:  version=@t
      commit-hash=@t
      =identity=pubkey
  ==
::
+$  htlc-info
  $:  =circuit-key  :: incoming circuit
      =hash         :: payment hash
      =chan-id      :: outgoing channel
  ==
::
++  rpc
  |%
  +$  action
    $%  [%get-info ~]
        [%wallet-balance ~]
        [%open-channel node=pubkey local-amount=sats:bc push-amount=sats:bc]
        [%close-channel funding-txid=txid output-index=@ud]
        [%settle-htlc =circuit-key =preimage]
        [%fail-htlc =circuit-key]
        [%send-payment invoice=cord timeout=(unit @dr) fee-limit=(unit sats:bc)]
        $:  %add-invoice
          =amt=msats
          memo=(unit cord)
          preimage=(unit preimage)
          hash=(unit hash)
          expiry=(unit @dr)
        ==
        [%cancel-invoice =payment=hash]
    ==
  ::
  +$  result
    $%  [%get-info node-info]
        [%wallet-balance total=msats confirmed=msats unconfirmed=msats]
        [%open-channel channel-point]
        [%close-channel ~]
        [%settle-htlc =circuit-key]
        [%fail-htlc =circuit-key]
        [%send-payment ~]
        [%add-invoice add-invoice-response]
        [%cancel-invoice ~]
    ==
  ::
  +$  error
    $:  code=@ud
        message=@t
    ==
  ::
  +$  response  (each result error)
  ::
  +$  route-hint
    $:  node-id=pubkey
        =chan-id
        fee-base-msat=@ud
        fee-proportional-usat=@ud
        cltv-expiry-delta=@ud
    ==
  ::
  +$  channel-update
    $%  [%open-channel channel]
        [%closed-channel channel-close-summary]
        [%active-channel channel-point]
        [%inactive-channel channel-point]
        [%pending-channel pending-channel]
    ==
  ::
  +$  channel
    $:  active=?
        remote-pubkey=pubkey
        channel-point=@t
        =chan-id
        capacity=sats:bc
        local-balance=sats:bc
        remote-balance=sats:bc
        commit-fee=sats:bc
        total-sent=sats:bc
    ==
  ::
  +$  channel-close-summary
    $:  channel-point=@t
        =chan-id
        chain-hash=@t
        closing-tx-hash=@t
        remote-pubkey=pubkey
        channel-closure-type=@tas
    ==
  ::
  +$  channel-point
    $:  funding-txid=txid
        output-index=@ud
    ==
  ::
  +$  pending-channel
    $:  =txid
        output-index=@ud
    ==
  ::
  +$  htlc-intercept-request
    $:  incoming-circuit-key=circuit-key
        incoming-amount-msat=sats:bc
        incoming-expiry=@ud
        payment-hash=hexb:bc
        outgoing-requested-chan-id=chan-id
        outgoing-amount-msat=sats:bc
        outgoing-expiry=@ud
        onion-blob=hexb:bc
    ==
  ::
  +$  htlc-intercept-response
    $:  incoming-circuit-key=circuit-key
        action=htlc-action
        preimage=(unit hexb:bc)
    ==
  ::
  +$  htlc-action  ?(%'SETTLE' %'FAIL' %'RESUME')
  ::
  +$  payment
    $:  =hash
        =preimage
        =value=msats
        =fee=msats
        request=cord
        status=payment-status
        failure-reason=payment-failure-reason
        creation-time=@da
    ==
  ::
  +$  payment-status
    $?  %'UNKNOWN'
        %'IN_FLIGHT'
        %'SUCCEEDED'
        %'FAILED'
    ==
  ::
  +$  payment-failure-reason
    $~  %'FAILURE_REASON_NONE'
    $?  %'FAILURE_REASON_NONE'
        %'FAILURE_REASON_TIMEOUT'
        %'FAILURE_REASON_NO_ROUTE'
        %'FAILURE_REASON_ERROR'
        %'FAILURE_REASON_INCORRECT_PAYMENT_DETAILS'
        %'FAILURE_REASON_INSUFFICIENT_BALANCE'
    ==
  ::
  +$  wallet-balance-response
    $:  total-balance=msats
        confirmed-balance=msats
        unconfirmed-balance=msats
    ==
  ::
  +$  add-invoice-response
    $:  r-hash=hexb:bc
        payment-request=cord
        add-index=@ud
        payment-address=hexb:bc
    ==
  ::
  +$  invoice
    $:  memo=cord
        =r=preimage
        =r=hash
        =value=msats
        settled=?
        creation-date=@da
        settle-date=@da
        expiry=@dr
        payment-request=cord
        add-index=@ud
        settle-index=@ud
        =amt-paid=msats
        state=invoice-state
    ==
  ::
  +$  invoice-state
    $?  %'OPEN'
        %'SETTLED'
        %'CANCELED'
        %'ACCEPTED'
    ==
  --
::
::  provider types
::
++  provider
  |%
  +$  host-info
    $:  api-url=@t
        connected=?
        clients=(set ship)
    ==
  ::
  +$  command
    $%  [%set-url api-url=@t]
        [%open-channel to=pubkey local-amt=sats:bc push-amt=sats:bc]
        [%close-channel funding-txid=txid output-index=@ud]
    ==
  ::
  +$  action
    $%  [%ping ~]
        [%wallet-balance ~]
        [%settle-htlc =htlc-info =preimage]
        [%fail-htlc =htlc-info]
        [%send-payment invoice=cord timeout=(unit @dr) fee-limit=(unit sats:bc)]
        $:  %add-invoice
          =amt=msats
          memo=(unit cord)
          preimage=(unit preimage)
          hash=(unit hash)
          expiry=(unit @dr)
        ==
        [%cancel-invoice =payment=hash]
    ==
  ::
  +$  error
    $%  [%rpc-error error:rpc]
        [%not-connected ~]
        [%bad-request ~]
    ==
  ::
  +$  result
    $%  [%node-info =node-info]
        [%htlc htlc-intercept-request:rpc]
        [%invoice-added add-invoice-response:rpc]
        [%invoice-update invoice:rpc]
        [%channel-update channel-update:rpc]
        [%payment-update payment:rpc]
        [%balance-update wallet-balance-response:rpc]
    ==
  ::
  +$  update  (each result error)
  ::
  +$  status  ?(%connected %disconnected)
  --
::
::  wallet types
::
++  wallet
  |%
  +$  action
    $%  [%new-wallet seed=(unit hexb:bc)]
        [%get-public-key path=(list @u)]
        [%get-address path=(list @u)]
        [%sign-digest path=(list @u) hash=hexb:bc]
    ==
  ::
  +$  result
    $%  [%public-key path=(list @u) =pubkey]
        [%address path=(list @u) =address:bc]
        [%signature path=(list @u) signature=hexb:bc]
    ==
  --
::
::  client types
::
+$  payreq  cord
::
+$  payment
  $:  payer=ship
      payee=ship
      fee-limit=(unit sats:bc)
      payment:rpc
  ==
::
+$  invoice
  $:  payer=ship
      payee=ship
      invoice:rpc
  ==
::
+$  payment-request
  $:  payer=ship
      payee=ship
      status=payment-status:rpc
      =payreq
      =amount=msats
      received-at=@da
  ==
::
+$  command
  $%  [%set-provider provider=(unit ship)]
      [%set-btc-provider provider=(unit ship)]
      [%open-channel who=ship =network:bolt funding-tx=@t =funding=sats:bc =push=msats]
      [%close-channel =chan-id]
      [%send-payment to=ship =amt=msats fee-limit=(unit sats:bc)]
      [%create-funding temporary-channel-id=@ funding-tx=@t]
  ==
::
+$  action
  $%  [%request-invoice =amt=msats]
      [%request-payment =payreq]
      [%payment-receipt =payment=hash]
      [%send-payment to=ship =amt=msats]
      [%send-invoice to=ship =amt=msats memo=(unit cord)]
  ==
::
+$  update
  $%  [%need-funding-signature temporary-channel-id=@ psbt=@t]
      [%channel-state =chan-id =chan-state:bolt]
      [%channel-closed =chan-id]
  ==
--
