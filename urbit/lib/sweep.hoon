/-  *bolt, bc=bitcoin
/+  psbt, channel, script
/+  keys=key-generation, tx=transactions
|%
:: notes
  :: don't necessarily need to move to the next commitment after every HTLC, could set timer to update periodically instead
  :: use encode (extract-unsigned) or en to get tx to broadcast
  :: could map/search by commitment height (encoded in nlocktime) instead of tx byts
::  +sweep-her-revoked-commitment:
::
++  sweep-her-revoked-balances
  =,  secp256k1:secp:crypto
  |=  $:  c=chan
          commit=commitment
          txid=hexb:bc
          secret=@
          fee=sats:bc
      ==
  |^  ^-  hexb:bc
  ::  sweep her output with revocation
  =+  per-commit=(priv-to-pub secret)
  =+  our-config=(~(config-for channel c) %local)
  =+  delay=to-self-delay:(~(config-for channel c) %remote)
  =/  her-delayed-pubkey=pubkey
    %+  derive-pubkey:keys
      pub.delayed-payment.basepoints.our-config
    per-commit
  =/  rev-priv=privkey:keys
    %:  derive-revocation-privkey:keys
      pub.revocation.basepoints.our-config
      prv.revocation.basepoints.our-config
      per-commit
      secret
    ==
  =+  rev-pub=(priv-to-pub rev-priv)
  =/  local-witness=script:btc-script:script
    %^  local-output:script
        rev-pub
      her-delayed-pubkey
    delay
  =/  scriptpubkeys=(list hexb:bc)
    (turn vout.tx.commit |=(=out:tx:psbt script-pubkey.out))
  =+  her-bal=balance.her.commit
  =|  inputs=(list input:psbt)
  =.  inputs
    %:  maybe-add-remote
      her-bal
      txid
      scriptpubkeys
      local-witness
    ==
  ::  sweep our output
  =+  our-bal=balance.our.commit
  =+  localpub=pub.multisig-key.our-config
  =+  anchors=anchor-outputs.constraints.c
  =.  inputs
    %:  maybe-add-local
      our-bal
      txid
      scriptpubkeys
      localpub
      inputs
      anchors
    ==
  ::  send to our localpubkey
  ::  TODO: options for sweep address
  =|  =output:psbt
  =+  tx-fee=(mul fee 186)
  ::  base size: 31B (output) + 82B (inputs) + 6B (version, counts)
  ::  witness size: 265B
  ::  virtual size: 186vB (rounded up)
  =.  value.output  (sub (add our-bal her-bal) tx-fee)
  =.  script-pubkey.output  (p2wpkh:script localpub)
  ::  build transaction
  =|  tx=psbt:psbt
  =.  tx
    %=  tx
      inputs    inputs
      outputs   ~[output]
      nversion  2
    ==
  ::  sign and encode
  =/  local-sig   (~(one sign:psbt tx) 0 rev-priv ~)
  =/  remote-sig  (~(one sign:psbt tx) 1 priv.multisig-key.our-config ~)
  =.  tx
    %:  ~(add-signature update:psbt tx)  0
      rev-pub
    local-sig
    ==
  =.  tx
    %:  ~(add-signature update:psbt tx)  1
      localpub
    remote-sig
    ==
  (extract:psbt sweep-tx)
  ++  maybe-add-remote
    |=  $:  bal=sats:bc
            id=hexb:bc
            keys=(list hexb:bc)
            wit=script:btc-script:script
        ==
    ^-  (list input:psbt)
    =+  addr=(p2wsh:script wit)
    =+  idx=(find keys ~[addr])
    =|  =input:psbt
    ?~  idx
      ~
    =+  wit-byts=(en:btc-script:script wit)
    :~
      %=  input
        script-type     %p2wsh
        trusted-value   `bal
        witness-script  `wit-byts
        prevout         [txid=id idx=u.idx]
      ==
    ==
  ++  maybe-add-local
    |=  $:  bal=sats:bc
            id=hexb:bc
            keys=(list hexb:bc)
            pub=pubkey
            in=(list input:psbt)
            anchors=?
        ==
    ^-  (list input:psbt)
    =/  anchor-script
      (remote-output:script pub)
    =/  addr  ?.  anchors
      (p2wpkh:script pub)
    (p2wsh:script anchor-script)
    =+  idx=(find keys ~[addr])
    ?~  idx
      in
    =|  =input:psbt
    =.  trusted-balance.input  `bal
    =.  prevout.input  [txid=id idx=u.idx]
    %+  snoc  inputs
      ?.  anchors
        =.  script-type.input  %p2wpkh  
        input
      =/  wit-byts
        (en:btc-script:script anchor-script)
      %=  input
        nsequence       1
        script-type     %p2wsh
        witness-script  `wit-byts
      ==
  --
::
++  sweep-her-revoked-htlc
  |=  $:  c=chan
          commit=tx:tx:psbt
      ==
  ^-  psbt:psbt
  *psbt:psbt
  ::  check for sent and recd htlcs
  ::  get indices from update
  ::  sweep all with revocation sig
::
++  sweep-our-commitment
  |=  $:  c=chan
      ==
  ^-  psbt:psbt
  *psbt:psbt
::
--
