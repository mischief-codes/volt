::  volt.hoon
::
/-  *volt, bolt
/-  btc=bitcoin, btc-wallet, btc-provider
/+  default-agent, dbug, libbolt=bolt
|%
+$  card  card:agent:gall
::
+$  provider-state  [host=ship connected=?]
::
+$  state-0
  $:  %0
      =node-info
      prov=(unit provider-state)
      btcp=(unit provider-state)
      ::
      $=  chan
      $:  activ=(map id:bolt chan:bolt)
          pends=(map hexb:bc larva-chan:bolt)
      ==
      ::
      $=  walt
      $:  prov=(unit ship)
          fund=(set utxo:btc)  :: funding outputs
          resv=(set utxo:btc)  :: reserved outputs
      ==
  ==
::
+$  versioned-state
  $%  state-0
  ==
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
++  on-init
  ^-  (quip card _this)
  `this(state *state-0)
::
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
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
    ::
        %volt-wallet-result
      ?>  (team:title our.bowl src.bowl)
      (handle-wallet-result:hc !<(result:wallet vase))
    ==
  [cards this]
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    -.sign  (on-agent:def wire sign)
      %kick
    ?:  ?=(%set-provider -.wire)
      :_  this(prov [~ src.bowl %.n])
      (watch-provider:hc src.bowl)
    ::
    ?:  ?=(%set-btc-provider -.wire)
      :_  this(btcp [~ src.bowl %.n])
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
      `this(prov ~)
    ::
    ?:  ?=(%set-btc-provider -.wire)
      ?~  p.sign
        `this
      =/  =tank  leaf+"subscribe to btc provider {<dap.bowl>} failed"
      %-  (slog tank u.p.sign)
      `this(btcp ~)
    ::
    `this
  ==
::
++  on-arvo   on-arvo:def
++  on-peek   on-peek:def
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
::
++  handle-command
  |=  =command
  ^-  (quip card _state)
  ?-    -.command
      %set-provider
    ?~  provider.command
      ?~  prov  `state
      :_  state(prov ~)
      (leave-provider host.u.prov)
    ::
    :_  state(prov `[u.provider.command %.n])
    ?~  prov  (watch-provider u.provider.command)
    %-  zing
    :~  (leave-provider host.u.prov)
        (watch-provider u.provider.command)
    ==
  ::
      %set-btc-provider
    ?~  provider.command
      ?~  btcp  `state
      :_  state(btcp ~)
      (leave-btc-provider host.u.btcp)
    ::
    :_  state(btcp `[u.provider.command %.n])
    ?~  btcp  (watch-btc-provider u.provider.command)
    %-  zing
    :~  (leave-btc-provider host.u.btcp)
        (watch-btc-provider u.provider.command)
    ==
  ::
      %set-wallet
    %-  ?~  who.command
        ~&  >  "%volt: unsetting wallet provider"  same
        ~&  >  "%volt: setting wallet provider: {<who.command>}"  same
    `state(prov.walt who.command)
  ::
      %open-channel
    ?~  prov  `state
    =+  +.command
    =+  tmp-id=(make-temp-id)
    =+  conf=(make-local-config funding-sats push-msats %.y)
    ::
    =|  oc=open-channel:msg:bolt
    =.  temporary-channel-id.oc            tmp-id
    =.  chain-hash.oc                      (chain-hash:libbolt %main)
    =.  funding-sats.oc                    funding-sats
    =.  push-msats.oc                      push-msats
    =.  funding-pubkey.oc                  multisig-pubkey.conf
    =.  dust-limit-sats.oc                 dust-limit-sats.conf
    =.  max-htlc-value-in-flight-msats.oc  max-htlc-value-in-flight-msats.conf
    =.  channel-reserve-sats.oc            reserve-sats.conf
    =.  htlc-minimum-msats.oc              htlc-minimum-msats.conf
    =.  feerate-per-kw.oc                  0
    =.  to-self-delay.oc                   to-self-delay.conf
    =.  max-accepted-htlcs.oc              max-accepted-htlcs.conf
    =.  basepoints.oc                      basepoints.conf
    =.  first-per-commitment-point.oc      [x=0 y=0]
    ::  ok, we need to figure out per-commitment-secret generation
    ::  i thought i had this code but it wasn't compiling so let's
    ::  try to revive it.
    =.  shutdown-script-pubkey.oc          0^0x0
    =.  anchor-outputs.oc                  %.y
    ::
    =|  lar=larva-chan:bolt
    =.  oc.lar         `oc
    =.  our.lar        conf
    =.  initiator.lar  %.y
    ::
    :_  state(pends.chan (~(put by pends.chan) tmp-id lar))
    ~[(send-message [%open-channel oc] who)]
  ::
      %close-channel
    `state
  ::
      %send-payment
    `state
  ==
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
      `state
    ::
        %update-fail-htlc
      `state
    ::
        %update-fail-malformed-htlc
      `state
    ::
        %update-fee
      `state
    ==
  [cards state]
  ::
  ++  handle-open-channel
    |=  =open-channel:msg:bolt
    ^-  (quip card _state)
    =+  open-channel
    =|  conf=remote-config:bolt
    =|  ac=accept-channel:msg:bolt
    :_  state
    ~[(send-message [%accept-channel ac] src.bowl)]
  ::
  ++  handle-accept-channel
    |=  =accept-channel:msg:bolt
    ^-  (quip card _state)
    =+  accept-channel
    =/  c=(unit larva-chan:bolt)
      %-  ~(get by pends.chan)
        temporary-channel-id
    ?~  c  `state
    =|  fc=funding-created:msg:bolt
    :_  state
    ~[(send-message [%funding-created fc] src.bowl)]
  ::
  ++  handle-funding-created
    |=  =funding-created:msg:bolt
    ^-  (quip card _state)
    =+  funding-created
    `state
  ::
  ++  handle-funding-signed
    |=  =funding-signed:msg:bolt
    ^-  (quip card _state)
    =+  funding-signed
    `state
  ::
  ++  handle-funding-locked
    |=  =funding-locked:msg:bolt
    ^-  (quip card _state)
    =+  funding-locked
    `state
  ::
  ++  handle-update-add-htlc
    |=  update=update-add-htlc:msg:bolt
    ^-  (quip card _state)
    =+  update
    `state
  ::
  ++  handle-commitment-signed
    |=  =commitment-signed:msg:bolt
    ^-  (quip card _state)
    =+  commitment-signed
    `state
  ::
  ++  handle-revoke-and-ack
    |=  =revoke-and-ack:msg:bolt
    ^-  (quip card _state)
    =+  revoke-and-ack
    `state
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
  --
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
  ^-  (quip card _state)
  `state
::
++  handle-bitcoin-status
  |=  =status:btc-provider
  ^-  (quip card _state)
  `state
::
++  handle-bitcoin-update
  |=  =update:btc-provider
  |^  ^-  (quip card _state)
  ?:  ?=([%| *] update)
    (provider-error +.update)
  (provider-result +.update)
  ::
  ++  provider-error
    |=  =error:btc-provider
    ^-  (quip card _state)
    `state
  ::
  ++  provider-result
    |=  =result:btc-provider
    ^-  (quip card _state)
    ?-    -.result
        %address-info
      `state
    ::
        %tx-info
      `state
    ::
        %raw-tx
      `state
    ::
        %broadcast-tx
      `state
    ::
        %block-info
      ::  check blockfilter for addresses we're interested in.
      `state
    ==
  --
::
++  handle-wallet-result
  |=  =result:wallet
  ^-  (quip card _state)
  ?-    -.result
      %public-key
    `state
  ::
      %address
    `state
  ::
      %signature
    `state
  ==
::
++  wallet-action
  |=  [pat=path =action:wallet]
  ^-  card
  ?~  prov.walt  ~|("provider not set" !!)
  :*  %pass   pat
      %agent  [u.prov.walt %volt-wallet]
      %poke   %wallet-action  !>(action)
  ==
::
++  poke-provider
  |=  =action:provider
  ^-  card
  ?~  prov  ~|("provider not set" !!)
  :*  %pass   /provider-action/[(scot %da now.bowl)]
      %agent  [host.u.prov %volt-provider]
      %poke   %volt-provider  !>(action)
  ==
::
++  poke-btc-provider
  |=  =action:btc-provider
  ^-  card
  ?~  btcp  ~|("provider not set" !!)
  :*  %pass   /btc-provider-action/[(scot %da now.bowl)]
      %agent  [host.u.btcp %volt-provider]
      %poke   %volt-provider  !>(action)
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
++  make-temp-id
  |.
  ^-  hexb:bc
  :-  32
  %-  ~(rad og eny.bowl)
  %-  bex  256
::
++  make-local-config
  |=  [=funding=sats:bc =push=msats initiator=?]
  |^  ^-  local-config:bolt
  =+  seed=[wid=32 dat=(~(rad og eny.bowl) (bex 256))]
  =/  initial-msats=msats
    ?:  initiator
      %+  sub
        %-  sats-to-msats:libbolt  funding-sats
      push-msats
    push-msats
  =|  =local-config:bolt
  %_  local-config
    seed                        seed
    to-self-delay               (mul 7 144)
    dust-limit-sats             dust-limit-sats:const:bolt
    ::
    max-htlc-value-in-flight-msats  (sats-to-msats:libbolt funding-sats)
    max-accepted-htlcs          30
    initial-msats               initial-msats
    reserve-sats                (max (div funding-sats 100) dust-limit-sats:const:bolt)
    funding-locked-received     %.n
    htlc-minimum-msats          1
    ::
    per-commitment-secret-seed  prv:(generate-keypair seed %revocation-root)
    multisig-pubkey             pub:(generate-keypair seed %multisig)
    htlc.basepoints             pub:(generate-keypair seed %htlc-base)
    payment.basepoints          pub:(generate-keypair seed %payment-base)
    delayed-payment.basepoints  pub:(generate-keypair seed %delay-base)
    revocation.basepoints       pub:(generate-keypair seed %revocation-base)
  ==
  ++  generate-keypair
    |=  [seed=hexb:bc =family:key:bolt]
    (generate-keypair:libbolt seed %main family 0)
  --
::
++  reserve-funding
  |=  =funding=sats:bc
  ^-  (pair data:tx:bolt _state)
  :-  *data:tx:bolt  state
::
++  validate-config
  |=  [config=channel-config:bolt =funding=sats:bc]
  ^-  ?
  ?:  (lth funding-sats min-funding-sats:const:bolt)
    ~|  "funding-sats too low: {<funding-sats>} < {<min-funding-sats:const:bolt>}"
      !!
  ?:  (gth funding-sats max-funding-sats:const:bolt)
    ~|  "funding-sats too high: {<funding-sats>} > {<max-funding-sats:const:bolt>}"
      !!
  ?.  ?&  (lte 0 initial-msats.config)
          (lte initial-msats.config (mul 1.000 funding-sats))
      ==
    ~|("bad initial-msats" !!)
  ?:  (lth reserve-sats.config dust-limit-sats.config)
    ~|("reserve satoshis less than dust limit" !!)
  %.y
::
++  validate-channel-sides
  |=  $:  local=local-config:bolt
          remote=remote-config:bolt
          =funding=sats:bc
          our=?
          initial-feerate-per-kw=sats:bc
      ==
  ^-  ?
  ?&  (validate-config -.local funding-sats)
      (validate-config -.remote funding-sats)
  ==
--
