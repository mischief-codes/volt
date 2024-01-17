:: https://github.com/ElementsProject/peerswap/blob/master/docs/peer-protocol.md
/-  bc=bitcoin, bolt
|%
+$  protocol-version  @u
+$  asset             (unit @t)  :: only used for Liquid Network
+$  swap-id           @t
+$  scid              @ud
+$  payreq            @t
+$  txid              hexb:bc
+$  network
  $~  %liquid
  $?  %liquid
      %mainnet
      %testnet
      %signet
  ==
+$  swap-request
  $:  =swap-id
      =asset
      =network
      =scid
      amount=sats:bc
      pubkey=pubkey:bolt
==
++  message
  $%
    $:  %test
        foo=@
    ==
    $:  %swap-in-request
        =swap-request
    ==
  ::
    $:  %swap-in-agreement
        =protocol-version
        =swap-id
        pubkey=pubkey:bolt
        premium=sats:bc
    ==
  ::
    $:  %swap-out-request
        =swap-request
    ==
  ::
    $:  %swap-out-agreement
        =protocol-version
        =swap-id
        pubkey=pubkey:bolt
        premium=sats:bc
    ==
  ::
    $:  %opening-tx-broadcasted
        =swap-id
        =payreq
        =txid
        script-out=@
        blinding-key=(unit @)  :: only used for Liquid Network
    ==
  ::
    $:  %cancel
        =swap-id
        message=@t
    ==
  ::
    $:  %coop-close
        =swap-id
        message=@t
        privkey=privkey:bolt
    ==
  ==
  ++  command
  $%
    $:  %request-swap-in
        ship=@p
        =network
        amount=sats:bc
    ==
    $:  %request-swap-out
        ship=@p
        =network
        amount=sats:bc
    ==
  ==
--
