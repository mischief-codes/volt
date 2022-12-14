/-  *bolt, bc=bitcoin
/+  psbt, channel, script
/+  keys=key-generation, tx=transactions
|%
::  +sweep-her-revoked-commitment:
::
++  sweep-her-revoked-commitment
  =,  secp256k1:secp:crypto
  |=  $:  c=chan
          commit=tx:tx:psbt
          secret=@
          =sweep=address:bc
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
  =/  witness-script=script:btc-script:script
    %:  local-output:script
      revocation-pubkey
      her-delayed-pubkey
      to-self-delay
    ==
  =+  local-address=(p2wsh:script witness-script)
  =+  output-indexes=~
  :: notes
  :: don't necessarily need to move to the next commitment after every HTLC, could set timer to update periodically instead
  :: use encode (extract-unsigned) or en to get tx to broadcast
  ~
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
