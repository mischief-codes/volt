/-  *bolt, bc=bitcoin
/+  psbt, channel, script
/+  keys=key-generation, tx=transactions
|%
:: notes
  :: don't necessarily need to move to the next commitment after every HTLC, could set timer to update periodically instead
  :: could map/search by commitment height (encoded in nlocktime) instead of tx byts
::
++  revoked-commitment
  =,  secp256k1:secp:crypto
  |=  $:  c=chan
          commit=commitment
          txid=hexb:bc
          fee=sats:bc
      ==
  |^  ^-  (list psbt:psbt)
  =+  secret=(~(got by lookup.commitments.c) commit)
  ::  sweep her output with revocation
  =+  per-commit=(priv-to-pub secret)
  =+  our-config=(~(config-for channel c) %local)
  =+  her-config=(~(config-for channel c) %remote)
  =+  delay=to-self-delay:her-config
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
  =^  has-local  inputs
    %:  maybe-add-local
      her-bal
      txid
      scriptpubkeys
      local-witness
    ==
  ::  sweep our output
  =+  our-bal=balance.our.commit
  =+  localpub=pub.multisig-key.our-config
  =+  anchors=anchor-outputs.constraints.c
  =^  has-remote  inputs
    %:  maybe-add-remote
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
  =|  val=sats:bc
  =?  val  has-local  (add val her-bal)
  =?  val  has-remote  (add val our-bal)
  =.  value.output  (sub val tx-fee)
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
  =+  xrprv=(priv-to-hexb:keys rev-priv)
  =?  tx  has-local
    %^  ~(add-signature update:psbt tx)
        0
      rev-pub
    %^  ~(one sign:psbt tx)
        0
      xrprv
    ~
  =?  tx  has-remote
    =/  remote-idx  ?:  has-local  1  0
    %^  ~(add-signature update:psbt tx)
        remote-idx
      localpub
    %^  ~(one sign:psbt tx)
        remote-idx
      (priv-to-hexb:keys prv.multisig-key.our-config)
    ~
  =+  txs=~[tx]
  ?:  ?&(=(0 (lent sent-htlcs.commit)) =(0 (lent recd-htlcs.commit)))
    txs
  (weld txs (revoke-htlc-outs rev-pub xrprv))
  ::
  ++  maybe-add-local
    |=  $:  bal=sats:bc
            id=hexb:bc
            keys=(list hexb:bc)
            wit=script:btc-script:script
        ==
    ^-  [? (list input:psbt)]
    =+  addr=(p2wsh:script wit)
    =+  idx=(find keys ~[addr])
    =|  =input:psbt
    ?~  idx
      [%.n ~]
    =+  wit-byts=(en:btc-script:script wit)
    :-  %.y
    :~  %=  input
          script-type     %p2wsh
          trusted-value   `bal
          witness-script  `wit-byts
          prevout         [txid=id idx=u.idx]
    ==  ==
  ::
  ++  maybe-add-remote
    |=  $:  bal=sats:bc
            id=hexb:bc
            keys=(list hexb:bc)
            pub=pubkey
            in=(list input:psbt)
            anchors=?
        ==
    ^-  [? (list input:psbt)]
    =/  anchor-script
      (remote-output:script pub)
    =/  addr  ?.  anchors
      (p2wpkh:script pub)
    (p2wsh:script anchor-script)
    =+  idx=(find keys ~[addr])
    =|  =input:psbt
    ?~  idx
      [%.n in]
    =.  trusted-value.input  `bal
    =.  prevout.input  [txid=id idx=u.idx]
    :-  %.y
    %+  snoc  in
      ?.  anchors
        input(script-type %p2wpkh)
      =+  wit-byts=(en:btc-script:script anchor-script)
      %=  input
        nsequence       1
        script-type     %p2wsh
        witness-script  `wit-byts
      ==
  ::
  ++  revoke-htlc-outs
    ::  refactor to be less duplicative
    |=  [rpub=pubkey rprv=hexb:bc]
    ^-  (list psbt:psbt)
    =/  our=(list psbt:psbt)
      %+  turn  sent-htlcs.commit
      |=  htlc=add-htlc-update
      =|  =input:psbt
      =+  val=(div amount-msats.htlc 1.000)
      =/  wit
        %:  htlc-witness:script
          %sent
          pub.htlc.basepoints.our.config.c
          pub.htlc.basepoints.her.config.c
          rpub
          payment-hash.htlc
          ~
          anchor-outputs.our.config.c
        ==
      =?  nsequence.input
        anchor-outputs.our.config.c
      1
      =.  input
        %=  input
          script-type     %p2wsh
          prevout         [txid output-index.htlc]
          trusted-value   `val
          witness-script  `(en:btc-script:script wit)
        ==
      =|  =output:psbt
      =.  value.output  (sub val fee) ::  TODO fee calc
      =.  script-pubkey.output
        (p2wpkh:script pub.multisig-key.our.config.c)
      =|  tx=psbt:psbt
      =.  tx
        %=  tx
          nversion  2
          inputs    ~[input]
          outputs   ~[output]
        ==
      %^  ~(add-signature update:psbt tx)
          0
        rpub
      %^  ~(one sign:psbt tx)
          0
        rprv
      ~
    =/  his=(list psbt:psbt)
      %+  turn  recd-htlcs.commit
      |=  htlc=add-htlc-update
      =|  =input:psbt
      =+  val=(div amount-msats.htlc 1.000)
      =/  wit
        %:  htlc-witness:script
          %received
          pub.htlc.basepoints.our.config.c
          pub.htlc.basepoints.her.config.c
          rpub
          payment-hash.htlc
          `timeout.htlc
          anchor-outputs.our.config.c
        ==
      =?  nsequence.input
        anchor-outputs.our.config.c
      1
      =.  input  
        %=  input
          script-type     %p2wsh
          prevout         [txid output-index.htlc]
          trusted-value   `val
          witness-script  `(en:btc-script:script wit)
        ==
      =|  =output:psbt
      =.  value.output  (sub val fee) ::  TODO fee calc
      =.  script-pubkey.output
        (p2wpkh:script pub.multisig-key.our.config.c)
      =|  tx=psbt:psbt
      =.  tx
        %=  tx
          nversion  2
          inputs    ~[input]
          outputs   ~[output]
        ==
      %^  ~(add-signature update:psbt tx)
          0
        rpub
      %^  ~(one sign:psbt tx)
          0
        rprv
      ~
    %+  weld  our  his      
  --
::
++  revoked-htlc-spend
  =,  secp256k1:secp:crypto
  |=  $:  c=chan
          secret=@
          val=sats:bc
          txid=hexb:bc
          fee=sats:bc
      ==
  ^-  psbt:psbt
  =+  per-commit=(priv-to-pub secret)
  =+  our-config=(~(config-for channel c) %local)
  =+  her-config=(~(config-for channel c) %remote)
  =+  delay=to-self-delay.her-config
  =/  her-pub=pubkey
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
  =/  witness=script:btc-script:script
    %^  htlc-spend:script
        rev-pub
      her-pub
    delay
  =|  =input:psbt
  =.  input
    %=  input
      script-type     %p2wsh
      prevout         [txid 0]
      trusted-value   `val
      witness-script  `(en:btc-script:script witness)
    ==
  =|  =output:psbt
  =.  output
    %=  output
      ::  fee calc: base size 74B + witness 156B => 113vB
      ::  TODO: double check this calc
      ::  TODO: branch calc based on anchor outputs?
      value          (sub val (mul fee 113))
      script-pubkey  (p2wpkh:script pub.multisig-key.our-config)
    ==
  =|  sweep=psbt:psbt
  =.  sweep
    %=  sweep
      inputs    ~[input]
      outputs   ~[output]
      nversion  2
    ==
  %^  ~(add-signature update:psbt sweep)
      0
    rev-pub
  %^  ~(one sign:psbt sweep)
      0
    (priv-to-hexb:keys rev-priv)
  ~
::
++  his-valid-commitment
  |=  $:  c=chan
          com=commitment
          secrets=(map hexb:bc hexb:bc)
          fee=sats:bc
          txid=hexb:bc
      ==
  ^-  psbt:psbt
  ?~  recd-htlcs.com
    *psbt:psbt
  ::  TODO: keep payment preimages map current (shift spent preimages to another piece of state) to optimize this search
  =|  sweep=psbt:psbt
  =|  =output:psbt
  =|  preimages=(list hexb:bc)
  =.  script-pubkey.output
    (p2wpkh:script pub.multisig-key.our-config)
  =/  to-spend=(list [input:psbt hexb:bc])
    %+  murn  recd-htlc.com
    |=  msg=add-htlc-update
    =+  preimage=(~(get by secrets) payment-hash.msg)
    ?~  preimage
      ~
    =/  witness=hexb:bc
      %-  en:btc-script:script
      %:  htlc-offered:script
        pub.htlc.basepoints.our.config.c
        pub.htlc.basepoints.her.config.c
        pub.revocation.basepoints.our.config.c
        payment-hash.msg
        anchor-outputs.our.config.c
      ==
    =+  amount-sats=(msats-to-sats amount-msats.msg)
    =|  =input:psbt
    :_  preimage
    %=  input
      script-type           %p2wsh
      witness-script        `witness
      trusted-value         `amount-sats
      prevout               [txid output-index.msg]
    ==
  =.  inputs.sweep  (turn to-spend |=([i=input:psbt hexb:bc] i))
  =+  total-value=(roll (turn inputs.sweep |=(i=input:psbt trusted-value.i) add)
  ::  per input: 41 base + 240 witness => 101vB
  ::  other: 39 base + 2 witness => 40vB
  :: =+  vbytes=(add 40 (mul 101 (lent inputs.sweep)))
  =+  n-in=(lent inputs.sweep)
  =.  value.output  total-value
  =.  outputs.sweep  ~[output]
  ::  one sig and one preimage per input + current estimated size
  =+  vbytes=(add (mul n-in 66) (estimated-size:psbt sweep))
  =.  value.output  (sub total-value (mul fee vbytes))
  =.  outputs.sweep  ~[output]
  =+  i=0
  |-
  ?:  =(i n-in)
    (extract:psbt sweep)
  =.  sweep
    %^  ~(add-signature update:psbt sweep)
        i
      pub.htlc.basepoints.our.config.c
    %^  ~(one sign:psbt sweep)
        i
      (priv-to-hexb:keys prv.htlc.basepoints.our.config.c
    ~
  =+  f-in=~(finalize txin:psbt (snag i inputs.sweep)))
  =.  inputs.sweep
    %^  snap
        inputs.sweep
      i
    %=  f-in
      final-script-witness  `(into final-script-witness 2 +.(snag i to-spend))
    ==
  $(i +(i))
::
++  timeout-his-recd-htlc
  |=  $:  c=chan
          com=commitment
          msg=add-htlc-update
      ==
  ^-  psbt:psbt
  =|  =input:psbt
  =/  witness=hexb:bc
    %-  en:btc-script:script
    %:  htlc-received:script
      pub.htlc.basepoints.our.config.c
      pub.htlc.basepoints.her.config.c
      pub.revocation.basepoints.our.config.c
      payment-hash.msg
      timeout.msg
      anchor-outputs.our.config.c
    ==
  =+  amount-sats=(msats-to-sats amount-msats.msg)
  =+  outpoint=[(txid:psbt (extract-unsigned:psbt tx.com)) output-index.msg]
  =.  input
    %=  input
      script-type     %p2wsh
      trusted-value   `amount-sats
      witness-script  `witness
      prevout         outpoint
    ==
  =|  =output:psbt
  =.  output.script-pubkey  (p2wpkh:script pub.multisig-key.our-config)
  =.  output.value  `amount-sats
  =|  sweep=psbt:psbt
  %=  sweep
    inputs   ~[input]
    outputs  ~[output]
  ==
::
++  our-force-close
  |=  $:  c=chan
          com=commitment
          fee=sats:bc
      ==
  ^-  (pair (list psbt:psbt) (list hexb:bc))
  *(pair (list psbt:psbt) (list hexb:bc))
--
