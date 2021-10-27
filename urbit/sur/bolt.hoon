::  sur/bolt.hoon
::  Datatypes to implement Lightning BOLT RFCs.
::
/-  bc=bitcoin
|%
+$  id      @ud
+$  blocks  @ud                               ::  number of blocks
+$  msats   @ud                               ::  millisats
+$  commitment-number  @ud
::
+$  pubkey     hexb:bc
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
    ==
  +$  pair  [pub=point prv=@]
  --
::  +tx: modifications to bitcoin tx types, to be merged back later
::
++  tx
  |%
  +$  data
    $:  data:tx:bc
        ws=(list witness)
    ==
  --
::
+$  basepoints
  $:  revocation=point
      payment=point
      delayed-payment=point
      htlc=point
  ==
::
++  channel-config
  $:  =ship
      =basepoints
      =multisig=pubkey
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
      =current-htlc=signature
      per-commitment-secret-seed=hexb:bc
  ==
::
++  remote-config
  $:  channel-config
      =next-per-commitment=point
      =current-per-commitment=point
  ==
::
+$  htlc
  $:  from=ship
      =channel=id
      =id
      amount-msat=msats
      payment-hash=hexb:bc
      cltv-expiry=blocks
      payment-preimage=(unit hexb:bc)
      local-sig=(unit hexb:bc)
      remote-sig=(unit hexb:bc)
  ==
::
++  commitment-keyring
  $:  local-htlc-key=pubkey
      remote-htlc-key=pubkey
      to-local-key=pubkey
      to-remote-key=pubkey
      revocation-key=pubkey
  ==
::
+$  commit-state
  $:
      =commitment-number
      ::  lexicographically ordered
      ::  increasing CLTV order tiebreaker for identical HTLCs
      ::
      offered=(list htlc)
      received=(list htlc)
  ==
::  pending offered HTLC that we're waiting for revoke_and_ack on
::
+$  htlc-pend
  $:  =htlc
      prior-txid=txid:bc
      revocation-pubkey=pubkey
  ==
::
+$  htlc-state
  $:  next-offer=id
      next-receive=id
      offer=(unit htlc-pend)
      receive=(unit htlc-pend)
  ==
::  +chlen: 1 of the 2 members of a channel
::
+$  chlen
  $:  =ship
      =funding=pubkey
      =funding=signature
      =shutdown-script=pubkey
      =basepoints
      per-commitment-point=point
      next-per-commitment-point=point
      =commit-state
  ==
::
::  +larva-chan: a channel in the larval state
::   - holds all the messages back and forth until finalized
::   - used to build chan
+$  larva-chan
  $:  initiator=?
      funding-tx=data:tx:bc
      our=local-config
      her=remote-config
      oc=(unit open-channel:msg)
      ac=(unit accept-channel:msg)
      fc=(unit funding-created:msg)
      fs=(unit funding-signed:msg)
      fl-funder=(unit funding-locked:msg)
      fl-fundee=(unit funding-locked:msg)
  ==
::  chan: channel state
::
+$  chan
  $:  =id
      initiator=?
      our=chlen
      her=chlen
      =funding=outpoint
      =funding=sats:bc
      dust-limit=sats:bc
      max-htlc-value-in-flight=msats
      channel-reserve=sats:bc
      htlc-minimum=msats
      feerate-per-kw=sats:bc
      to-self-delay=blocks
      cltv-expiry-delta=blocks
      max-accepted-htlcs=@ud
      anchor-outputs=?
      revocations=(map txid:bc per-commitment-secret=privkey)
      =htlc-state
  ==
::  msg: BOLT spec messages between peers
::    defined in RFC02
::
++  msg
  |%
  ::  funding messages
  ::
  +$  open-channel
    $:  chain-hash=hexb:bc
        temporary-channel-id=hexb:bc
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
    $:  temporary-channel-id=hexb:bc
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
    $:  temporary-channel-id=hexb:bc
        =funding=outpoint
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
        =id
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
        =id
        per-commitment-secret=hexb:bc
        next-per-commitment-point=point
    ==
  ::
  ::  closing messages
  ::
  +$  shutdown
    $:  =channel=id
        =script=pubkey
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
      [%shutdown shutdown:msg]
      [%closing-signed closing-signed:msg]
      [%update-add-htlc update-add-htlc:msg]
      [%commitment-signed commitment-signed:msg]
      [%revoke-and-ack revoke-and-ack:msg]
      [%update-fulfill-htlc =channel=id =id preimage=hexb:bc]
      [%update-fail-htlc =channel=id =id reason=@t]
      [%update-fail-malformed-htlc =channel=id =id]
      [%update-fee ~]
  ==
--
