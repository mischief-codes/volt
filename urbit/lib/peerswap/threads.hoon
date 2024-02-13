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
:: todo
++  estimate-opening-tx-fee
  |=  ~
  ^-  sats:bc
  100
::
++  poke-volt
  |=  [=bowl:gall =command:volt =swap-id]
  ^-  (list card)
  =/  hash  (scot %uv (sham eny.bowl))
  =/  tid     `@ta`(cat 3 'thread_' (scot %uv (sham eny.bowl)))
  =/  swapid  `@ta`(crip "{<swap-id>}")
  =/  ta-now  `@ta`(scot %da now.bowl)
  =/  start-args  [~ `tid byk.bowl(r da+now.bowl) %api-get-invoice !>(command)]
  :~
    [%pass /thread/[swapid]/[ta-now] %agent [our.bowl %spider] %watch /thread-result/[tid]]
    [%pass /thread/[swapid]/[ta-now] %agent [our.bowl %spider] %poke %spider-start !>(start-args)]
  ==
--
