::  volt.hoon
::
/-  *volt, bolt, btc-provider
/+  default-agent, dbug
/+  bolt, bl=btc, bc=bitcoin
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
          ::  fund=(set utxo:btc)  :: funding outputs
          ::  resv=(set utxo:btc)  :: reserved outputs
      ==
      ::
      $=  chain
      $:  block=@ud
          fee=(unit sats:bc)   :: sats/vbyte
          time=@da
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
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+    path  (on-watch:def path)
      [%all ~]
    ?>  (team:title our.bowl src.bowl)
    `this
  ==
::
++  on-arvo   on-arvo:def
++  on-peek   on-peek:def
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
    ?:  =(host.u.prov our.bowl) :: own provider wat do?
      `state
    =+  +.command
    =+  tmp-id=(make-temp-id)
    =+  conf=(make-local-config funding-sats push-msats %.y)
    ::
    =|  oc=open-channel:msg:bolt
    =.  temporary-channel-id.oc            tmp-id
    =.  chain-hash.oc                      (chain-hash:bolt %main)
    =.  funding-sats.oc                    funding-sats
    =.  push-msats.oc                      push-msats
    =.  funding-pubkey.oc                  multisig-pubkey.conf
    =.  dust-limit-sats.oc                 dust-limit-sats.conf
    =.  max-htlc-value-in-flight-msats.oc  max-htlc-value-in-flight-msats.conf
    =.  channel-reserve-sats.oc            reserve-sats.conf
    =.  htlc-minimum-msats.oc              htlc-minimum-msats.conf
    =.  feerate-per-kw.oc                  (current-feerate-per-kw)
    =.  to-self-delay.oc                   to-self-delay.conf
    =.  max-accepted-htlcs.oc              max-accepted-htlcs.conf
    =.  basepoints.oc                      basepoints.conf
    ::
    ::  TODO: what should we do about upfront shutdown?
    =.  shutdown-script-pubkey.oc          0^0x0
    =.  anchor-outputs.oc                  anchor-outputs.conf
    ::
    =/  first-per-commitment-secret=hexb:bc
      %+  generate-from-seed:secret:bolt
        per-commitment-secret-seed.conf
      first-index:secret:bolt
    ::
    =.  first-per-commitment-point.oc
      %-  compute-commitment-point:secret:bolt
        first-per-commitment-secret
    ::
    =|  lar=larva-chan:bolt
    =.  oc.lar         `oc
    =.  our.lar        conf
    =.  initiator.lar  %.y
    =.  ship.her.lar   who
    ::
    :_  state(pends.chan (~(put by pends.chan) tmp-id lar))
    ~[(send-message [%open-channel oc] who)]
  ::
      %close-channel
    ?~  prov  `state
    ?:  =(host.u.prov our.bowl) :: own provider wat do?
      `state
    `state
  ::
      %send-payment
    ?~  prov  `state
    ?:  =(host.u.prov our.bowl) :: own provider wat do?
      `state
    `state
  ::
      %create-funding
    ::  continue channel funding flow
    =+  +.command
    =/  c=(unit larva-chan:bolt)
      (~(get by pends.chan) temporary-channel-id)
    ?~  c
      ~&  >>>  "%volt: no channel with id: {<temporary-channel-id>}"
      `state
    ?~  fc.u.c
      ~&  >>>  "%volt: invalid channel state: {<temporary-channel-id>}"
      `state
    ::
    ::  todo: create channel ID and move
    :_  state(pends.chan (~(put by pends.chan) temporary-channel-id u.c))
    ~[(send-message [%funding-created u.fc.u.c] ship.her.u.c)]
  ==
::
++  handle-message
  |=  =message:bolt
  |^  ^-  (quip card _state)
  ~&  >  "got message: {<message>}"
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
    =+  conf=(make-local-config funding-sats push-msats %.n)
    =|  rc=remote-config:bolt
    =.  multisig-pubkey.rc                 funding-pubkey
    =.  basepoints.rc                      basepoints
    =.  to-self-delay.rc                   to-self-delay
    =.  dust-limit-sats.rc                 dust-limit-sats
    =.  max-htlc-value-in-flight-msats.rc  max-htlc-value-in-flight-msats
    =.  max-accepted-htlcs.rc              max-accepted-htlcs
    =.  initial-msats.rc                   (sub (mul funding-sats 1.000) push-msats)
    =.  reserve-sats.rc                    channel-reserve-sats
    =.  htlc-minimum-msats.rc              htlc-minimum-msats
    =.  next-per-commitment-point.rc       first-per-commitment-point
    ::  TODO: upfront shutdown script
    =.  upfront-shutdown-script.rc         0^0x0
    ::
    ~|  %incompatible-channel-configurations
    ?>  (validate-channel-sides conf rc funding-sats %.n feerate-per-kw)
    ::
    =|  ac=accept-channel:msg:bolt
    =.  temporary-channel-id.ac            temporary-channel-id
    =.  dust-limit-sats.ac                 dust-limit-sats.conf
    =.  max-htlc-value-in-flight-msats.ac  max-htlc-value-in-flight-msats.conf
    =.  channel-reserve-sats.ac            reserve-sats.conf
    =.  htlc-minimum-msats.ac              htlc-minimum-msats.conf
    =.  minimum-depth.ac                   3  ::  default value
    =.  to-self-delay.ac                   to-self-delay.conf
    =.  max-accepted-htlcs.ac              max-accepted-htlcs.conf
    =.  funding-pubkey.ac                  multisig-pubkey.conf
    =.  basepoints.ac                      basepoints.conf
    ::  TODO: upfront shutdown script
    =.  shutdown-script-pubkey.ac  0^0x0
    =.  anchor-outputs.ac          anchor-outputs.conf
    ::
    =/  first-per-commitment-secret=hexb:bc
      %+  generate-from-seed:secret:bolt
        per-commitment-secret-seed.conf
      first-index:secret:bolt
    ::
    =.  first-per-commitment-point.ac
      %-  compute-commitment-point:secret:bolt
        first-per-commitment-secret
    ::
    =|  lar=larva-chan:bolt
    =.  initiator.lar  %.n
    =.  our.lar        conf
    =.  her.lar        rc
    =.  oc.lar         `open-channel
    =.  ac.lar         `ac
    ::
    :_  state(pends.chan (~(put by pends.chan) temporary-channel-id lar))
    ~[(send-message [%accept-channel ac] src.bowl)]
  ::
  ++  handle-accept-channel
    |=  =accept-channel:msg:bolt
    ^-  (quip card _state)
    =+  accept-channel
    =/  c=(unit larva-chan:bolt)
      (~(get by pends.chan) temporary-channel-id)
    ?~  c
      ~&  >>>  "%volt: %accept-channel for non-existent channel: {<temporary-channel-id>}"
      `state
    ?~  oc.u.c
      ~&  >>>  "%volt: %accept-channel without %open-channel: {<temporary-channel-id>}"
      `state
    ?^  fc.u.c
      ~&  >>>  "volt: funding already created: {<temporary-channel-id>}"
      `state
    ?.  initiator.u.c
      ~|("initiator sent accept channel" !!)
    ::
    ~|  "minimum depth too low {<minimum-depth>}"
    ?<  (lte minimum-depth 0)
    ~|  "minimum depth too high {<minimum-depth>}"
    ?<  (gth minimum-depth 30)
    ::
    =|  rc=remote-config:bolt
    =.  basepoints.rc                      basepoints
    =.  multisig-pubkey.rc                 funding-pubkey
    =.  to-self-delay.rc                   to-self-delay
    =.  dust-limit-sats.rc                 dust-limit-sats
    =.  max-htlc-value-in-flight-msats.rc  max-htlc-value-in-flight-msats
    =.  max-accepted-htlcs.rc              max-accepted-htlcs
    =.  initial-msats.rc                   push-msats.u.oc.u.c
    =.  reserve-sats.rc                    channel-reserve-sats
    =.  htlc-minimum-msats.rc              htlc-minimum-msats
    =.  next-per-commitment-point.rc       first-per-commitment-point
    =.  upfront-shutdown-script.rc         shutdown-script-pubkey
    =.  anchor-outputs.rc                  anchor-outputs
    ::
    ~|  %incompatible-channel-configurations
    ?>  (validate-channel-sides our.u.c rc funding-sats.u.oc.u.c %.y feerate-per-kw.u.oc.u.c)
    ::
    =/  funding-output=output:tx:bc
      %^    funding-output:bolt-tx:bolt
          multisig-pubkey.our.u.c
        multisig-pubkey.rc
      funding-sats.u.oc.u.c
    ::
    =.  funding-tx.u.c
      %_  funding-tx.u.c
        os  (sort-outputs:bip69:bolt [funding-output os.funding-tx.u.c])
      ==
    ::
    =+  psbt=(to-psbt funding-tx.u.c)
    =+  funding-txid=(get-id:txu:bc funding-tx.u.c)
    =+  funding-out-pos=(find [funding-output]~ os.funding-tx.u.c)
    ?~  funding-out-pos
      ~|(%invalid-funding-tx !!)
    =/  multisig-privkey=@  prv:(generate-keypair seed.our.u.c %multisig)
    ::
    =|  fc=funding-created:msg:bolt
    =.  temporary-channel-id.fc  temporary-channel-id
    =.  funding-outpoint.fc      [funding-txid u.funding-out-pos funding-sats.u.oc.u.c]
    =.  signature.fc             (sign-commitment dat.funding-txid multisig-privkey)
    ::
    =|  lar=larva-chan:bolt
    =.  funding-tx.lar  funding-tx.u.c
    =.  our.lar         our.u.c
    =.  her.lar         rc
    =.  oc.lar          oc.u.c
    =.  ac.lar          `accept-channel
    =.  fc.lar          `fc
    ::
    :_  state(pends.chan (~(put by pends.chan) temporary-channel-id lar))
    ~[(give-update [%need-funding-signature temporary-channel-id psbt])]
  ::
  ++  handle-funding-created
    |=  =funding-created:msg:bolt
    ^-  (quip card _state)
    =+  funding-created
    =/  c=(unit larva-chan:bolt)
      %-  ~(get by pends.chan)
        temporary-channel-id
    ?~  c  `state
    =|  fs=funding-signed:msg:bolt
    :_  state
    ~[(send-message [%funding-signed fs] src.bowl)]
  ::
  ++  handle-funding-signed
    |=  =funding-signed:msg:bolt
    ^-  (quip card _state)
    =+  funding-signed
    :_  state
    ~[(poke-btc-provider [%broadcast-tx 0^0x0])]
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
      `state(chain [block=block.result fee=fee.result time=now.bowl])
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
++  give-update
  |=  =update
  ^-  card
  [%give %fact ~[/all] %volt-update !>(update)]
::
++  make-temp-id
  |.
  ^-  hexb:bc
  :-  32
  %-  ~(rad og eny.bowl)
  %-  bex  256
::
++  generate-keypair
  |=  [seed=hexb:bc =family:key:bolt]
  (generate-keypair:bolt seed %main family 0)
::
::  TODO: estimate fee based on network state, target ETA, desired confs
++  current-feerate-per-kw
  |.
  %+  max
    feerate-per-kw-min-relay:const:bolt
  (div feerate-fallback:const:bolt 4)
::
++  to-psbt
  |=  tx=data:tx:bc
  ^-  base64:psbt:bc
  =+  raw-tx=(basic-encode:txu:bc tx)
  (encode:pbt:bc %.y raw-tx 0^0x0 ~ ~)
::
++  make-local-config
  |=  [=funding=sats:bc =push=msats initiator=?]
  ^-  local-config:bolt
  =+  seed=[wid=32 dat=(~(rad og eny.bowl) (bex 256))]
  =/  initial-msats=msats
    ?:  initiator
      %+  sub
        %-  sats-to-msats:bolt  funding-sats
      push-msats
    push-msats
  =|  =local-config:bolt
  %_  local-config
    seed                        seed
    to-self-delay               (mul 7 144)
    dust-limit-sats             dust-limit-sats:const:bolt
    ::
    max-htlc-value-in-flight-msats  (sats-to-msats:bolt funding-sats)
    max-accepted-htlcs          30
    initial-msats               initial-msats
    reserve-sats                (max (div funding-sats 100) dust-limit-sats:const:bolt)
    funding-locked-received     %.n
    htlc-minimum-msats          1
    ::
    per-commitment-secret-seed  [32 prv:(generate-keypair seed %revocation-root)]
    multisig-pubkey             pub:(generate-keypair seed %multisig)
    htlc.basepoints             pub:(generate-keypair seed %htlc-base)
    payment.basepoints          pub:(generate-keypair seed %payment-base)
    delayed-payment.basepoints  pub:(generate-keypair seed %delay-base)
    revocation.basepoints       pub:(generate-keypair seed %revocation-base)
    anchor-outputs              %.y
  ==
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
::
++  sign-commitment
  =,  secp256k1:secp:crypto
  |=  [txid=@ key=@]
  ^-  hexb:bc
  =+  [v=@ r=@ s=@]=(ecdsa-raw-sign txid key)
  %-  cat:byt:bcu:bc
  :~  [wid=32 dat=v]
      [wid=32 dat=r]
      [wid=1 dat=s]
  ==
--
