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
++  sweep-her-revoked-commitment
  =,  secp256k1:secp:crypto
  |=  $:  c=chan
          commit=tx:tx:psbt
          txid=hexb:bc
          secret=@
          =sweep=address:bc
          fee=sats:bc
      ==
  ^-  (unit psbt:psbt)
  =+  per-commitment-point=(priv-to-pub secret)
  =+  our-config=(~(config-for channel c) %local)
  =+  her-config=(~(config-for channel c) %remote)
  =+  to-self-delay=to-self-delay.her-config
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
    %:  local-output:script
      revocation-pubkey
      her-delayed-pubkey
      to-self-delay
    ==
  =+  local-address=(p2wsh:script local-witness-script)
  =/  scriptpubkeys
    (turn vout.commit |=(=out:tx:psbt script-pubkey.out))
  =+  local-idx=u:(find scriptpubkeys ~[local-address])
  =+  her-balance  `balance.her.commit
  =+  our-balance  `balance.our.commit
  =|  local-input=input:psbt
  %=  local-input
    prevout         [txid=id idx=local-idx]
    witness-script  `local-witness-script
    trusted-value   her-balance
    script-type     %p2wsh
  ==
  =|  remote-input=input:psbt
  =.  trusted-value.remote-input  our-balance
  ?.  anchor-outputs.constraints.c
    =+  remote-address=(p2wpkh:script pub.multisig-key.our-config)
    =+  remote-idx=u:(find scriptpubkeys ~[remote-address])
    %=  remote-input
      script-type  %p2wpkh
      prevout      [txid=id idx=remote-idx]
    ==
  =/  remote-witness-script=script:btc-script:script
    %-  remote-output:script  pub.multisig-key.our-config
  =+  remote-address=(p2wsh:script remote-witness-script)
  =+  remote-idx=u:(find scriptpubkeys ~[remote-address])
  %=  remote-input
    nsequence       1
    script-type     %p2wsh
    witness-script  `remote-witness-script
    prevout         [txid=id idx=remote-idx]
  ==
  =|  =output:psbt
  %=  output
    script-pubkey  ~ ::  TODO: destination for swept funds
    value          (sub (add our-balance her-balance) fee)
    ::  witness script?
  ==
  =|  tx=psbt:psbt
  %=  tx
    inputs   ~[local-input remote-input]
    outputs  
  
  ==
  ::  sign and encode
  tx
::  +sweep-her-revoked-htlc:
::
++  sweep-her-revoked-htlc
  |=  $:  c=chan
          commit=tx:tx:psbt
      ==
  ^-  psbt:psbt
  *psbt:psbt
::  +sweep-our-commitment:
::
++  sweep-our-commitment
  |=  $:  c=chan
      ==
  ^-  psbt:psbt
  *psbt:psbt
::
--
