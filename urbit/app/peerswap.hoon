/-  *peerswap, bolt
/+  *peerswap, default-agent, dbug, utilities
/+  key-gen=key-generation
/=  peerswap-message  /mar/peerswap/message
|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0
  ==
+$  state-0
  $:  %0
      swaps=(map swap-id swap)
      keypairs=(map pubkey:bolt pair:key:bolt)
  ==
--
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
    hc    ~(. +> bowl)
++  on-init
  ^-  (quip card _this)
  `this(state *state-0)
::
++  on-save
  ^-  vase
  !>(state)
::
++  on-load  on-load:def
  :: |=  old-state=vase
  :: ^-  (quip card _this)
  :: :: `this(state !<(versioned-state old-state))
  ::    `this(state !<(versioned-state ~))
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  =^  cards  state
    ?+    mark  (on-poke:def mark vase)
        %peerswap-command
      ?>  (team:title our.bowl src.bowl)
      (handle-command:hc !<(command vase))
        %peerswap-message
      ?<  =((clan:title src.bowl) %pawn)
      (handle-message:hc !<(message vase))
    ::
    ==
  [cards this]
::
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-peek   on-peek:def
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  =^  cards  state
  =/  swap-id-raw  (snag 1 wire)
  ?+    -.wire  `state
      %thread
    ?+    -.sign  `state
        %poke-ack
      ?~  p.sign
        ::  %-  (slog leaf+"Thread started successfully" ~)
        `state
      ::  %-  (slog leaf+"Thread failed to start" u.p.sign)
      `state
    ::
        %fact
      ?+    p.cage.sign  `state
          %thread-fail
        =/  err  !<  (pair term tang)  q.cage.sign
        ::  %-  (slog leaf+"Thread failed: {(trip p.err)}" q.err)
        `state
          %thread-done
        =/  =swap-id  (scan (trip swap-id-raw) dem:ag)
        =/  =swap  (get-swap swap-id)
        =/  res  !<(=update:volt q.cage.sign)
        ?+  -.res  `state
            %new-invoice  (send-swap-out-agreement:hc swap +.res)
        ==
      ==
    ==
  ==
  [cards this]
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
++  print-swap
  |=  =swap
  ~&  swap
  ~&  'printing swap'
  `state
++  debug-print
  |=  [swap-id=(unit swap-id) all=?]
  :: print swap by
  ?:  ?=(^ swap-id)
    =/  swap  (~(get by swaps.state) +.swap-id)
    ?:  ?=(^ swap)
      (print-swap +.swap)
    ~&  'No swap found with id={<swap-id>}'  `state
  ?:  all  ~&  'Print all swap ids'  ~&  swaps.state  `state
  ~&  'Print last swap id'
  `state
++  handle-command
  |=  =command
  ^-  (quip card _state)
  ?-  -.command
      %request-swap-in
    (request-swap-in +.command)
      %request-swap-out
    (request-swap-out +.command)
      %debug-print
    (debug-print +.command)
  ==
++  request-swap
  |=  [p=swap-params =swap-type]
  ^-  (quip card _state)
  :: todo: should move more filtering into query-chans on volt side
  =/  scid  (select-swap-chan (query-chans ship.p) p swap-type)
  =/  =pair:key:bolt  (make-keypair)
  =/  =swap-request  [protocol-version=1 (make-swap-id) asset=~ network.p scid sats.p pub.pair]
  =/  =swap  (new-initiator-swap swap-request swap-type)
  =/  message  ?-  swap-type
    %swap-in   [%swap-in-request swap-request]
    %swap-out  [%swap-out-request swap-request]
  ==
  :-  ~[(send-message message ship.p)]
  %=  state
    swaps     (~(put by swaps) swap-id.swap swap)
    keypairs  (~(put by keypairs) pub.pair pair)
  ==
::
++  request-swap-in
  |=  [p=swap-params]
  ^-  (quip card _state)
  (request-swap p %swap-in)
::
++  request-swap-out
  |=  [p=swap-params]
  ^-  (quip card _state)
  (request-swap p %swap-out)
::
++  handle-message
  |=  =message
  ^-  (quip card _state)
  ~&  -.message
  ?-  -.message
      %swap-in-request
    (handle-swap-in-request +.message)
      %swap-in-agreement
    (handle-swap-in-agreement +.message)
      %swap-out-request
    (handle-swap-out-request +.message)
      %swap-out-agreement
    (handle-swap-out-agreement +.message)
      %opening-tx-broadcasted
    (handle-opening-tx-broadcasted message)
      %cancel
    (handle-cancel message)
      %coop-close
    (handle-coop-close message)
==

++  handle-swap-in-request
  |=  req=swap-request
  ^-  (quip card _state)
  =/  chan  -:(skim (query-chans src.bowl) |=(=chan:bolt =(+.scid.chan scid.req)))
  ?>  (can-facilitate-swap-in req (some chan))
  =/  =pair:key:bolt  (make-keypair)
  =/  message   [%swap-in-agreement protocol-version=1 swap-id.req pub.pair premium=1]
  =/  =swap  (new-responder-swap-in req pub.pair 1)
  :-  ~[(send-message message src.bowl)]
  %=  state
    swaps     (~(put by swaps) swap-id.swap swap)
    keypairs  (~(put by keypairs) pub.pair pair)
  ==
::
++  handle-swap-out-request
  |=  req=swap-request
  ^-  (quip card _state)
  =/  chan  -:(skim (query-chans src.bowl) |=(=chan:bolt =(+.scid.chan scid.req)))
  ?>  (can-facilitate-swap-out req (some chan))
  =/  =pair:key:bolt  (make-keypair)
  =/  =swap  (new-responder-swap-out req pub.pair)
  :-  (get-opening-tx-fee-payreq req)
  %=  state
    swaps     (~(put by swaps) swap-id.swap swap)
    keypairs  (~(put by keypairs) pub.pair pair)
  ==
::
++  get-opening-tx-fee-payreq
  |=  req=swap-request
  ^-  (list card)
  =/  bc-network=network:bc  ?-  network.req
    %liquid   ~|('%peerswap: Liquid not supported' !!)
    %mainnet  %main
    %testnet  %testnet
    %signet   %regtest
  ==
  =/  hash  (scot %uv (sham eny.bowl))
  =/  tid     `@ta`(cat 3 'thread_' (scot %uv (sham eny.bowl)))
  =/  swapid  `@ta`(crip "{<swap-id.req>}")
  =/  ta-now  `@ta`(scot %da now.bowl)
  =/  =command:volt
  :*
    %add-invoice
    (estimate-opening-tx-fee)
    (some 'Peerswap opening tx fee')
    (some bc-network)
  ==
  ~&  'swapid in get payreq'  ~&  swapid
  =/  start-args  [~ `tid byk.bowl(r da+now.bowl) %api-get-invoice !>(command)]
  :~
    [%pass /thread/[swapid]/[ta-now] %agent [our.bowl %spider] %watch /thread-result/[tid]]
    [%pass /thread/[swapid]/[ta-now] %agent [our.bowl %spider] %poke %spider-start !>(start-args)]
  ==
::
::  todo: how to distinguish this thread from other threads that get invoices
++  send-swap-out-agreement
  |=  [s=swap p=payment-request:volt]
  ^-  (quip card _state)
  =/  message  [%swap-out-agreement protocol-version=1 swap-id.s our-pubkey.s payreq.p]
  =/  new=swap  (add-tx-fee-payreq s payreq.p)
  :-  ~[(send-message message src.bowl)]
  %=  state
    swaps     (~(put by swaps) swap-id.new new)
  ==
::
++  estimate-opening-tx-fee
  |=  ~
  ^-  sats:bc
  100
::
++  handle-swap-in-agreement
  |=  a=swap-in-agreement
  ^-  (quip card _state)
  :: create opening tx
  :: send tx opened message
  `state
::
++  handle-swap-out-agreement
  |=  a=swap-out-agreement
  ^-  (quip card _state)
  ~&  'handle-swap-out-agreement'
  :: pay invoice
  =/  new=swap  (add-swap-out-agreement (get-swap swap-id.a) a)
  :-  (pay-tx-fee-invoice new)
  %=  state
    swaps     (~(put by swaps) swap-id.new new)
  ==
::
++  pay-tx-fee-invoice
  |=  =swap
  ^-  (list card)
  ~

++  handle-opening-tx-broadcasted
  |=  =message
  ^-  (quip card _state)
  !!
::
++  handle-cancel
  |=  =message
  ^-  (quip card _state)
  !!
::
++  handle-coop-close
  |=  =message
  ^-  (quip card _state)
  !!
::
++  send-message
  |=  [=message who=@p]
  ^-  card
  :*  %pass   /message/[(scot %p who)]/[(scot %da now.bowl)]
      %agent  who^%peerswap
      %poke   %peerswap-message  !>(message)
  ==
::
:: queries to other agents
++  query-chans
  :: todo: filter by network
  |=  ship=@p
  ^-  (list chan:bolt)
  =/  bas=path  /(scot %p our.bowl)/volt/(scot %da now.bowl)
  .^((list chan:bolt) %gx (weld bas /channels/open/partner/(scot %p ship)/noun))
::
::
::  move to peerswap utils
::
++  can-facilitate-swap-in
  |=  [req=swap-request chan=(unit chan:bolt)]
  ^-  ?
  (can-facilitate-swap req chan %swap-in)

++  can-facilitate-swap-out
  |=  [req=swap-request chan=(unit chan:bolt)]
  ^-  ?
  (can-facilitate-swap req chan %swap-out)

++  can-facilitate-swap
  |=  [req=swap-request chan=(unit chan:bolt) =swap-type]
  ^-  ?
  ?.  =(protocol-version.req 1)
    ~|('%peerswap: Unrecognized protocol version={<protocol-version.req>} in swap request' !!)
  ?.  ?=(^ chan)
    ~|('%peerswap: Unrecognized channel scid={<scid.req>} in swap request' !!)
  =/  chan-can-swap  ?-  swap-type
    %swap-in   can-be-taker
    %swap-out  can-be-maker
  ==
  ?.  (chan-can-swap +.chan amount.req)
    ~|("%peerswap: Proposed swap channel from {<ship>} does not have sufficient inbound capacity={<amount.req>} sat." !!)
  &
::
++  select-swap-chan
  |=  [chans=(list chan:bolt) p=swap-params =swap-type]
  ^-  scid
  ?:  =(0 (lent chans))
    ~|("%peerswap: no open channel with {<ship>}" !!)
  =/  chan-can-swap  ?-  swap-type
    %swap-in   can-be-maker
    %swap-out  can-be-taker
  ==
  =/  can-swap-chans=(list chan:bolt)  (skim chans (curr chan-can-swap sats.p))
   ?:  =(0 (lent can-swap-chans))
    ~|("%peerswap: no open channel with {<ship>} has sufficient outbound capacity" !!)
  +.scid:(rear can-swap-chans)
::
:: todo: check that this actually works
++  make-keypair
  |=  ~
  =/  rng  ~(. og eny.bowl)
  =/  seed=@  (~(rad og eny.bowl) (bex 256))
  ::  todo: configure network
  ::  todo: look into key family (%multisig here)
  =/  =pair:key:bolt  (generate-keypair:key-gen seed %regtest %multisig)
  pair
::
++  can-be-maker
  |=  [=chan:bolt =sats:bc]
  ^-  ?
  ?&  (chan-has-outbound-liq chan sats)
      ?=(^ scid.chan)
  ==
::
++  can-be-taker
  |=  [=chan:bolt =sats:bc]
  ^-  ?
  ?&  (chan-has-inbound-liq chan sats)
      ?=(^ scid.chan)
  ==
::
++  chan-has-inbound-liq
  |=  [=chan:bolt amount=sats:bc]
  :: todo: need util for this conversion
  =/  =msats:bolt  (mul amount 1.000)
  ^-  ?
  :: todo: should we check our commitment or theirs
  =+  our-com=(rear our.commitments.chan)
  (gte balance.her.our-com msats)
::
++  chan-has-outbound-liq
  |=  [=chan:bolt amount=sats:bc]
  :: todo: need util for this conversion
  =/  =msats:bolt  (mul amount 1.000)
  ^-  ?
  :: todo: should we check our commitment or theirs
  =+  our-com=(rear our.commitments.chan)
  (gte balance.our.our-com msats)
::
++  make-swap-id
  |=  ~
  ^-  swap-id
  =/  rng  ~(. og eny.bowl)
  =^  tmp-id  rng  (rads:rng (bex 256))
  tmp-id
++  get-swap
  |=  =swap-id
  ^-  swap
  =/  maybe-swap=(unit swap)  (~(get by swaps) swap-id)
  ?:  ?=(^ maybe-swap)
    ~|('%peerswap: swap with id={<swap-id>} not found' !!)
  +.maybe-swap
--
