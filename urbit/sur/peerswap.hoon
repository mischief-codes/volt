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
++  message
  $%
    $:  %test
        foo=@
    ==
    $:  %swap-in-request
        =protocol-version
        =swap-id
        =asset
        =network
        =scid
        amount=sats:bc
        pubkey=pubkey:bolt
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
        =protocol-version
        =swap-id
        =asset
        =network
        =scid
        amount=sats:bc
        pubkey=pubkey:bolt
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
--
