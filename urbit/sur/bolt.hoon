::  sur/bolt.hoon
::  Datatypes to implement Lightning BOLT RFCs.
::
/-  bc=bitcoin, psbt
|%
+$  id       @ud
+$  htlc-id  @ud
+$  blocks   @ud  ::  number of blocks
+$  msats    @ud  ::  millisats
+$  commitment-number  @sd
::
+$  pubkey     point
+$  privkey    hexb:bc
+$  signature  hexb:bc
::
+$  network   ?(network:bc %regtest)
+$  point     point:secp:crypto
+$  outpoint  [=txid:bc pos=@ud =sats:bc]
+$  witness   (list hexb:bc)
::  +const: protocol constants
::
++  const
  |%
  ++  min-final-cltv-expiry  144
  ++  min-remote-delay       144
  ++  max-remote-delay       2.016
  ++  min-funding-sats       200.000
  ++  max-funding-sats       16.777.216
  ++  max-htlc-number        966
  ++  min-confirmations      3
  ++  max-confirmations      6
  ++  dust-limit-sats        546
  ::
  ++  fee-eta-target         2
  ++  feerate-regtest        180.000
  ++  feerate-max-dynamic    1.500.000
  ++  feerate-fallback       150.000
  ++  feerate-default-relay  1.000
  ++  feerate-max-relay      50.000
  ++  feerate-per-kw-min-relay  253
  --
::  +key: key-related types
::
++  key
  |%
  +$  family
    $?  %multisig
        %revocation-base
        %htlc-base
        %payment-base
        %delay-base
        %revocation-root
        %node-key
    ==
  +$  pair  [pub=pubkey prv=@]
  --
::
+$  basepoints
  $:  revocation=pair:key
      payment=pair:key
      delayed-payment=pair:key
      htlc=pair:key
  ==
::
++  channel-config
  $:  =ship
      =network
      =basepoints
      multisig-key=pair:key
      to-self-delay=blocks
      =dust-limit=sats:bc
      =max-htlc-value-in-flight=msats
      max-accepted-htlcs=@ud
      =initial=msats
      =reserve=sats:bc
      =htlc-minimum=msats
      upfront-shutdown-script=hexb:bc
      anchor-outputs=?
  ==
::
++  local-config
  $:  channel-config
      seed=hexb:bc
      funding-locked-received=?
      =current-commitment=signature
      current-htlc-signatures=(list signature)
      per-commitment-secret-seed=hexb:bc
  ==
::
++  remote-config
  $:  channel-config
      =next-per-commitment=point
      =current-per-commitment=point
  ==
::  +larva-chan: a channel in the larval state
::   - holds all the messages back and forth until finalized
::   - used to build chan
::
+$  larva-chan
  $:  initiator=?
      our=local-config
      her=remote-config
      oc=(unit open-channel:msg)
      ac=(unit accept-channel:msg)
  ==
::
+$  fee-update
  $:  rate=sats:bc
      local-commitment-number=(unit commitment-number)
      remote-commitment-number=(unit commitment-number)
  ==
::
+$  direction  ?(%sent %received)
+$  owner      ?(%local %remote)
+$  htlc-info  (map owner commitment-number)
::
+$  htlc-state
  $:  adds=(map htlc-id update-add-htlc:msg)
      locked-in=(map htlc-id htlc-info)
      settles=(map htlc-id htlc-info)
      fails=(map htlc-id htlc-info)
      fee-updates=(list fee-update)
      revack-pending=$~(%.n ?)
      =next=htlc-id
      commitment-number=$~(-1 commitment-number)
  ==
::
+$  htlc
  $:  update-add-htlc:msg
      witness=hexb:bc
  ==
::  +revocation-store: BOLT-03 revocation storage
::
+$  revocation-store
  $~  :*  idx=(dec (bex 48))
          buckets=*(map @u shachain-element)
      ==
  $:  idx=@ud
      buckets=(map @u shachain-element)
  ==
+$  shachain-element  [idx=@ud secret=hexb:bc]
::  +chan-state: channel state
::
+$  chan-state
  $~  %preopening
  $?  %preopening
      %opening
      %funded
      %open
      %shutdown
      %closing
      %force-closing
      %closed
      %redeemed
  ==
::  +chan: full channel representation
::
+$  chan
  $:  =id
      state=chan-state
      =funding=outpoint
      ::
      $=  constraints
      $:  initiator=?
          anchor-outputs=?
          capacity=sats:bc
          funding-tx-min-depth=blocks
      ==
      ::
      $=  config
      $:  our=local-config
          her=remote-config
      ==
      ::
      $=  htlcs
      $:  our=htlc-state
          her=htlc-state
      ==
      ::
      revocations=revocation-store
  ==
::  +msg: BOLT spec messages between peers
::    defined in RFC02
::
++  msg
  |%
  ::  funding messages
  ::
  +$  open-channel
    $:  chain-hash=hexb:bc
        temporary-channel-id=@
        =funding=sats:bc
        =push=msats
        =funding=pubkey
        =dust-limit=sats:bc
        =max-htlc-value-in-flight=msats
        =channel-reserve=sats:bc
        =htlc-minimum=msats
        feerate-per-kw=sats:bc
        to-self-delay=blocks
        cltv-expiry-delta=blocks
        max-accepted-htlcs=@ud
        =basepoints
        =first-per-commitment=point
        =shutdown-script=pubkey
        anchor-outputs=?
    ==
  ::
  +$  accept-channel
    $:  temporary-channel-id=@
        =dust-limit=sats:bc
        =max-htlc-value-in-flight=msats
        =channel-reserve=sats:bc
        =htlc-minimum=msats
        minimum-depth=blocks
        to-self-delay=blocks
        max-accepted-htlcs=@ud
        =funding=pubkey
        =basepoints
        =first-per-commitment=point
        =shutdown-script=pubkey
        anchor-outputs=?
    ==
  ::
  +$  funding-created
    $:  temporary-channel-id=@
        funding-txid=hexb:bc
        funding-idx=@u
        =signature
    ==
  ::
  +$  funding-signed
    $:  =channel=id
        =signature
    ==
  ::
  +$  funding-locked
    $:  =channel=id
        =next-per-commitment=point
    ==
  ::
  ::  htlc messages
  ::
  +$  add-signed-htlc
    $:  add=update-add-htlc
        sign=commitment-signed
    ==
  ::
  +$  update-add-htlc
    $:  =channel=id
        =htlc-id
        =amount=msats
        payment-hash=hexb:bc
        cltv-expiry=blocks
    ==
  ::
  +$  commitment-signed
    $:  =channel=id
        sig=signature
        num-htlcs=@ud
        htlc-sigs=(list signature)
    ==
  ::
  +$  revoke-and-ack
    $:  =channel=id
        per-commitment-secret=hexb:bc
        next-per-commitment-point=point
    ==
  ::
  ::  closing messages
  ::
  +$  shutdown
    $:  =channel=id
        script-pubkey=hexb:bc
    ==
  ::
  +$  closing-signed
    $:  =channel=id
        =fee=sats:bc
        =signature
        min-fee=(unit sats:bc)
        max-fee=(unit sats:bc)
    ==
  --
::
+$  message
  $%  [%open-channel open-channel:msg]
      [%accept-channel accept-channel:msg]
      [%funding-created funding-created:msg]
      [%funding-signed funding-signed:msg]
      [%funding-locked funding-locked:msg]
    ::
      [%shutdown shutdown:msg]
      [%closing-signed closing-signed:msg]
    ::
      [%update-add-htlc update-add-htlc:msg]
      [%commitment-signed commitment-signed:msg]
      [%revoke-and-ack revoke-and-ack:msg]
    ::
      [%update-fulfill-htlc =channel=id =id preimage=hexb:bc]
      [%update-fail-htlc =channel=id =id reason=@t]
      [%update-fail-malformed-htlc =channel=id =id]
      [%update-fee =channel=id feerate-per-kw=sats:bc]
  ==
--
