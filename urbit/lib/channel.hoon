::  channel.hoon: channel state manipulation
::
/-  *bolt
/+  psbt, *utilities
/+  bc=bitcoin, btc-script=bolt-script
/+  tx=transactions, script=scripts, keys=key-generation
/+  revocation=revocation-store, log=update-log
::
|_  c=chan
::
++  make-channel-id
  |=  [funding-txid=hexb:bc funding-output-index=@ud]
  ^-  id
  (mix dat.funding-txid funding-output-index)
::  +state-transitions: allowable state transitions for channel
::
++  state-transitions
  ^-  (set (pair chan-state))
  %-  silt
  ^-  (list (pair chan-state))
  :~  [%preopening %opening]
      [%opening %funded]
      [%funded %open]
      [%opening %shutdown]
      [%funded %shutdown]
      [%open %shutdown]
      [%shutdown %shutdown]
      [%shutdown %closing]
      [%closing %closing]
    ::
      [%opening %force-closing]
      [%funded %force-closing]
      [%open %force-closing]
      [%shutdown %force-closing]
      [%closing %force-closing]
    ::
      [%opening %closed]
      [%funded %closed]
      [%open %closed]
      [%shutdown %closed]
      [%closing %closed]
    ::
      [%force-closing %force-closing]
      [%force-closing %closed]
      [%force-closing %redeemed]
      [%closed %redeemed]
      [%opening %redeemed]
      [%preopening %redeemed]
  ==
::
++  new
  |=  $:  =id
          =local-config
          =remote-config
          =funding=outpoint
          initial-feerate=sats:bc
          initiator=?
          anchor-outputs=?
          capacity=sats:bc
          funding-tx-min-depth=blocks
      ==
  ^-  chan
  *chan
::
++  is-active
  ^-  ?
  =(state.c %open)
::
++  is-funded
  ^-  ?
  =+  ^=  idx
      %+  find  [state.c]~
      :~  %funded
          %open
          %shutdown
          %closing
          %force-closing
          %redeemed
      ==
  ?=(^ idx)
::
++  is-closing
  ^-  ?
  =+  ^=  idx
      %+  find  [state.c]~
      ~[%shutdown %closing %force-closing]
  ?=(^ idx)
::
++  is-closed
  ^-  ?
  =+  ^=  idx
      %+  find  [state.c]~
      ~[%closing %force-closing %redeemed]
  ?=(^ idx)
::
++  is-redeemed
  =(state.c %redeemed)
::
++  can-update
  ^-  ?
  ?|  =(state.c %open)
      =(state.c %closing)
  ==
::
++  set-state
  |=  new-state=chan-state
  ^-  chan
  ?.  (~(has in state-transitions) [state.c new-state])
    ~|("illegal-state-transition: {<state.c>}->{<new-state>}" !!)
  c(state new-state)
::
++  invert-owner
  |=  o=owner
  ^-  owner
  ?-  o
    %local   %remote
    %remote  %local
  ==
::
++  config-for
  |=  =owner
  ^-  channel-config
  ?-  owner
    %local   -.our.config.c
    %remote  -.her.config.c
  ==
::
++  commitments-for
  |=  =owner
  ^-  (list commitment)
  ?-  owner
    %local   our.commitments.c
    %remote  her.commitments.c
  ==
::
++  make-funding-address
  |=  [=network =local-funding=pubkey =remote-funding=pubkey]
  ^-  address:bc
  :-  %bech32
  %-  need
  %+  bech32-encode  network
  %-  sha256:bcu:bc
  %-  en:btc-script
  %+  funding-output:script
    local-funding-pubkey
  remote-funding-pubkey
::
++  funding-address
  ^-  address:bc
  %^    make-funding-address
      network.our.config.c
    pub.multisig-key.our.config.c
  pub.multisig-key.her.config.c
::
++  funding-tx-min-depth
  ^-  blocks
  funding-tx-min-depth.constraints.c
::
++  oldest-unrevoked-commitment
  |=  =owner
  ^-  (unit commitment)
  ?~  (commitments-for owner)
    ~
  `(head (commitments-for owner))
::
++  latest-commitment
  |=  =owner
  ^-  (unit commitment)
  ?~  (commitments-for owner)
    ~
  `(rear (commitments-for owner))
::
++  oldest-unrevoked-commitment-number
  |=  =owner
  ^-  commitment-number
  =+  oldest=(oldest-unrevoked-commitment owner)
  ?~  oldest  0
  height.u.oldest
::
++  latest-commitment-number
  |=  =owner
  ^-  commitment-number
  =+  latest=(latest-commitment owner)
  ?~  latest  0
  height.u.latest
::
++  next-commitment-number
  |=  =owner
  =+  latest=(latest-commitment owner)
  ?~  latest  0
  +(height.u.latest)
::
++  select-updates
  |=  [our-index=@ her-index=@]
  ^-  [ours=(list update) hers=(list update)]
  =+  ^=  acc-updates
      |=  index=@
      |=  [=update acc=(list update)]
      ?:  (lth index.update index)
        [update acc]
      acc
  :*  ^=  ours
      %+  roll  list.our.updates.c
      (acc-updates our-index)
  ::
      ^=  hers
      %+  roll  list.her.updates.c
      (acc-updates her-index)
  ==
::
++  removed-indices
  |=  updates=(list update)
  ^-  (set @)
  %+  roll  updates
  |=  [=update acc=(set @)]
  ?+    -.update  acc
    %settle-htlc          (~(put in acc) parent.update)
    %fail-htlc            (~(put in acc) parent.update)
    %fail-malformed-htlc  (~(put in acc) parent.update)
  ==
::
+$  evaluation-state
  $:  whose=owner
      our-balance=msats
      her-balance=msats
      our-removals=(set @)
      her-removals=(set @)
      our-htlcs=(list add-htlc-update)
      her-htlcs=(list add-htlc-update)
      ours-pending-lock-in=(list update)
      hers-pending-lock-in=(list update)
      total-weight=@
      fee-rate=sats:bc
  ==
::
++  calculate-commitment-weight
  |=  state=evaluation-state
  ^-  evaluation-state
  =+  ^=  is-dust
      |=  incoming=?
      |=  h=add-htlc-update
      ^-  ?
      =/  =direction
        ?:  ?|  ?&(incoming =(whose.state %local))
                ?&(?!(incoming) =(whose.state %remote))
            ==
          %received
        %sent
      %:  is-trimmed:tx
        direction=direction
        amount-msats=amount-msats.h
        feerate=fee-rate.state
        dust-limit=dust-limit-sats:(config-for whose.state)
        anchor=anchor-outputs.constraints.c
      ==
  =+  n-ours=(lent (skip our-htlcs.state (is-dust %.n)))
  =+  n-hers=(lent (skip her-htlcs.state (is-dust %.y)))
  =/  weight=@
    %+  add
      ?:  anchor-outputs.constraints.c
        anchor-commit-weight:tx
      commitment-tx-weight:tx
    %+  add
      (mul n-ours htlc-output-weight:tx)
    (mul n-hers htlc-output-weight:tx)
  state(total-weight weight)
::
++  add-back-fees
  |=  state=evaluation-state
  ^-  evaluation-state
  =+  latest=(latest-commitment whose.state)
  ?~  latest  state
  %=    state
      our-balance
    ?:  initiator.constraints.c
      (add fee.u.latest our-balance.state)
    our-balance.state
  ::
      her-balance
    ?:  initiator.constraints.c
      her-balance.state
    (add fee.u.latest her-balance.state)
  ==
::
++  evaluate-updates
  |=  $:  ours=(list update)
          hers=(list update)
          state=evaluation-state
      ==
  |^
  ^-  evaluation-state
  =.  state
    %=  state
      our-removals  (removed-indices ours)
      her-removals  (removed-indices hers)
    ==
  =.  state
    %+  roll  ours
    |:  [entry=*update state=state]
    (evaluate-update entry %.y state)
  =.  state
    %+  roll  hers
    |:  [entry=*update state=state]
    (evaluate-update entry %.n state)
  state
  ::
  ++  evaluate-update
    |=  [=update ours=? state=evaluation-state]
    ^-  evaluation-state
    ?+  -.update   (evaluate-remove update ours state)
      %add-htlc    (evaluate-add update ours state)
      %fee-update  (evaluate-fee update ours state)
    ==
  ::
  ++  evaluate-add
    |=  [=update ours=? state=evaluation-state]
    ^-  evaluation-state
    ?>  ?=([%add-htlc *] update)
    =+  ^=  removed
        ?:  ours
          our-removals.state
        her-removals.state
    ?:  (~(has in removed) htlc-id.update)
      state
    =+  ^=  add-height
        ?:  =(%local whose.state)
          our.add-height.update
        her.add-height.update
    ?.  =(add-height 0)  state
    %=  state
        ours-pending-lock-in
      ?:  ours
        [update ours-pending-lock-in.state]
      ours-pending-lock-in.state
    ::
        hers-pending-lock-in
      ?:  ours
        hers-pending-lock-in.state
      [update hers-pending-lock-in.state]
    ::
        our-balance
      ?:  ours
        (sub our-balance.state amount-msats.update)
      our-balance.state
    ::
        her-balance
      ?:  ours
        her-balance.state
      (sub her-balance.state amount-msats.update)
    ::
        our-htlcs
      ?:  ours
        [+.update our-htlcs.state]
      our-htlcs.state
    ::
        her-htlcs
      ?:  ours
        her-htlcs.state
      [+.update her-htlcs.state]
    ==
  ::
  ++  evaluate-remove
    |=  [=update ours=? state=evaluation-state]
    ^-  evaluation-state
    =+  ^=  rem-height
        ?:  =(%local whose.state)
          our.rem-height.update
        her.rem-height.update
    ?.  !=(rem-height 0)  state
    =/  amount=msats
      ?+  -.update  !!
        %settle-htlc          amount-msats.update
        %fail-htlc            amount-msats.update
        %fail-malformed-htlc  amount-msats.update
      ==
    %=    state
        ours-pending-lock-in
      ?:  ours
        [update ours-pending-lock-in.state]
      ours-pending-lock-in.state
    ::
        hers-pending-lock-in
      ?:  ours
        [update hers-pending-lock-in.state]
      hers-pending-lock-in.state
    ::
        our-balance
      ?:  ours
        our-balance.state
      (add our-balance.state amount)
    ::
        her-balance
      ?:  ours
        (add her-balance.state amount)
      her-balance.state
    ==
  ::
  ++  evaluate-fee
    |=  [=update ours=? tate=evaluation-state]
    ^-  evaluation-state
    ?>  ?=([%fee-update *] update)
    =+  ^=  add-height
        ?:  =(%local whose.state)
          our.add-height.update
        her.add-height.update
    =+  ^=  rem-height
        ?:  =(%local whose.state)
          our.rem-height.update
        her.rem-height.update
    ?.  =(add-height 0)  state
    %=    state
        fee-rate
      fee-rate.update
    ::
        ours-pending-lock-in
      ?:  ours
        [update ours-pending-lock-in.state]
      ours-pending-lock-in.state
    ::
        hers-pending-lock-in
      ?:  ours
        hers-pending-lock-in.state
      [update hers-pending-lock-in.state]
    ==
  --
::
++  lock-in-update
  |=  [=update whose=owner next-height=commitment-number]
  ^-  update
  %=    update
      our.add-height
    ?-  whose
      %local   next-height
      %remote  our.add-height.update
    ==
  ::
      her.add-height
    ?-  whose
      %local   her.add-height.update
      %remote  next-height
    ==
  ==
::
++  apply-pending-lock-ins
  |=  state=evaluation-state
  |^  ^-  [our=update-log her=update-log]
  =+  next-height=(next-commitment-number whose.state)
  :*  our=(apply-lock-ins ours-pending-lock-in our.updates.c)
      her=(apply-lock-ins hers-pending-lock-in her.updates.c)
  ==
  ++  apply-lock-ins
    |=  [updates=(list update) log=update-log]
    ^-  update-log
    %+  roll  updates
    |:  [update=*update log=log]
    =.  update  (lock-in-update update whose.state next-height)
  --
::
++  next-commitment
  |=  $:  whose=owner
          our-index=@  our-htlc-index=@
          her-index=@  her-htlc-index=@
      ==
  ^-  commitment
  =|  =commitment
  =+  commitment-chain=(commitments-for whose)
  =+  dust-limit=dust-limit-sats:(config-for whose)
  =+  next-height=(next-commitment-number whose)
  =+  (select-updates our-index her-index)
  =+  latest=(latest-commitment whose)
  ?~  latest  !!
  =|  state=evaluation-state
  =.  state
    %=  state
      whose        whose
      our-balance  balance.our.u.latest
      her-balance  balance.her.u.latest
      fee-rate     fee.u.latest
    ==
  =.  state  (add-back-fees state)
  =.  state  (evaluate-updates ours hers state)
  =.  state  (calculate-commitment-weight state)
  =+  ^=  commitment-tx
      ^-  psbt:psbt
      %:  make-commitment-tx
        whose=whose
        local-msats=our-balance.state
        commitment-number=next-height
        feerate-per-kw=fee-rate.state
        remote-msats=her-balance.state
        local-htlcs=our-htlcs.state
        remote-htlcs=her-htlcs.state
      ==
  %=  commitment
    height  next-height
    owner   whose
    fee-per-kw  fee-rate.state
    dust-limit  dust-limit
    our     :*  msg-idx=our-index
                htlc-idx=our-htlc-index
                balance=our-balance.state
            ==
    her     :*  msg-idx=her-index
                htlc-idx=her-htlc-index
                balance=her-balance.state
  ==        ==
::
++  is-commitment-valid
  |=  $:  whose=owner
          our-index=@
          her-index=@
          our-add=(unit update)
          her-add=(unit update)
      ==
  ^-  ?
  =+  updates=(select-updates our-index her-index)
  %.n
::  +open-with-first-commitment-point: initialize channel state after opening
::
++  open-with-first-commitment-point
  |=  [=remote=point =remote=signature]
  ^-  chan
  ~|(%unimplemented !!)
::  +sign-next-commitment: create signatures for next remote commitment tx
::
++  sign-next-commitment
  ^-  (pair (pair signature (list signature)) chan)
  ~|(%unimplemented !!)
::  +receive-new-commitment: process signatures for our next local commitment
::
++  receive-new-commitment
  |=  [sig=signature htlc-sigs=(list signature)]
  ^-  chan
  ~|(%unimplemented !!)
::  +revoke-current-commitment: generate a revoke-and-ack for the current commitment
::
++  revoke-current-commitment
  ^-  (pair revoke-and-ack:msg chan)
  ~|(%unimplemented !!)
::  +receive-revocation: process a received revocation
::
++  receive-revocation
  =,  secp256k1:secp:crypto
  |=  =revoke-and-ack:msg
  ^-  chan
  ~|(%unimplemented !!)
::  +add-htlc: add a new local htlc to the channel
::
++  add-htlc
  |=  h=update-add-htlc:msg
  ^-  (pair update-add-htlc:msg chan)
  ~|  %cannot-add-htlc
  =|  update=add-htlc-update
  =.  update
    %=  update
      payment-hash  payment-hash.h
      timeout       cltv-expiry.h
      amount-msats  amount-msats.h
      index         update-count.our.updates.c
      htlc-id       htlc-count.our.updates.c
    ==
  ::  ?>  (can-add-htlc %local update)
  :-  h
  %=  c
    our.updates  (~(append-htlc log our.updates.c) [%add-htlc update])
  ==
::  +receive-htlc: add a new remote htlc to the channel
::
++  receive-htlc
  |=  h=update-add-htlc:msg
  ^-  (pair update-add-htlc:msg chan)
  ~|  %cannot-add-htlc
  ?>  =(htlc-id.h htlc-count.her.updates.c)
  =|  update=add-htlc-update
  =.  update
    %=  update
      payment-hash  payment-hash.h
      timeout       cltv-expiry.h
      amount-msats  amount-msats.h
      index         update-count.her.updates.c
      htlc-id       htlc-count.her.updates.c
    ==
  ::  ?>  (can-add-htlc %remote amount-msats.h)
  :-  h
  %=  c
    her.updates  (~(append-htlc log her.updates.c) [%add-htlc update])
  ==
::  +settle-htlc: settle/fulfill a pending received HTLC
::
++  settle-htlc
  |=  [preimage=hexb:bc =htlc-id]
  ^-  chan
  =+  htlc=(~(lookup-htlc log her.updates.c) htlc-id)
  ?~  htlc  ~|(%unknown-htlc !!)
  ?>  ?=([%add-htlc *] u.htlc)
  ::  TODO check if already settled
  ?>  =(payment-hash.u.htlc (sha256:bcu:bc preimage))
  =|  update=settle-htlc-update
  =.  update
    %=  update
      amount-msats  amount-msats.u.htlc
      preimage      preimage
      index         update-count.our.updates.c
      parent        htlc-id.u.htlc
    ==
  ::  TODO mark as settled
  c(our.updates (~(append-update log our.updates.c) [%settle-htlc update]))
::  +recive-htlc-settle: settle/fulfill a pending offered HTLC
::
++  receive-htlc-settle
  |=  [preimage=hexb:bc =htlc-id]
  ^-  chan
  =+  htlc=(~(lookup-htlc log our.updates.c) htlc-id)
  ?~  htlc  ~|(%unknown-htlc !!)
  ?>  ?=([%add-htlc *] u.htlc)
  ::  TODO check if already settled
  =|  update=settle-htlc-update
  =.  update
    %=  update
      amount-msats  amount-msats.u.htlc
      preimage      preimage
      parent        htlc-id.u.htlc
      payment-hash  payment-hash.u.htlc
      index         update-count.her.updates.c
    ==
  ::  TODO mark as settled
  c(her.updates (~(append-update log her.updates.c) [%settle-htlc update]))
::  +fail-htlc: fail a pending received HTLC
::
++  fail-htlc
  |=  =htlc-id
  ^-  chan
  =+  htlc=(~(lookup-htlc log her.updates.c) htlc-id)
  ?~  htlc  ~|(%unknown-htlc !!)
  ?>  ?=([%add-htlc *] u.htlc)
  ::  TODO check if already failed
  =|  update=fail-htlc-update
  =.  update
    %=  update
      amount-msats  amount-msats.u.htlc
      payment-hash  payment-hash.u.htlc
      parent        htlc-id.u.htlc
      index         update-count.our.updates.c
    ==
  :: TODO mark as failed
  c(our.updates (~(append-update log our.updates.c) [%fail-htlc update]))
::  +receive-fail-htlc: fail a pending offered HTLC
::
++  receive-fail-htlc
  |=  =htlc-id
  ^-  chan
  =+  htlc=(~(lookup-htlc log our.updates.c) htlc-id)
  ?~  htlc  ~|(%unknown-htlc !!)
  ?>  ?=([%add-htlc *] u.htlc)
  =|  update=fail-htlc-update
  =.  update
    %=  update
      amount-msats  amount-msats.u.htlc
      payment-hash  payment-hash.u.htlc
      parent        htlc-id.u.htlc
      index         update-count.her.updates.c
    ==
  ::  TODO mark as failed
  c(her.updates (~(append-update log her.updates.c) [%fail-htlc update]))
::  +update-fee: process a local feerate update
::
++  update-fee
  |=  feerate=sats:bc
  ^-  chan
  ?.  initiator.constraints.c
    ~|(%cannot-update-fee !!)
  =|  update=fee-update
  =.  update
    %=  update
      index     update-count.our.updates.c
      fee-rate  feerate
    ==
  c(our.updates (~(append-update log our.updates.c) [%fee-update update]))
::  +receive-update-fee: process a remote feerate update
::
++  receive-fee-update
  |=  feerate=sats:bc
  ^-  chan
  ?:  initiator.constraints.c
    ~|(%cannot-update-fee !!)
  =|  update=fee-update
  =.  update
    %=  update
      index     update-count.her.updates.c
      fee-rate  feerate
    ==
  c(her.updates (~(append-update log her.updates.c) [%fee-update update]))
::  +make-htlc-tx: construct HTLC transaction for signing
::
++  make-htlc-tx
  |=  $:  subject=owner
          commitment=psbt:psbt
          =per-commitment=point
          =commitment-number
          =direction
          htlc=update-add-htlc:msg
          output-index=@u
      ==
  ^-  psbt:psbt
  ~|(%unimplemented !!)
::  +make-commitment-tx: generate owner's commitment transaction
::
++  make-commitment-tx
  |=  $:  whose=owner
          =local=msats
          =remote=msats
          =commitment-number
          feerate-per-kw=sats:bc
          local-htlcs=(list add-htlc-update)
          remote-htlcs=(list add-htlc-update)
      ==
  ^-  psbt:psbt
  ::  %:  commitment:tx
  ::    commitment-number=commitment-number
  ::    local-funding-pubkey=0^0
  ::    remote-funding-pubkey=0^0
  ::    remote-payment-pubkey=0^0
  ::    funder-payment-basepoint=0^0
  ::    revocation-pubkey=0^0
  ::    delayed-pubkey=0^0
  ::    to-self-delay=0
  ::    funding-outpoint=[0^0 0 0]
  ::  ==
  ~|(%unimplemented !!)
::
++  make-closing-tx
  |=  $:  local-script=hexb:bc
          remote-script=hexb:bc
          =fee=sats:bc
      ==
  ^-  [tx=psbt:psbt =signature]
  ~|(%unimplemented !!)
::
++  signature-fits
  |=  tx=psbt:psbt
  ^-  ?
  ~|(%unimplemented !!)
::
++  force-close-tx
  ^-  psbt:psbt
  ~|(%unimplemented !!)
--
