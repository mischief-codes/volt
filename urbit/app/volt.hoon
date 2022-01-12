::  volt.hoon
::  Lightning channel management agent
::
/-  *volt, btc-provider
/+  default-agent, dbug
/+  bc=bitcoin, bolt11=bolt-bolt11
/+  psbt, bolt, ring
|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0
  ==
::
+$  provider-state  [host=ship connected=?]
::
+$  state-0
  $:  %0
      keys=(map hexb:bc ship)                         ::  map from pubkey to ship
      pres=(map hexb:bc hexb:bc)                      ::  map from hashes to preimages
      hist=(list payment)                             ::  payment history
      $=  prov                                        ::  provider state
      $:  volt=(unit provider-state)                  ::    volt provider
          info=node-info                              ::    provider lnd info
          btcp=(unit provider-state)                  ::    bitcoin provider
      ==                                              ::
      $=  chan                                        ::  channel state
      $:  larv=(map id:bolt larva-chan:bolt)          ::    larva channels
          fund=(map id:bolt psbt:psbt)                ::    funding transactions
          live=(map id:bolt chan:bolt)                ::    live channels
          peer=(map ship (set id:bolt))               ::    by peer
          wach=(map hexb:bc id:bolt)                  ::    by funding address
      ==                                              ::
      $=  chain                                       ::  blockchain state
      $:  block=@ud                                   ::    current height
          fees=(unit sats:bc)                         ::    feerate
          time=@da                                    ::    timestamp
  ==  ==
--
::
%-  agent:dbug
::
=|  state-0
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def  ~(. (default-agent this %|) bowl)
    hc   ~(. +> bowl)
::
++  on-init
  ^-  (quip card _this)
  ~&  >  '%volt initialized successfully'
  `this(state *state-0)
::
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  ~&  >  '%volt recompiled successfully'
  `this(state !<(versioned-state old-state))
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  =^  cards  state
    ?+    mark  (on-poke:def mark vase)
        %volt-command
      ?>  (team:title our.bowl src.bowl)
      (handle-command:hc !<(command vase))
    ::
        %volt-action
      ?>  (team:title our.bowl src.bowl)
      (handle-action:hc !<(action vase))
    ::
        %volt-message
      ?<  =((clan:title src.bowl) %pawn)
      (handle-message:hc !<(message:bolt vase))
    ==
  [cards this]
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    -.sign  (on-agent:def wire sign)
      %kick
    ?:  ?=(%set-provider -.wire)
      :_  this(volt.prov [~ src.bowl %.n])
      (watch-provider:hc src.bowl)
    ::
    ?:  ?=(%set-btc-provider -.wire)
      :_  this(btcp.prov [~ src.bowl %.n])
      (watch-btc-provider:hc src.bowl)
    ::
    `this
  ::
      %fact
    =^  cards  state
      ?+    p.cage.sign  `state
          %volt-provider-status
        (handle-provider-status:hc !<(status:provider q.cage.sign))
      ::
          %volt-provider-update
        (handle-provider-update:hc !<(update:provider q.cage.sign))
      ::
          %btc-provider-status
        (handle-bitcoin-status:hc !<(status:btc-provider q.cage.sign))
      ::
          %btc-provider-update
        (handle-bitcoin-update:hc !<(update:btc-provider q.cage.sign))
      ==
    [cards this]
  ::
      %watch-ack
    ?:  ?=(%set-provider -.wire)
      ?~  p.sign
        `this
      =/  =tank  leaf+"subscribe to provider {<dap.bowl>} failed"
      %-  (slog tank u.p.sign)
      `this(volt.prov ~)
    ::
    ?:  ?=(%set-btc-provider -.wire)
      ?~  p.sign
        `this
      =/  =tank  leaf+"subscribe to btc provider {<dap.bowl>} failed"
      %-  (slog tank u.p.sign)
      `this(btcp.prov ~)
    ::
    `this
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+    path  (on-watch:def path)
      [%all ~]
    ?>  (team:title our.bowl src.bowl)
    `this
  ==
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  ?=([%task-timer *] wire)
    [monitor-channels this]
  ?:  ?=([%sub-pubkeys ~] wire)
    ?:  ?=([%jael %public-keys ks=*] sign-arvo)
      ?-    +>-.sign-arvo
          %full
        =+  +>+.sign-arvo
        =+  ^=  pubkeys
          ^-  (map hexb:bc ship)
          %-  ~(rep by points)
          |=  [[=ship =point:jael] acc=(map hexb:bc ship)]
          =+  ^=  pubkey
            %-  compress-point:secp256k1:secp:crypto
            %-  get-public-key-from-pass:detail:ring
            pass:(~(got by keys.point) life.point)
          (~(put by acc) 33^pubkey ship)
        `this(keys (~(uni by keys) pubkeys))
      ::  TODO: force close any open channels when pubkeys change ?
      ::
          %diff
        `this
      ::
          %breach
        `this
      ==
    (on-arvo:def wire sign-arvo)
(on-arvo:def wire sign-arvo)
::
++  on-peek   on-peek:def
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
::
++  handle-command
  |=  =command
  |^  ^-  (quip card _state)
  ?-    -.command
      %set-provider
    ?~  provider.command
      ?~  volt.prov  `state
      :_  state(volt.prov ~)
      (leave-provider host.u.volt.prov)
    ::
    :_  state(volt.prov `[u.provider.command %.n])
    ?~  volt.prov  (watch-provider u.provider.command)
    %-  zing
    :~  (leave-provider host.u.volt.prov)
        (watch-provider u.provider.command)
    ==
  ::
      %set-btc-provider
    ?:  =(provider.command btcp.prov)  `state
    ?~  provider.command
      ?~  btcp.prov  `state
      :_  state(btcp.prov ~)
      (leave-btc-provider host.u.btcp.prov)
    ::
    :_  state(btcp.prov `[u.provider.command %.n])
    ?~  btcp.prov  (watch-btc-provider u.provider.command)
    %-  zing
    :~  (leave-btc-provider host.u.btcp.prov)
        (watch-btc-provider u.provider.command)
    ==
  ::
      %update-channels
    =^  cards  state
      %^  spin  ~(val by live.chan)  state
      |=  $:  channel=chan:bolt
              state=_state
          ==
      ^-  (quip card _state)
      =^  cards  channel  (maybe-send-commitment channel)
      :-  cards
      %=  state
        live.chan  (~(put by live.chan) id.channel channel)
      ==
    [(zing cards) state]
  ::
      %open-channel
    (open-channel +.command)
  ::
      %create-funding
    (create-funding +.command)
  ::
      %close-channel
    (close-channel +.command)
  ::
      %send-payment
    (send-payment +.command)
  ::
      %pay-channel
    =+  +.command
    =+  channel=(~(get by live.chan) chan-id)
    ?~  channel
      `state
    (pay-channel u.channel amount-msats payment-hash)
  ==
  ++  open-channel
    |=  [who=ship =funding=sats:bc =push=msats =network:bolt]
    ^-  (quip card _state)
    ?~  btcp.prov  `state
    ?:  (gth funding-sats max-funding-sats:const:bolt)
      ~|  "%volt: must set funding-sats to less than 2^24 sats"
        !!
    ?:  (gth push-msats (sats-to-msats:bolt funding-sats))
      ~|  "%volt: must set push-msats to less than or equal 1000*funding-sats"
        !!
    ?:  (lth funding-sats min-funding-sats:const:bolt)
      ~|  "%volt: funding-sats too low {<funding-sats>} < {<min-funding-sats:const:bolt>}"
        !!
    =+  tmp-id=(make-temp-id)
    =+  feerate=(current-feerate-per-kw)
    =+  ^=  local-config
        ^-  local-config:bolt
        (make-local-config network funding-sats push-msats %.y)
    =+  ^=  first-per-commitment-secret
        ^-  hexb:bc
        %^    generate-from-seed:secret:bolt
            per-commitment-secret-seed.local-config
          first-index:secret:bolt
        ~
    =|  oc=open-channel:msg:bolt
    =.  oc
      %=  oc
        temporary-channel-id            tmp-id
        chain-hash                      (network-chain-hash:bolt network)
        funding-sats                    funding-sats
        push-msats                      push-msats
        funding-pubkey                  pub.multisig-key.local-config
        dust-limit-sats                 dust-limit-sats.local-config
        max-htlc-value-in-flight-msats  max-htlc-value-in-flight-msats.local-config
        channel-reserve-sats            reserve-sats.local-config
        htlc-minimum-msats              htlc-minimum-msats.local-config
        feerate-per-kw                  feerate
        to-self-delay                   to-self-delay.local-config
        max-accepted-htlcs              max-accepted-htlcs.local-config
        pub.revocation.basepoints       pub.revocation.basepoints.local-config
        pub.htlc.basepoints             pub.htlc.basepoints.local-config
        pub.payment.basepoints          pub.payment.basepoints.local-config
        pub.delayed-payment.basepoints  pub.delayed-payment.basepoints.local-config
        anchor-outputs                  anchor-outputs.local-config
        first-per-commitment-point      %-  compute-commitment-point:secret:bolt
                                             first-per-commitment-secret
        shutdown-script-pubkey          upfront-shutdown-script.local-config
      ==
    =|  lar=larva-chan:bolt
    =.  lar
      %=  lar
        initiator   %.y
        ship.her    who
        our         local-config
        oc          `oc
      ==
    :_  state(larv.chan (~(put by larv.chan) tmp-id lar))
    :~  (send-message [%open-channel oc] who)
        (watch-pubkey who)
    ==
  ::
  ++  create-funding
    |=  [temporary-channel-id=@ psbt=@t]
    ^-  (quip card _state)
    =/  c=(unit larva-chan:bolt)
      (~(get by larv.chan) temporary-channel-id)
    ?~  c
      ~&  >>>  "%volt: no channel with id: {<temporary-channel-id>}"
      `state
    ?~  oc.u.c
      ~&  >>>  "%volt: invalid channel state: {<temporary-channel-id>}"
      `state
    ?~  ac.u.c
      ~&  >>>  "%volt: invalid channel state: {<temporary-channel-id>}"
      `state
    ~|  %invalid-funding-tx
    =+  ^=  funding-tx
        ^-  (unit psbt:^psbt)
        (from-base64:create:^psbt psbt)
    ?>  ?=(^ funding-tx)
    ::  TODO: check tx is complete
    ::
    =+  ^=  funding-output
        ^-  output:^psbt
        %^    funding-output:tx:bolt
            pub.multisig-key.our.u.c
          pub.multisig-key.her.u.c
        funding-sats.u.oc.u.c
    ::
    =+  ^=  funding-out-pos
        ^-  (unit @u)
        =+  outs=vout.u.funding-tx
        =+  i=0
        |-
        ?~  outs  ~
        =+  out=(head outs)
        ?:  ?&  =(value.out value.funding-output)
                =(script-pubkey.out script-pubkey.funding-output)
            ==
          (some i)
        $(outs (tail outs), i +(i))
    ?>  ?=(^ funding-out-pos)
    ::
    =+  funding-txid=(txid:^psbt (extract-unsigned:^psbt u.funding-tx))
    %-  (slog leaf+"funding-txid={<funding-txid>}" ~)
    ::
    =+  ^=  channel-id
        ^-  id:bolt
        %+  make-channel-id:bolt
          funding-txid
        u.funding-out-pos
    ::
    =+  ^=  channel
        ^-  chan:bolt
        %:  new:channel:bolt
          id=channel-id
          local-channel-config=our.u.c
          remote-channel-config=her.u.c
          funding-outpoint=[funding-txid u.funding-out-pos funding-sats.u.oc.u.c]
          initial-feerate=feerate-per-kw.u.oc.u.c
          initiator=initiator.u.c
          anchor-outputs=anchor-outputs.our.u.c
          capacity=funding-sats.u.oc.u.c
          funding-tx-min-depth=minimum-depth.u.ac.u.c
        ==
    =^  [sig=signature:bolt htlc-sigs=(list signature:bolt)]  channel
      ~(sign-next-commitment channel:bolt channel)
    ::
    =|  =funding-created:msg:bolt
    =.  funding-created
      %=  funding-created
        temporary-channel-id  temporary-channel-id
        funding-txid          funding-txid
        funding-idx           u.funding-out-pos
        signature             sig
      ==
    :_  %=  state
          larv.chan  (~(del by larv.chan) temporary-channel-id)
          live.chan  (~(put by live.chan) channel-id channel)
          fund.chan  (~(put by fund.chan) channel-id u.funding-tx)
        ==
    ~[(send-message [%funding-created funding-created] ship.her.u.c)]
  ::
  ++  close-channel
    |=  =chan-id
    ^-  (quip card _state)
    =+  channel=(~(get by live.chan) chan-id)
    ?~  channel  `state
    =^  cards  u.channel  (send-shutdown u.channel)
    :-  cards
    state(live.chan (~(put by live.chan) chan-id u.channel))
  ::
  ++  send-shutdown
    |=  channel=chan:bolt
    ^-  (quip card _channel)
    ?>  (can-send-shutdown channel)
    :_  channel
    ~[(send-message [%shutdown id.channel 0^0x0] ship.her.config.channel)]
  ::
  ++  can-send-shutdown
    |=  channel=chan:bolt
    ^-  ?
    ?:  (~(has-pending-changes channel:bolt channel) %remote)
      ::  if there are updates pending on the receiving node's commitment transaction:
      ::    MUST NOT send a shutdown.
      %.n
    %.y
  ::
  ++  send-payment
    |=  payreq=@t
    ^-  (quip card _state)
    ?~  btcp.prov  `state
    =+  invoice=(de:bolt11 payreq)
    ?~  invoice
      ~&  >>>  "%volt: invalid payreq"
      `state
    ?~  amount.u.invoice
      ~&  >>>  "%volt: payreq didn't specify amount"
      `state
    =+  amount-msats=(amount-to-msats:bolt11 u.amount.u.invoice)
    ?:  =(0 amount-msats)
      ~&  >>>  "%volt: payreq amount is below 1 msat"
      `state
    =/  who=(unit @p)
      (~(get by keys) pubkey.u.invoice)
    ?~  who
      ::  unrecognized payee pubkey, try asking provider
      ::
      (forward-invoice-to-provider u.invoice amount-msats)
    =+  chan-ids=(~(get by peer.chan) u.who)
    ?~  chan-ids
      ::  no direct channel, try asking provider
      ::
      (forward-invoice-to-provider u.invoice amount-msats)
    =+  channel=(find-channel-with-capacity u.chan-ids amount-msats)
    ?~  channel
      ::  no bilateral capacity, try asking provider
      ::
      (forward-invoice-to-provider u.invoice amount-msats)
    (pay-channel u.channel amount-msats payment-hash.u.invoice)
  ::
  ++  find-channel-with-capacity
    |=  [ids=(set id:bolt) =amount=msats]
    ^-  (unit chan:bolt)
    %+  roll  ~(tap in ids)
    |=  [=id:bolt acc=(unit chan:bolt)]
    =+  channel=(~(get by live.chan) id)
    ?~  channel  acc
    ?:  (~(can-pay channel:bolt u.channel) amount-msats)
      `u.channel
    acc
  ::
  ++  forward-invoice-to-provider
    |=  [=invoice:bolt11 =amount=msats]
    ^-  (quip card _state)
    ?~  volt.prov
      ~&  >>>  "%volt: no provider configured"
      `state
    =+  provider-channels=(~(get by peer.chan) host.u.volt.prov)
    ?~  provider-channels
      ~&  >>>  "%volt: no channel with provider"
      `state
    =+  channel=(find-channel-with-capacity u.provider-channels amount-msats)
    ?~  channel
      ~&  >>>  "%volt: insufficient capacity with provider"
      `state
    ~|(%unimplemented !!)
  ::
  ++  pay-channel
    |=  [channel=chan:bolt =amount=msats payment-hash=hexb:bc]
    ^-  (quip card _state)
    =+  final-cltv=(add block.chain min-final-cltv-expiry:const:bolt)
    =^  htlc  channel
      %^    ~(add-next-htlc channel:bolt channel)
          amount-msats
        payment-hash
      final-cltv
    :_  state(live.chan (~(put by live.chan) id.channel channel))
    ~[(send-message [%update-add-htlc htlc] ship.her.config.channel)]
  --
::
++  handle-message
  |=  =message:bolt
  |^  ^-  (quip card _state)
  =^  cards  state
    ?-    -.message
    ::
    ::::  +-------+                              +-------+
      ::  |       |--(1)---  open_channel  ----->|       |
      ::  |       |<-(2)--  accept_channel  -----|       |
      ::  |       |                              |       |
      ::  |   A   |--(3)--  funding_created  --->|   B   |
      ::  |       |<-(4)--  funding_signed  -----|       |
      ::  |       |                              |       |
      ::  |       |--(5)--- funding_locked  ---->|       |
      ::  |       |<-(6)--- funding_locked  -----|       |
    ::::  +-------+                              +-------+
    ::
        %open-channel
      (handle-open-channel +.message)
    ::
        %accept-channel
      (handle-accept-channel +.message)
    ::
        %funding-created
      (handle-funding-created +.message)
    ::
        %funding-signed
      (handle-funding-signed +.message)
    ::
        %funding-locked
      (handle-funding-locked +.message)
    ::
    ::::  +-------+                               +-------+
      ::  |       |--(1)---- update_add_htlc ---->|       |
      ::  |       |--(2)---- update_add_htlc ---->|       |
      ::  |       |<-(3)---- update_add_htlc -----|       |
      ::  |       |                               |       |
      ::  |       |--(4)--- commitment_signed --->|       |
      ::  |   A   |<-(5)---- revoke_and_ack ------|   B   |
      ::  |       |                               |       |
      ::  |       |<-(6)--- commitment_signed ----|       |
      ::  |       |--(7)---- revoke_and_ack ----->|       |
      ::  |       |                               |       |
      ::  |       |--(8)--- commitment_signed --->|       |
      ::  |       |<-(9)---- revoke_and_ack ------|       |
    ::::  +-------+                               +-------+
    ::
        %update-add-htlc
      (handle-update-add-htlc +.message)
    ::
        %commitment-signed
      (handle-commitment-signed +.message)
    ::
        %revoke-and-ack
      (handle-revoke-and-ack +.message)
    ::
    ::::  +-------+                              +-------+
      ::  |       |--(1)-----  shutdown  ------->|       |
      ::  |       |<-(2)-----  shutdown  --------|       |
      ::  |       |                              |       |
      ::  |       | <complete all pending HTLCs> |       |
      ::  |   A   |                 ...          |   B   |
      ::  |       |                              |       |
      ::  |       |--(3)-- closing_signed  F1--->|       |
      ::  |       |<-(4)-- closing_signed  F2----|       |
      ::  |       |              ...             |       |
      ::  |       |--(?)-- closing_signed  Fn--->|       |
      ::  |       |<-(?)-- closing_signed  Fn----|       |
    ::::  +-------+                              +-------+
    ::
        %shutdown
      (handle-shutdown +.message)
    ::
        %closing-signed
      (handle-closing-signed +.message)
    ::
        %update-fulfill-htlc
      (handle-update-fulfill-htlc +.message)
    ::
        %update-fail-htlc
      (handle-update-fail-htlc +.message)
    ::
        %update-fail-malformed-htlc
      (handle-update-fail-malformed-htlc +.message)
    ::
        %update-fee
      (handle-update-fee +.message)
    ==
  [cards state]
  ::
  ++  handle-open-channel
    |=  =open-channel:msg:bolt
    ^-  (quip card _state)
    =+  open-channel
    ?:  (gth funding-sats max-funding-sats:const:bolt)
      ~|  "%volt: must set funding-sats to less than 2^24 sats"
        !!
    ?:  (gth push-msats (sats-to-msats:bolt funding-sats))
      ~|  "%volt: must set push-msats to less than or equal 1000*funding-sats"
        !!
    ?:  (lth funding-sats min-funding-sats:const:bolt)
      ~|  "%volt: funding-sats too low {<funding-sats>} < {<min-funding-sats:const:bolt>}"
        !!
    ::
    =+  network=(chain-hash-network:bolt chain-hash)
    ::
    =+  ^=  local-config
        ^-  local-config:bolt
        (make-local-config network funding-sats push-msats %.n)
    ::
    =|  =remote-config:bolt
    =.  remote-config
      %=  remote-config
        network                         network
        pub.multisig-key                funding-pubkey
        basepoints                      basepoints
        to-self-delay                   to-self-delay
        dust-limit-sats                 dust-limit-sats
        max-htlc-value-in-flight-msats  max-htlc-value-in-flight-msats
        max-accepted-htlcs              max-accepted-htlcs
        initial-msats                   %+  sub
                                          (sats-to-msats:bolt funding-sats)
                                        push-msats
        reserve-sats                    channel-reserve-sats
        htlc-minimum-msats              htlc-minimum-msats
        next-per-commitment-point       first-per-commitment-point
        upfront-shutdown-script         shutdown-script-pubkey
      ==
    ::
    ~|  %incompatible-channel-configurations
    ?>  (validate-config -.remote-config funding-sats)
    ::  The receiving node MUST fail the channel if:
    ::      the funder's amount for the initial commitment transaction is not
    ::      sufficient for full fee payment.
    ::
    =+  ^=  commit-fees
        %.  %remote
        %~  got  by
        %:  commitment-fee:bolt
          num-htlcs=0
          feerate=feerate-per-kw
          is-local-initiator=%.n
          anchors=%.y
          round=%.n
        ==
    ?:  (lth initial-msats.remote-config commit-fees)
      ~|("%volt: funder's amount is insufficient for full fee payment" !!)
    ::  The receiving node MUST fail the channel if:
    ::      both to_local and to_remote amounts for the initial commitment transaction are
    ::      less than or equal to channel_reserve_satoshis (see BOLT 3).
    ::
    =+  reserve-msats=(sats-to-msats:bolt channel-reserve-sats)
    ?:  ?&  (lte initial-msats.local-config reserve-msats)
            (lte initial-msats.remote-config reserve-msats)
        ==
      ~|  "%volt: both to-local and to-remote amounts are less than channel-reserve-sats"
        !!
    ::
    =+  ^=  first-per-commitment-secret
        ^-  hexb:bc
        %^    generate-from-seed:secret:bolt
            per-commitment-secret-seed.local-config
          first-index:secret:bolt
        ~
    ::
    =|  =accept-channel:msg:bolt
    =.  accept-channel
      %=  accept-channel
        temporary-channel-id            temporary-channel-id
        dust-limit-sats                 dust-limit-sats.local-config
        max-htlc-value-in-flight-msats  max-htlc-value-in-flight-msats.local-config
        channel-reserve-sats            reserve-sats.local-config
        htlc-minimum-msats              htlc-minimum-msats.local-config
        minimum-depth                   3
        to-self-delay                   to-self-delay.local-config
        max-accepted-htlcs              max-accepted-htlcs.local-config
        funding-pubkey                  pub.multisig-key.local-config
        pub.revocation.basepoints       pub.revocation.basepoints.local-config
        pub.htlc.basepoints             pub.htlc.basepoints.local-config
        pub.payment.basepoints          pub.payment.basepoints.local-config
        pub.delayed-payment.basepoints  pub.delayed-payment.basepoints.local-config
        basepoints                      basepoints.local-config
        shutdown-script-pubkey          upfront-shutdown-script.local-config
        anchor-outputs                  anchor-outputs.local-config
        first-per-commitment-point      %-  compute-commitment-point:secret:bolt
                                          first-per-commitment-secret
      ==
    ::
    =|  lar=larva-chan:bolt
    =.  lar
      %=  lar
        initiator  %.n
        our        local-config
        her        remote-config
        oc         `open-channel
        ac         `accept-channel
      ==
    ::
    :_  %=  state
          larv.chan  (~(put by larv.chan) temporary-channel-id lar)
        ==
    :~  (send-message [%accept-channel accept-channel] src.bowl)
        (watch-pubkey src.bowl)
    ==
  ::
  ++  handle-accept-channel
    |=  msg=accept-channel:msg:bolt
    ^-  (quip card _state)
    =/  c=(unit larva-chan:bolt)
      (~(get by larv.chan) temporary-channel-id.msg)
    ?~  c
      ~&  >>>  "%volt: %accept-channel for non-existent channel: {<temporary-channel-id.msg>}"
      `state
    ?~  oc.u.c
      ~&  >>>  "%volt: %accept-channel without %open-channel: {<temporary-channel-id.msg>}"
      `state
    ?>  =(ship.her.u.c src.bowl)
    ::
    ?.  initiator.u.c
      ~|  "%volt: initiator sent accept channel"
        !!
    ?:  (lte minimum-depth.msg 0)
      ~|  "%volt: minimum depth too low: {<minimum-depth.msg>}"
        !!
    ?:  (gth minimum-depth.msg 30)
      ~|  "%volt: minimum depth too high: {<minimum-depth.msg>}"
        !!
    ::
    =|  =remote-config:bolt
    =.  remote-config
      %=  remote-config
        ship                            ship.her.u.c
        basepoints                      basepoints.msg
        pub.multisig-key                funding-pubkey.msg
        to-self-delay                   to-self-delay.msg
        dust-limit-sats                 dust-limit-sats.msg
        max-htlc-value-in-flight-msats  max-htlc-value-in-flight-msats.msg
        max-accepted-htlcs              max-accepted-htlcs.msg
        initial-msats                   push-msats.u.oc.u.c
        reserve-sats                    channel-reserve-sats.msg
        htlc-minimum-msats              htlc-minimum-msats.msg
        next-per-commitment-point       first-per-commitment-point.msg
        upfront-shutdown-script         shutdown-script-pubkey.msg
        anchor-outputs                  anchor-outputs.msg
      ==
    ::
    ~|  %incompatible-channel-configurations
    ?>  (validate-config -.remote-config funding-sats.u.oc.u.c)
    ::  if channel_reserve_satoshis is less than dust_limit_satoshis, MUST reject the channel
    ::
    ?:  (lth reserve-sats.remote-config dust-limit-sats.our.u.c)
      ~|  "%volt: reserve-sats.remote-config < dust-limit-sats.local-config"
        !!
    ::  if channel_reserve_satoshis is less than dust_limit_satoshis, MUST reject the channel
    ::
    ?:  (lth reserve-sats.our.u.c dust-limit-sats.remote-config)
      ~|  "%volt: reserve-sats.local-config < dust-limit-sats.remote-config"
        !!
    ::
    =+  ^=  funding-address
        ^-  address:bc
        %^    make-funding-address:bolt
            network.our.u.c
          pub.multisig-key.our.u.c
        funding-pubkey.msg
    ::
    %-  (slog leaf+"chan-id={<temporary-channel-id.msg>}" ~)
    %-  (slog leaf+"funding-address={<funding-address>}" ~)
    ::
    :_  %=    state
            larv.chan
        %+  ~(put by larv.chan)  temporary-channel-id.msg
        %=  u.c
          her         remote-config
          ac          `msg
        ==  ==
    ~[(give-update [%need-funding-signature temporary-channel-id.msg funding-address])]
  ::
  ++  handle-funding-created
    |=  msg=funding-created:msg:bolt
    ^-  (quip card _state)
    =/  c=(unit larva-chan:bolt)
      %-  ~(get by larv.chan)
        temporary-channel-id.msg
    ?~  c
      ~&  >>>  "%volt: %funding-created for non-existent channel: {<temporary-channel-id.msg>}"
      `state
    ?~  oc.u.c
      ~&  >>>  "%volt: %funding-created without %open-channel: {<temporary-channel-id.msg>}"
      `state
    ?~  ac.u.c
      ~&  >>>  "%volt: %funding-created without %accept-channel: {<temporary-channel-id.msg>}"
      `state
    ?>  =(ship.her.u.c src.bowl)
    ::
    =+  ^=  channel-id
        ^-  id:bolt
        %+  make-channel-id:bolt
          funding-txid.msg
        funding-idx.msg
    ::
    =+  ^=  funding-output
        ^-  output:psbt
        %^    funding-output:tx:bolt
            pub.multisig-key.our.u.c
          pub.multisig-key.her.u.c
        funding-sats.u.oc.u.c
    ::
    =+  ^=  channel
        ^-  chan:bolt
        %:  new:channel:bolt
          id=channel-id
          local-channel-config=our.u.c
          remote-channel-config=her.u.c
          funding-outpoint=[funding-txid.msg funding-idx.msg funding-sats.u.oc.u.c]
          initial-feerate=feerate-per-kw.u.oc.u.c
          initiator=initiator.u.c
          anchor-outputs=anchor-outputs.our.u.c
          capacity=funding-sats.u.oc.u.c
          funding-tx-min-depth=minimum-depth.u.ac.u.c
        ==
    ::
    =.  channel
      (~(receive-new-commitment channel:bolt channel) signature.msg ~)
    =^  sigs  channel
      ~(sign-next-commitment channel:bolt channel)
    =/  [sig=signature:bolt htlc-sigs=(list signature:bolt)]
      sigs
    =.  channel
      %+  ~(open-with-first-commitment-point channel:bolt channel)
        first-per-commitment-point.u.oc.u.c
      signature.msg
    =.  channel
      (~(set-state channel:bolt channel) %opening)
    ::
    :_  %=  state
          larv.chan  (~(del by larv.chan) temporary-channel-id.msg)
          live.chan  (~(put by live.chan) channel-id channel)
          peer.chan  (~(put by peer.chan) src.bowl channel-id)
          wach.chan  %+  ~(put by wach.chan)
                       script-pubkey.funding-output
                     channel-id
        ==
    ~[(send-message [%funding-signed channel-id sig] src.bowl)]
  ::
  ++  handle-funding-signed
    |=  msg=funding-signed:msg:bolt
    ^-  (quip card _state)
    =+  remote-sig=signature.msg
    ?.  (~(has by live.chan) channel-id.msg)
      ~&  >>>  "%volt: no channel with id: {<channel-id.msg>}"
      `state
    ?.  (~(has by fund.chan) channel-id.msg)
      ~&  >>>  "%volt: no funding tx with id: {<channel-id.msg>}"
      `state
    ::
    =+  channel=(~(got by live.chan) channel-id.msg)
    ?>  =(ship.her.config.channel src.bowl)
    =+  funding-tx=(~(got by fund.chan) channel-id.msg)
    =+  ^=  funding-output
        ^-  output:psbt
        %^    funding-output:tx:bolt
            pub.multisig-key.our.config.channel
          pub.multisig-key.her.config.channel
        sats.funding-outpoint.channel
    ::
    =.  channel
      %+  ~(receive-new-commitment channel:bolt channel)
        remote-sig
      ~
    =.  channel
      %+  ~(open-with-first-commitment-point channel:bolt channel)
        next-per-commitment-point.her.config.channel
      remote-sig
    =.  channel
      (~(set-state channel:bolt channel) %opening)
    ::
    :_  %=  state
          live.chan  (~(put by live.chan) channel-id.msg channel)
          peer.chan  (~(put by peer.chan) src.bowl channel-id.msg)
          fund.chan  (~(del by fund.chan) channel-id.msg)
          wach.chan  %+  ~(put by wach.chan)
                       script-pubkey.funding-output
                     channel-id.msg
        ==
    =-  ~[(poke-btc-provider [%broadcast-tx -])]
    %-  encode-tx:psbt
      (extract-unsigned:psbt funding-tx)
  ::
  ++  handle-funding-locked
    |=  msg=funding-locked:msg:bolt
    ^-  (quip card _state)
    =+  channel=(~(get by live.chan) channel-id.msg)
    ?~  channel  `state
    ?:  funding-locked-received.our.config.u.channel
      `state
    =.  config.u.channel
      %=    config.u.channel
          our
        our.config.u.channel(funding-locked-received %.y)
      ::
          her
        %=  her.config.u.channel
          next-per-commitment-point  next-per-commitment-point.msg
        ==
      ==
    =?  u.channel  ~(is-funded channel:bolt u.channel)
      (mark-open u.channel)
    `state(live.chan (~(put by live.chan) id.u.channel u.channel))
  ::
  ++  handle-update-add-htlc
    |=  msg=update-add-htlc:msg:bolt
    ^-  (quip card _state)
    ?>  (~(has by live.chan) channel-id.msg)
    =+  c=(~(got by live.chan) channel-id.msg)
    ?>  =(ship.her.config.c src.bowl)
    ?.  =(state.c %open)
      ~|(%invalid-state !!)
    =^  htlc  c  (~(receive-htlc channel:bolt c) msg)
    :-  ~
    state(live.chan (~(put by live.chan) channel-id.msg c))
  ::
  ++  handle-commitment-signed
    |=  msg=commitment-signed:msg:bolt
    ^-  (quip card _state)
    ?>  (~(has by live.chan) channel-id.msg)
    =+  c=(~(got by live.chan) channel-id.msg)
    =+  msg
    ?>  =(ship.her.config.c src.bowl)
    ?.  (~(has-pending-changes channel:bolt c) %local)
      ~|(%invalid-state !!)
    ?:  (~(is-revack-pending htlcs:bolt c) %local)
      ~|(%invalid-state !!)
    =^  cards  c
      %-  send-revoke-and-ack
      %+  ~(receive-new-commitment channel:bolt c)
        sig
      htlc-sigs
    :-  cards
    state(live.chan (~(put by live.chan) id.c c))
  ::
  ++  handle-revoke-and-ack
    |=  msg=revoke-and-ack:msg:bolt
    ^-  (quip card _state)
    ?>  (~(has by live.chan) channel-id.msg)
    =+  c=(~(got by live.chan) channel-id.msg)
    ?>  =(ship.her.config.c src.bowl)
    =^  cards  c
      %-  maybe-send-commitment
      %.  msg
      ~(receive-revocation channel:bolt c)
    :-  cards
    state(live.chan (~(put by live.chan) id.c c))
  ::
  ++  handle-shutdown
    |=  =shutdown:msg:bolt
    ^-  (quip card _state)
    =+  shutdown
    `state
  ::
  ++  handle-closing-signed
    |=  =closing-signed:msg:bolt
    ^-  (quip card _state)
    =+  closing-signed
    `state
  ::
  ++  handle-update-fulfill-htlc
    |=  [=channel=id:bolt =htlc-id:bolt preimage=hexb:bc]
    ^-  (quip card _state)
    ?>  (~(has by live.chan) channel-id)
    =+  channel=(~(got by live.chan) channel-id)
    ?>  =(ship.her.config.channel src.bowl)
    =+  payment-hash=(sha256:bcu:bc preimage)
    =.  channel
      %+  ~(receive-htlc-settle channel:bolt channel)
        preimage
      htlc-id
    =^  cards  channel
      (maybe-send-commitment channel)
    :-  cards
    %=  state
      live.chan  (~(put by live.chan) id.channel channel)
      pres       (~(put by pres) payment-hash preimage)
    ==
  ::
  ++  handle-update-fail-htlc
    |=  [=channel=id:bolt =htlc-id:bolt reason=@t]
    ^-  (quip card _state)
    ?>  (~(has by live.chan) channel-id)
    =+  channel=(~(got by live.chan) channel-id)
    ?>  =(ship.her.config.channel src.bowl)
    =.  channel
      %-  ~(receive-fail-htlc channel:bolt channel)
        htlc-id
    =^  cards  channel
      (maybe-send-commitment channel)
    ~&  >>>  "{<id.channel>} failed HTLC: {<reason>}"
    [cards state(live.chan (~(put by live.chan) id.channel channel))]
  ::
  ++  handle-update-fail-malformed-htlc
    |=  [=channel=id:bolt =htlc-id:bolt]
    ^-  (quip card _state)
    ?>  (~(has by live.chan) channel-id)
    =+  channel=(~(got by live.chan) channel-id)
    ?>  =(ship.her.config.channel src.bowl)
    =.  channel
      %-  ~(receive-fail-htlc channel:bolt channel)
        htlc-id
    =^  cards  channel
      (maybe-send-commitment channel)
    ~&  >>>  "{<id.channel>} failed HTLC: (malformed)"
    [cards state(live.chan (~(put by live.chan) id.channel channel))]
  ::
  ++  handle-update-fee
    |=  [=channel=id:bolt feerate-per-kw=sats:bc]
    ^-  (quip card _state)
    ?>  (~(has by live.chan) channel-id)
    =+  channel=(~(got by live.chan) channel-id)
    ?>  =(ship.her.config.channel src.bowl)
    =.  channel
      %+  ~(update-fee channel:bolt channel)
        feerate-per-kw
      %.n
    `state(live.chan (~(put by live.chan) id.channel channel))
  ::
  ++  send-revoke-and-ack
    |=  c=chan:bolt
    ^-  (quip card chan:bolt)
    =^  rev    c  ~(revoke-current-commitment channel:bolt c)
    =^  cards  c  (maybe-send-commitment c)
    :_  c
    :_  cards
    (send-message [%revoke-and-ack rev] src.bowl)
  --
::
++  maybe-send-commitment
  |=  c=chan:bolt
  ^-  (quip card chan:bolt)
  ?:  (~(is-revack-pending htlcs:bolt c) %remote)      `c
  ?.  (~(has-pending-changes channel:bolt c) %remote)  `c
  =^  sigs  c
    ~(sign-next-commitment channel:bolt c)
  =/  [sig=signature:bolt htlc-sigs=(list signature:bolt)]
    sigs
  =+  n-htlc-sigs=(lent htlc-sigs)
  :_  c
  =-  ~[(send-message - ship.her.config.c)]
  :*  %commitment-signed
      id.c         sig
      n-htlc-sigs  htlc-sigs
  ==
::
++  handle-action
  |=  =action
  ^-  (quip card _state)
  `state
::
++  handle-provider-status
  |=  =status:provider
  ^-  (quip card _state)
  `state
::
++  handle-provider-update
  |=  =update:provider
  |^  ^-  (quip card _state)
  ?:  ?=([%| *] update)
    (provider-error +.update)
  (provider-result +.update)
  ::
  ++  provider-error
    |=  =error:provider
    ^-  (quip card _state)
    `state
  ::
  ++  provider-result
    |=  =result:provider
    ^-  (quip card _state)
    `state
  --
::
++  handle-bitcoin-status
  |=  =status:btc-provider
  ^-  (quip card _state)
  ?~  btcp.prov  `state
  ?.  =(host.u.btcp.prov src.bowl)  `state
  ?-    -.status
      %new-block
    :_  %=  state
          btcp.prov  `u.btcp.prov(connected %.y)
          chain      [block.status fee.status now.bowl]
        ==
    %+  turn  ~(val by wach.chan)
    |=  =id:bolt
    =+  channel=(~(got by live.chan) id)
    %-  poke-btc-provider
    [%address-info ~(funding-address channel:bolt channel)]
  ::
      %connected
    :-  ~
    %=  state
      btcp.prov  `u.btcp.prov(connected %.y)
      chain      [block.status fee.status now.bowl]
    ==
  ::
      %disconnected
    `state(btcp.prov `u.btcp.prov(connected %.n))
  ==
::
++  handle-bitcoin-update
  |=  =update:btc-provider
  |^  ^-  (quip card _state)
  ?~  btcp.prov  `state
  ?.  =(host.u.btcp.prov src.bowl)  `state
  ?.  ?=([%& *] update)  `state
  ?-    -.p.update
      %address-info
    (handle-address-info +.p.update)
  ::
      %tx-info
    `state
  ::
      %raw-tx
    `state
  ::
      %broadcast-tx
    ::  apparently this can fail
    ~&  >>  p.update
    `state
  ::
      %block-info
    `state
  ==
  ++  handle-address-info
    |=  $:  =address:bc
            utxos=(set utxo:bc)
            used=?
            block=@ud
        ==
    ^-  (quip card _state)
    ?.  ?=([%bech32 *] address)  `state
    =+  ^=  script-pubkey
        %-  cat:byt:bcu:bc
        :~  1^0
            1^0x20
            (bech32-decode:bolt +.address)
        ==
    =+  id=(~(get by wach.chan) script-pubkey)
    ?~  id  `state
    =+  channel=(~(got by live.chan) u.id)
    =/  utxo=(unit utxo:bc)
      %-  ~(rep in utxos)
      |=  [output=utxo:bc acc=(unit utxo:bc)]
      ?:  ?&  =(txid.output txid.funding-outpoint.channel)
              =(pos.output pos.funding-outpoint.channel)
              =(value.output sats.funding-outpoint.channel)
          ==
        `output
      acc
    ::
    ?:  ?=(^ utxo)
      =/  channel=chan:bolt
        %+  ~(update-onchain-state channel:bolt channel)
          u.utxo
        block
      =^  cards  channel
        (on-channel-update channel u.utxo block)
      [cards state(live.chan (~(put by live.chan) u.id channel))]
    ::
    ?:  ~(is-funded channel:bolt channel)
      ::  funded + no utxo -> spent
      ::
      ~&  >>>  "funding-tx spent"
      ::  find spender tx and then ask:
      ::  - is it a cooperative close?
      ::  - is it a force close?
      ::  - is it a revoked commitment?
      `state
    `state
  ::
  ++  on-channel-update
    |=  [channel=chan:bolt =utxo:bc block=@ud]
    ^-  (quip card _channel)
    ?:  ?&  =(state.channel %open)
            (~(has-expiring-htlcs channel:bolt channel) block)
        ==
      ::  (force-close channel)
      `channel
    ?:  =(state.channel %funded)
      (send-funding-locked channel)
    ?:  =(state.channel %open)
      `channel
    ?:  =(state.channel %force-closing)
      `channel
    `channel
  --
::
++  remove-channel
  |=  =id:bolt
  ^-  (quip card _state)
  =+  channel=(~(get by live.chan) id)
  ?~  channel  `state
  =+  ship=ship.her.config.u.channel
  =+  peer-ids=(~(gut by peer.chan) ship ~)
  =.  peer-ids  (~(del in peer-ids) id)
  :-  ?~  peer-ids  ~[(unwatch-pubkey ship)]  ~
  %=    state
      live.chan
    (~(del by live.chan) id)
  ::
      wach.chan
    (~(del by wach.chan) ~(funding-address channel:bolt u.channel))
  ::
      peer.chan
    ?~  peer-ids
      (~(del by peer.chan) ship)
    (~(put by peer.chan) ship peer-ids)
  ::  remove pubkey if no channels left
  ::
      keys
    ?^  peer-ids  keys
    =+  pubkey=(get-peer-pubkey ship)
    ?~  pubkey  keys
    (~(del by keys) u.pubkey)
  ==
::
++  get-peer-pubkey
  |=  who=@p
  ^-  (unit pubkey:bolt)
  =/  peer-life=(unit @ud)
    .^((unit @ud) %j /=lyfe=/(scot %p who))
  ?~  peer-life  ~
  =/  peer-deed=[life pass (unit @ux)]
    .^([life pass (unit @ux)] %j /=deed=/(scot %p who)/(scot %d u.peer-life))
  %-  some
  (get-public-key-from-pass:detail:ring +<.peer-deed)
::
++  send-funding-locked
  |=  channel=chan:bolt
  ^-  (quip card chan:bolt)
  =+  who=ship.her.config.channel
  =+  idx=(dec start-index:revocation:bolt)
  =+  ^=  next-per-commitment-point
      %-  compute-commitment-point:secret:bolt
      %^    generate-from-seed:secret:bolt
          per-commitment-secret-seed.our.config.channel
        idx
      ~
  =?    channel
      ?&  ~(is-funded channel:bolt channel)
          funding-locked-received.our.config.channel
      ==
   (mark-open channel)
  :_  channel
  =-  ~[(send-message - who)]
  [%funding-locked id.channel next-per-commitment-point]
::
++  mark-open
  |=  c=chan:bolt
  ^-  chan:bolt
  ?>  ~(is-funded channel:bolt c)
  =+  old-state=state.c
  ?:  =(old-state %open)    c
  ?.  =(old-state %funded)  c
  ?>  funding-locked-received.our.config.c
  (~(set-state channel:bolt c) %open)
::
++  make-temp-id
  |.
  ^-  id:bolt
  (~(rad og eny.bowl) (bex 256))
::
++  generate-basepoints
  |=  [seed=hexb:bc =network:bolt]
  ^-  basepoints:bolt
  =|  =basepoints:bolt
  %=  basepoints
    htlc             (generate-keypair:bolt seed network %htlc-base)
    payment          (generate-keypair:bolt seed network %payment-base)
    delayed-payment  (generate-keypair:bolt seed network %delay-base)
    revocation       (generate-keypair:bolt seed network %revocation-base)
  ==
::  TODO: estimate fee based on network state, target ETA, desired confs
::
++  current-feerate-per-kw
  |.
  ^-  sats:bc
  %+  max
    feerate-per-kw-min-relay:const:bolt
  (div feerate-fallback:const:bolt 4)
::
++  validate-config
  |=  [config=channel-config:bolt =funding=sats:bc]
  ^-  ?
  ?&  ?!  (lth funding-sats min-funding-sats:const:bolt)
      ?!  (gth funding-sats max-funding-sats:const:bolt)
      ?&  (lte 0 initial-msats.config)
          (lte initial-msats.config (sats-to-msats:bolt funding-sats))
      ==
      ?!  (lth reserve-sats.config dust-limit-sats.config)
  ==
::
++  make-local-config
  |=  [=network:bolt =funding=sats:bc =push=msats initiator=?]
  ^-  local-config:bolt
  ::  TODO: really need cryptographic random
  ::
  =+  ^=  seed
      ^-  hexb:bc
      32^(~(rad og eny.bowl) (bex 256))
  ::
  =|  =local-config:bolt
  =.  local-config
    %=    local-config
        ship                     our.bowl
        network                  network
        seed                     seed
        to-self-delay            (mul 7 144)
        dust-limit-sats          dust-limit-sats:const:bolt
        max-accepted-htlcs       30
        funding-locked-received  %.n
        htlc-minimum-msats       1
        anchor-outputs           %.y
        multisig-key             (generate-keypair:bolt seed network %multisig)
        basepoints               (generate-basepoints seed network)
    ::
        max-htlc-value-in-flight-msats
      (sats-to-msats:bolt funding-sats)
    ::
        initial-msats
      ?:  initiator
        %+  sub
          %-  sats-to-msats:bolt  funding-sats
        push-msats
      push-msats
    ::
        reserve-sats
      %+  max
        (div funding-sats 100)
      dust-limit-sats:const:bolt
    ::
        per-commitment-secret-seed
      32^prv:(generate-keypair:bolt seed network %revocation-root)
    ==
  ?>  (validate-config -.local-config funding-sats)
  local-config
::
++  poke-btc-provider
  |=  =action:btc-provider
  ^-  card
  ?~  btcp.prov  ~|("provider not set" !!)
  :*  %pass   /btc-provider-action/[(scot %da now.bowl)]
      %agent  [host.u.btcp.prov %btc-provider]
      %poke   %btc-provider-action  !>(action)
  ==
::
++  poke-provider
  |=  =action:provider
  ^-  card
  ?~  volt.prov  ~|("provider not set" !!)
  :*  %pass   /provider-action/[(scot %da now.bowl)]
      %agent  [host.u.volt.prov %volt-provider]
      %poke   %volt-provider-action  !>(action)
  ==
::
++  send-message
  |=  [msg=message:bolt who=@p]
  ^-  card
  :*  %pass   /message/[(scot %p who)]/[(scot %da now.bowl)]
      %agent  who^%volt
      %poke   %volt-message  !>(msg)
  ==
::
++  watch-provider
  |=  who=@p
  ^-  (list card)
  :-  :*  %pass   /set-provider/[(scot %p who)]
          %agent  who^%volt-provider
          %watch  /clients
      ==
    ~
::
++  watch-btc-provider
  |=  who=@p
  ^-  (list card)
  =/  =dock     [who %btc-provider]
  =/  wir=wire  /set-btc-provider/[(scot %p who)]
  :+
    :*  %pass   wir
        %agent  dock
        %watch  /clients
    ==
    :*  %pass   (welp wir [%priv ~])
        %agent  dock
        %watch  /clients/[(scot %p our.bowl)]
    ==
  ~
::
++  leave-provider
  |=  who=@p
  ^-  (list card)
  :-  :*  %pass   /set-provider/[(scot %p who)]
          %agent  who^%volt-provider
          %leave  ~
      ==
    ~
::
++  leave-btc-provider
  |=  who=@p
  ^-  (list card)
  =/  wir=wire  /set-btc-provider/[(scot %p who)]
  :+
    :*  %pass   wir
        %agent  who^%btc-provider
        %leave  ~
    ==
    :*  %pass   (welp wir %priv^~)
        %agent  who^%btc-provider
        %leave  ~
    ==
  ~
::
++  watch-pubkey
  |=  who=@p
  ^-  card
  :*  %pass         /sub-pubkeys
      %arvo         %j
      %public-keys  (silt ~[who])
  ==
::
++  unwatch-pubkey
  |=  who=@p
  ^-  card
  :*  %pass  /sub-pubkeys
      %arvo  %j
      %nuke  (silt ~[who])
  ==
::
++  give-update
  |=  =update
  ^-  card
  [%give %fact ~[/all] %volt-update !>(update)]
::
++  start-task-timer
  |=  interval=@dr
  ^-  card
  :*  %pass  /task-timer
      %arvo  %b
      %wait  (add now.bowl interval)
  ==
::
++  monitor-channels
  ^-  (list card)
  =/  update=command  [%update-channels ~]
  :~  :*  %pass   /monitor/[(scot %da now.bowl)]
          %agent  [our.bowl %volt]
          %poke   %volt-command  !>(update)
      ==
      (start-task-timer ~s10)
  ==
--
