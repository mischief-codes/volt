/-  *peerswap, bolt, volt
/+  *peerswap-utils
|%
+$  card  card:agent:gall
::
++  get-opening-tx-fee-payreq
  |=  [=bowl:gall req=swap-request]
  ^-  (list card)
  =/  =command:volt
  :*
    %add-invoice
    (estimate-opening-tx-fee)
    (some 'Peerswap opening tx fee')
    (some (get-bc-network network.req))
  ==
  (poke-volt bowl command swap-id.req)
::
++  pay-opening-tx-fee-payreq
  |=  [=bowl:gall =swap]
  :: ?>  =(status.swap %paying-tx-fee-payreq)
  ^-  (list card)
  =/  =command:volt  [%send-payment +.payreq.swap (some src.bowl)]
  (poke-volt bowl command swap-id.swap)
::
:: todo
++  estimate-opening-tx-fee
  |=  ~
  ^-  sats:bc
  100
::
++  get-thread-type-from-command
  |=  =command:volt
  ^-  thread-type
  ?+   -.command  !!
    %add-invoice   %get-opening-tx-fee-payreq
    %send-payment  %pay-opening-tx-fee-payreq
  ==
++  get-thread-type-from-wire
  |=  =wire
  ^-  thread-type
  =/  thread-type-raw  `term`(scan (trip (snag 1 wire)) sym)
  ?>  ?=(thread-type thread-type-raw)
  thread-type-raw
::
++  get-swap-id-from-wire
  |=  =wire
  ^-  swap-id
  (scan (trip (snag 2 wire)) dem:ag)
::
++  get-thread-file
  |=  =command:volt
  ^-  term
  ?+  -.command  !!
    %add-invoice   %api-get-invoice
    %send-payment  %api-send-payment
  ==
::
++  poke-volt
  |=  [=bowl:gall =command:volt =swap-id]
  ^-  (list card)
  =/  hash  (scot %uv (sham eny.bowl))
  =/  tid     `@ta`(cat 3 'thread_' (scot %uv (sham eny.bowl)))
  =/  swapid  `@ta`(crip "{<swap-id>}")
  =/  ta-now  `@ta`(scot %da now.bowl)
  =/  =thread-type  (get-thread-type-from-command command)
  =/  =wire  /thread/[thread-type]/[swapid]/[ta-now]
  :: ~&  'wire'  ~&  wire
  ~&  "thread file in threads.hoon: {<(get-thread-file command)>}"
  ~&  "thread-type in threads.hoon: {<thread-type>}"
  ~&  "command in threads.hoon: {<command>}"
  =/  start-args  [~ `tid byk.bowl(r da+now.bowl) (get-thread-file command) !>(command)]
  :~
    [%pass wire %agent [our.bowl %spider] %watch /thread-result/[tid]]
    [%pass wire %agent [our.bowl %spider] %poke %spider-start !>(start-args)]
  ==
--
