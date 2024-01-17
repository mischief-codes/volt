/-  *peerswap
/+  default-agent, dbug
|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0
  ==
+$  state-0
  $:  %0
      swap-requests=(map swap-id swap-request)
  ==
::
--
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
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
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  =^  cards  state
    ?+    mark  (on-poke:def mark vase)
        %command
      ?>  (team:title our.bowl src.bowl)
      (handle-command:hc !<(command vase))
        %message
      ?<  =((clan:title src.bowl) %pawn)
      (handle-message:hc !<(message vase))
    ::
    ==
  [cards this]
::
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-peek   on-peek:def
++  on-agent  on-agent:def
++  on-arvo   on-arvo:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
++  handle-command
  |=  =command
  ^-  (quip card _state)
  ?-  -.command
      %request-swap-in
    (request-swap-in +.command)
      %request-swap-out
    (request-swap-out +.command)
  ==
++  request-swap-in
  |=  [ship=@p =network amount=sats:bc]
  =/  =swap-id  (make-swap-id)  :: random
  ~&  swap-id  ~&  'swap-id'
  =/  =asset  ~  :: not used for bitcoin
  =/  =scid  100  :: get from existing channel I think
  ::  have amount
  =/  pubkey=pubkey:bolt  !!  :: where to get??
  !!
++  request-swap-out
  |=  [ship=@p =network amount=sats:bc]
  =/  =swap-id  (make-swap-id)  :: random
  ~&  swap-id  ~&  'swap-id'
  =/  =asset  ~  :: not used for bitcoin
  =/  =scid  100  :: get from existing channel I think
  ::  have amount
  =/  pubkey=pubkey:bolt  !!  :: where to get??
  !!
++  make-swap-id
  |=  ~
  ^-  swap-id
  =/  rng  ~(. og eny.bowl)
  =^  tmp-id  rng  (rads:rng (bex 256))
  tmp-id

++  handle-message
  |=  =message
  ^-  (quip card _state)
  ~&  message
  ?-  -.message
      %test
    (handle-test message)
      %swap-in-request
    (handle-swap-in-request message)
      %swap-in-agreement
    (handle-swap-in-agreement message)
      %swap-out-request
    (handle-swap-out-request message)
      %swap-out-agreement
    (handle-swap-out-agreement message)
      %opening-tx-broadcasted
    (handle-opening-tx-broadcasted message)
      %cancel
    (handle-cancel message)
      %coop-close
    (handle-coop-close message)
==
  ::
++  handle-test
  |=  =message
  ~&  'message'  ~&  message
  ^-  (quip card _state)
  !!
++  handle-swap-in-request
  |=  =message
  ^-  (quip card _state)
  !!
++  handle-swap-in-agreement
  |=  =message
  ^-  (quip card _state)
  !!
++  handle-swap-out-request
  |=  =message
  ^-  (quip card _state)
  !!
++  handle-swap-out-agreement
  |=  =message
  ^-  (quip card _state)
  !!
++  handle-opening-tx-broadcasted
  |=  =message
  ^-  (quip card _state)
  !!
++  handle-cancel
  |=  =message
  ^-  (quip card _state)
  !!
++  handle-coop-close
  |=  =message
  ^-  (quip card _state)
  !!
--
