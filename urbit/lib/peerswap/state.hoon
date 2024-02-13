/-  *peerswap, bc=bitcoin
|%
:: todo: sub-cores for responder vs initiator
++  new-responder-swap-in
  |=  [req=swap-request our-pubkey=pubkey:bolt premium=sats:bc]
  ^-  swap
  =|  =swap
  %=  swap
    protocol-version  protocol-version.req
    swap-id           swap-id.req
    network           network.req
    scid              scid.req
    amount            amount.req
    our-pubkey        our-pubkey
    their-pubkey      (some pubkey.req)
    premium           (some premium)
    initiator         |
    swap-type         %swap-in
    swap-status       %awaiting-tx-open
  ==
::
++  new-responder-swap-out
  |=  [req=swap-request our-pubkey=pubkey:bolt]
  ^-  swap
  =|  =swap
  %=  swap
    protocol-version  protocol-version.req
    swap-id           swap-id.req
    network           network.req
    scid              scid.req
    amount            amount.req
    our-pubkey        our-pubkey
    their-pubkey      (some pubkey.req)
    initiator         |
    swap-type         %swap-out
    swap-status       %generating-tx-fee-payreq
  ==
::
++  new-initiator-swap
  |=  [req=swap-request =swap-type]
  ^-  swap
  =|  =swap
  %=  swap
    protocol-version  protocol-version.req
    swap-id           swap-id.req
    network           network.req
    scid              scid.req
    amount            amount.req
    our-pubkey        pubkey.req
    initiator         &
    swap-type         swap-type
    swap-status       %awaiting-agreement
  ==
::
++  add-tx-fee-payreq
  |=  [old=swap =payreq]
  ^-  swap
  %=  old
    payreq        (some payreq)
    swap-status   %awaiting-tx-fee-payment
  ==
::
++  add-swap-out-agreement
  |=  [old=swap agreement=swap-out-agreement]
  ^-  swap
  %=  old
    payreq        (some payreq.agreement)
    their-pubkey  (some pubkey.agreement)
    swap-status   %paying-tx-fee-payreq
  ==
::
++  update-swap-opening-tx-broadcasted
  |=  [old=swap msg=opening-tx-broadcasted]
  ^-  swap
  %=  old
    payreq        (some payreq.msg)
    txid          (some txid.msg)
    script-out    (some script-out.msg)
    swap-status   %awaiting-swap
  ==
--
