::
:: sur/volt.hoon
::
/-  bc=bitcoin
|%
::
+$  pubkey    hexb:bc
+$  txid      hexb:bc
+$  hash      hexb:bc
+$  preimage  hexb:bc
::
+$  msats    @ud
+$  chan-id  @ud
+$  htlc-id  @ud
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
        [%send-payment invoice=cord timeout=@dr]
        [%add-invoice =amt=msats memo=(unit cord) preimage=(unit preimage) hash=(unit hash)]
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
  +$  payment-update
    $:  hash=hexb:bc
        =value=msats
        =fee=msats
        request=@t
        status=payment-status
        create-time=@ud
    ==
  ::
  +$  payment-status
    $?  %'IN_FLIGHT'
        %'SUCCEEDED'
        %'FAILED_TIMEOUT'
        %'FAILED_NO_ROUTE'
        %'FAILED_ERROR'
        %'FAILED_INCORRECT_PAYMENT_DETAILS'
        %'FAILED_INSUFFICIENT_BALANCE'
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
  ::
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
        [%send-payment invoice=cord]
        [%add-invoice =amt=msats memo=(unit cord) preimage=(unit preimage) hash=(unit hash)]
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
        [%invoice-added add-invoice-response:rpc]
        [%invoice-update invoice:rpc]
        [%channel-update channel-update:rpc]
        [%payment-update payment-update:rpc]
        [%balance-update wallet-balance-response:rpc]
    ==
  ::
  +$  update  (each result error)
  ::
  +$  status  ?(%connected %disconnected)
  --
::
::  client types
::
+$  command
  $%  [%set-provider provider=(unit ship)]
      [%open-channel ~]
      [%close-channel ~]
      [%wallet-balance ~]
      [%send-payment to=ship =amt=msats]
      [%add-invoice =amt=msats memo=(unit cord)]
      [%reset ~]
  ==
::
+$  action
  $%  [%request-invoice =amt=msats]
      [%request-payment invoice=cord]
  ==
::
+$  payment-state
  $?  %sent-invoice-request
      %pending-invoice
      %sent-payment-request
      %pending-payment
      %sent-payment
      %complete
      %canceled
      %failed
  ==
::
+$  payment
  $:  stat=payment-state
      dire=?(%incoming %outgoing)
      pyer=ship
      pyee=ship
      amnt=msats
      pyre=(unit cord)
      prem=(unit preimage)
      hash=(unit hash)
  ==
--
