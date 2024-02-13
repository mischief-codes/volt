/-  *peerswap, bolt
/+  key-gen=key-generation
|%
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
++  can-facilitate-swap
  |=  [req=swap-request =chan:bolt =swap-type]
  ^-  ?
  ?.  =(protocol-version.req 1)
    ~|('%peerswap: Unrecognized protocol version={<protocol-version.req>} in swap request' !!)
  =/  chan-can-swap  ?-  swap-type
    %swap-in   can-be-taker
    %swap-out  can-be-maker
  ==
  ?.  (chan-can-swap chan amount.req)
    ~|("%peerswap: Proposed swap channel from {<ship>} does not have sufficient inbound capacity={<amount.req>} sat." !!)
  &
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
++  can-facilitate-swap-in
  |=  [req=swap-request =chan:bolt]
  ^-  ?
  (can-facilitate-swap req chan %swap-in)
::
++  can-facilitate-swap-out
  |=  [req=swap-request =chan:bolt]
  ^-  ?
  (can-facilitate-swap req chan %swap-out)
::
++  make-swap-id
  |=  =bowl:gall
  ^-  swap-id
  =/  rng  ~(. og eny.bowl)
  =^  tmp-id  rng  (rads:rng (bex 256))
  tmp-id
:: todo: check that this actually works
++  make-keypair
  |=  =bowl:gall
  =/  rng  ~(. og eny.bowl)
  =/  seed=@  (~(rad og eny.bowl) (bex 256))
  ::  todo: configure network
  ::  todo: look into key family (%multisig here)
  =/  =pair:key:bolt  (generate-keypair:key-gen seed %regtest %multisig)
  pair
::
++  get-bc-network
  |=  peerswap-network=network
  ^-  network:bc
  ?-  peerswap-network
    %liquid   ~|('%peerswap: Liquid network not supported' !!)
    %mainnet  %main
    %testnet  %testnet
    %signet   %regtest
  ==
--
