/-  peerswap
/+  default-agent, dbug
|%
+$  card  card:agent:gall
+$  versioned-state
  $%  state-0
  ==
+$  state-0  @
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
  `this
++  on-save   on-save:def
++  on-load   on-load:def
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  =^  cards  state
    ?+    mark  (on-poke:def mark vase)
        %message
      ?<  =((clan:title src.bowl) %pawn)
      (handle-message:hc !<(message:peerswap vase))
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
++  handle-message
  |=  =message:peerswap
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
  |=  =message:peerswap
  ~&  'message'  ~&  message
  ^-  (quip card _state)
  !!
++  handle-swap-in-request
  |=  =message:peerswap
  ^-  (quip card _state)
  !!
++  handle-swap-in-agreement
  |=  =message:peerswap
  ^-  (quip card _state)
  !!
++  handle-swap-out-request
  |=  =message:peerswap
  ^-  (quip card _state)
  !!
++  handle-swap-out-agreement
  |=  =message:peerswap
  ^-  (quip card _state)
  !!
++  handle-opening-tx-broadcasted
  |=  =message:peerswap
  ^-  (quip card _state)
  !!
++  handle-cancel
  |=  =message:peerswap
  ^-  (quip card _state)
  !!
++  handle-coop-close
  |=  =message:peerswap
  ^-  (quip card _state)
  !!
--
