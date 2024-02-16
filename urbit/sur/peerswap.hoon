:: https://github.com/ElementsProject/peerswap/blob/master/docs/peer-protocol.md
/-  bc=bitcoin, bolt, volt
|%
+$  protocol-version  @u
+$  asset             (unit @t)  :: only used for Liquid Network
+$  swap-id           @
+$  payreq            payreq:volt
+$  txid              hexb:bc
+$  scid              scid:volt
+$  network  ?(%liquid %mainnet %testnet %signet)
+$  status
  $?  %awaiting-agreement
  :: I think if the state is ever updated for this one, it has succeded?
  %generating-tx-fee-payreq
  :: same as ^^
  %paying-tx-fee-payreq
  %awaiting-tx-fee-payment
  %awaiting-tx-open
  %awaiting-fee-invoice
  %awaiting-fee-invoice-payment
  %awaiting-swap
==
+$  swap-type  ?(%swap-in %swap-out)
+$  swap-params  [ship=@p =network =sats:bc]
+$  swap  $:
    =protocol-version
    =swap-id
    =asset
    =network
    =scid
    amount=sats:bc
    our-pubkey=pubkey:bolt
    their-pubkey=(unit pubkey:bolt)
    premium=(unit sats:bc)
    payreq=(unit payreq)
    initiator=?
    =swap-type
    =status
    txid=(unit txid)
    script-out=(unit @)
    cancel-message=(unit @t)
    coop-close-message=(unit @t)
    coop-close-privkey=(unit privkey:bolt)
==
+$  swap-request
  $:  =protocol-version
      =swap-id
      =asset
      =network
      =scid
      amount=sats:bc
      pubkey=pubkey:bolt
==
+$  swap-in-agreement
  $:  =protocol-version
      =swap-id
      pubkey=pubkey:bolt
      premium=sats:bc
==
+$  swap-out-agreement
  $:  =protocol-version
      =swap-id
      pubkey=pubkey:bolt
      payreq=payreq:volt
==
+$  opening-tx-broadcasted
  $:  =swap-id
      =payreq
      =txid
      script-out=@
      blinding-key=(unit @)  :: only used for Liquid Network
==
++  thread-type
  $?
    %get-opening-tx-fee-payreq
    %pay-opening-tx-fee-payreq
  ==
++  message
  $%
    $:(%swap-in-request =swap-request)
    $:(%swap-in-agreement =swap-in-agreement)
    $:(%swap-out-request =swap-request)
    $:(%swap-out-agreement =swap-out-agreement)
    $:(%opening-tx-broadcasted =opening-tx-broadcasted)
    $:(%cancel =swap-id message=@t)
    $:(%coop-close =swap-id message=@t privkey=privkey:bolt)
  ==
  ++  command
  $%
    $:(%request-swap-in =swap-params)
    $:(%request-swap-out =swap-params)
    $:(%debug-print swap-id=(unit swap-id) all=?)
  ==
--
