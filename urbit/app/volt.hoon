::
/-  *volt, bolt
/+  default-agent, dbug
|%
::
+$  card  card:agent:gall
::
+$  provider-state
  $:  host=ship
      connected=?
  ==
::
+$  state-0
  $:  %0
      =node-info
      ::
      prov=(unit provider-state)
      btc-prov=(unit provider-state)
      ::
      wallet=(unit ship)
      ::
      chans=(map id:bolt chan:bolt)
      pending-chans=(map id:bolt chan:bolt)
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
  `this(state !<(versioned-state old-state)
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  =^  cards  this
  ?+    mark  (on-poke:def mark vase)
      %volt-command
    ?>  (team:title our.bowl src.bowl)
    (handle-command:hc !<(command vase))
  ::
      %volt-action
    (handle-action:hc !<(action vase))
  ::
      %volt-message
    (handle-channel-message:hc !<(message vase)
  ==
  [card this]
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
      :_  this(btc-prov [~ src.bowl %.n])
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
    [card this]
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
      `this(btc-prov ~)
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
      ~[(leave-provider host.u.prov)]
    ::
    :_  state(prov `[u.provider.command %.n])
    ?~  prov
      (watch-provider u.provider.command)
    %-  zing
    :~
      ~[(leave-provider host.u.prov)]
      (watch-provider u.provider.command)
    ==
  ::
      %set-btc-provider
    ?~  provider.command
      ?~  btc-prov  `state
      :_  state(btc-prov ~)
      ~[(leave-btc-provider host.u.prov)]
    ::
    :_  state(btc-prov `[u.provider.command %.n])
    ?~  prov
      (watch-btc-provider u.provider.command)
    %-  zing
    :~
      ~[(leave-btc-provider host.u.prov)]
      (watch-btc-provider u.provider.command)
    ==
  ::
      %open-channel
    `state
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
  ^-  (quip card _state)
  ?-    -.message
      %open-channel
    :_  state
    ~[(send-message accept-channel src.bowl)]
  ::
      %accept-channel
    ?.  (~(has by pending-chans) temporary-channel-id.message)
      `state
    =/  =chan  (~(got by pending-chans) temporary-channel-id.message)
    `state
    ~[(sign-transaction tx)]
  ::
      %funding-created
    `state
  ::
      %funding-signed
    `state
  ::
      %funding-locked
    `state
  ::
      %update-add-htlc
    `state
  ::
      %commitment-signed
    `state
  ::
      %revoke-and-ack
    `state
  ::
      %shutdown
    `state
  ::
      %closing-signed
    `state
  ==
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
  ^-  (quip card _state)
  `state
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
  |=  =action:wallet
  ^-  card
  :*  %pass   /wallet-action
      %agent  [wallet %volt-wallet]
      %poke   %wallet-action  !>(action)
  ==
::
++  provider-action
  |=  =action:provider
  ^-  card
  :*  %pass   /provider-action
      %agent  [u.prov %volt-provider]
      %poke   %volt-provider  !>(action)
  ==
::
++  send-message
  |=  [who=@p msg=message:bolt]
  ^-  card
  :*  %pass   /send-message/[(scot %p who)]
      %agent  [who %volt]
      %poke   %volt-message  !>(msg)
  ==
::
++  watch-provider
  |=  who=@p
  ^-  card
  :*  %pass   wir
      %agent  dock
      %watch  /clients
  ==
::
++  watch-btc-provider
  |=  who=@p
  ^-  (list card)
  =/  =dock     [who %btc-provider]
  =/  wir=wire  /set-bitc-provider/[(scot %p who)]
  :~
    :*  %pass   wir
        %agent  dock
        %watch  /clients
    ==
  ==
--
