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
          commit=tx:tx:psbt
          txid=hexb:bc
          secret=@
          fee=sats:bc
      ==
  ^-  hexb:bc
  ::  sweep her output with revocation
  =+  per-commitment-point=(priv-to-pub secret)
  =+  our-config=(~(config-for channel c) %local)
  =+  delay=to-self-delay:(~(config-for channel c) %remote)
  =/  her-delayed-pubkey=pubkey
    %+  derive-pubkey:keys
      pub.delayed-payment.basepoints.our-config
    per-commitment-point
  =/  our-revocation-privkey=privkey:keys
    %:  derive-revocation-privkey:keys
      pub.revocation.basepoints.our-config
      prv.revocation.basepoints.our-config
      per-commitment-point
      secret
    ==
  =+  revocation-pubkey=(priv-to-pub our-revocation-privkey)
  =/  local-witness-script=script:btc-script:script
    %^  local-output:script
        revocation-pubkey
      her-delayed-pubkey
    delay
  =+  local-address=(p2wsh:script local-witness-script)
  =/  scriptpubkeys
    (turn vout.commit |=(=out:tx:psbt script-pubkey.out))
  =+  local-idx=(find scriptpubkeys ~[local-address])
  =+  her-balance  `balance.her.commit
  =|  inputs=(list input:psbt)
  ?^  local-idx
    =|  local-input=input:psbt
    %=  local-input
      script-type     %p2wsh
      trusted-value   her-balance
      witness-script  `local-witness-script
      prevout         [txid=id idx=u.local-idx]
    ==
    =.  inputs  (snoc inputs local-input)
  same
  ::  sweep our output
  =|  remote-input=input:psbt
  =+  our-balance  `balance.our.commit
  =.  trusted-value.remote-input  our-balance
  ?.  anchor-outputs.constraints.c
    =+  remote-address=(p2wpkh:script pub.multisig-key.our-config)
    =+  remote-idx=(find scriptpubkeys ~[remote-address])
    ?^  remote-idx
      %=  remote-input
        script-type  %p2wpkh
        prevout      [txid=id idx=u.remote-idx]
      ==
      =.  inputs  (snoc inputs remote-input)
    same
  =/  remote-witness-script=script:btc-script:script
    %-  remote-output:script  pub.multisig-key.our-config
  =+  remote-address=(p2wsh:script remote-witness-script)
  =+  remote-idx=(find scriptpubkeys ~[remote-address])
  ?^  remote-idx
    %=  remote-input
      nsequence       1
      script-type     %p2wsh
      witness-script  `remote-witness-script
      prevout         [txid=id idx=u.remote-idx]
    ==
    =.  inputs  (snoc inputs remote-input)
  same
  ::  send to our localpubkey
  ::  TODO: options for sweep address
  =+  tx-fee  (mul fee 186)
  ::  base size: 31B (output) + 82B (inputs) + 6B (version, counts)
  ::  witness size: 265B
  ::  virtual size: 186vB (rounded up)
  =|  =output:psbt
  %=  output
    value          (sub (add our-balance her-balance) tx-fee)
    script-pubkey  (p2wpkh:script pub.multisig-key.our-config)
  ==
  ::  build transaction
  =|  tx=psbt:psbt
  %=  tx
    inputs    ~[local-input remote-input]
    outputs   ~[output]
    nversion  2
  ==
  ::  sign and encode
  =/  local-sig  (~(one sign:psbt tx) 0 our-revocation-privkey)
  =/  remote-sig (~(one sign:psbt tx) 1 priv.multisig-key.our-config)
  =.  closing-tx
    %:  ~(add-signature update:psbt tx)  0
      revocation-pubkey
    local-sig
  ==
  =.  closing-tx
    %:  ~(add-signature update:psbt tx)  1
      pub.multisig-key.our-config
    remote-sig
  ==
  (extract:psbt tx)
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
