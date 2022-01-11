::  bolt.hoon
::  Library functions to implement Lightning BOLT RFCs.
::
/-  *bolt
/+  bc=bitcoin, btc-script=bolt-script, bolt11=bolt-bolt11
/+  bip32, der, psbt
|%
++  bcu  bcu:bc
::
++  anchor-size           330
++  anchor-output-weight  3
++  commitment-tx-weight  724
++  htlc-success-weight   703
++  htlc-timeout-weight   663
++  htlc-output-weight    172
::
++  mainnet-hash
  ^-  hexb:bc
  32^0x19.d668.9c08.5ae1.6583.1e93.4ff7.63ae.46a2.a6c1.72b3.f1b6.0a8c.e26f
::
++  testnet-hash
  ^-  hexb:bc
  32^0x933.ea01.ad0e.e984.2097.79ba.aec3.ced9.0fa3.f408.7195.26f8.d77f.4943
::
++  regtest-hash
  ^-  hexb:bc
  32^0xf91.88f1.3cb7.b2c7.1f2a.335e.3a4f.c328.bf5b.eb43.6012.afca.590b.1a11.466e.2206
::
++  network-chain-hashes
  ^-  (map network hexb:bc)
  %-  malt
  ^-  (list (pair network hexb:bc))
  :~  [%main mainnet-hash]
      [%testnet testnet-hash]
      [%regtest regtest-hash]
  ==
::
++  chain-hash-networks
  ^-  (map hexb:bc network)
  %-  malt
  ^-  (list (pair hexb:bc network))
  :~  [mainnet-hash %main]
      [testnet-hash %testnet]
      [regtest-hash %regtest]
  ==
::
++  network-chain-hash
  |=  =network
  ^-  hexb:bc
  ?.  (~(has by network-chain-hashes) network)
    ~|(%unknown-network !!)
  (~(got by network-chain-hashes) network)
::
++  chain-hash-network
  |=  chain-hash=hexb:bc
  ^-  network
  ?.  (~(has by chain-hash-networks) chain-hash)
    ~|(%unknown-network !!)
  (~(got by chain-hash-networks) chain-hash)
::
++  msats-to-sats
  |=  a=msats
  ^-  sats:bc
  (div a 1.000)
::
++  sats-to-msats
  |=  a=sats:bc
  ^-  msats
  (mul a 1.000)
::
++  bech32-encode
  |=  [=network =hexb:bc]
  ^-  (unit cord)
  =+  prefix=(~(get by prefixes:bolt11) network)
  ?~  prefix  ~
  %-  some
  %+  encode-raw:bech32:bolt11  u.prefix
  :-  0v0
  %+  to-atoms:bit:bcu  5
  %+  pad-bits:bolt11   5
  (bytes-to-bits:bolt11 hexb)
::
++  bech32-decode
  |=  =cord
  ^-  hexb:bc
  (from-address:bech32:bolt11 cord)
::
++  make-channel-id
  |=  [funding-txid=hexb:bc funding-output-index=@ud]
  ^-  id
  (mix dat.funding-txid funding-output-index)
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
++  fee-by-weight
  |=  [feerate-per-kw=@ud weight=@ud]
  ^-  sats:bc
  (div (mul weight feerate-per-kw) 1.000)
::
++  received-htlc-trim-threshold
  |=  [=dust-limit=sats:bc feerate=sats:bc anchor=?]
  ^-  sats:bc
  =+  weight=htlc-success-weight
  =?  weight  anchor  (add weight 3)
  %+  add  dust-limit-sats
  (fee-by-weight feerate weight)
::
++  offered-htlc-trim-threshold
  |=  [=dust-limit=sats:bc feerate=sats:bc anchor=?]
  ^-  sats:bc
  =+  weight=htlc-timeout-weight
  =?  weight  anchor  (add weight 3)
  %+  add  dust-limit-sats
  (fee-by-weight feerate weight)
::
++  fee-for-htlc-output
  |=  feerate=sats:bc
  ^-  sats:bc
  (fee-by-weight feerate htlc-output-weight)
::
++  is-trimmed
  |=  [=direction h=update-add-htlc:msg feerate=sats:bc =dust-limit=sats:bc anchor=?]
  |^  ^-  ?
  (lth (msats-to-sats amount-msats.h) threshold)
  ++  threshold
    ^-  sats:bc
    ?-    direction
        %sent
      (offered-htlc-trim-threshold dust-limit-sats feerate anchor)
    ::
        %received
      (received-htlc-trim-threshold dust-limit-sats feerate anchor)
    ==
  --
::
++  commitment-fee
  |=  $:  num-htlcs=@ud
          feerate=sats:bc
          is-local-initiator=?
          anchors=?
          round=?
      ==
  ^-  (map owner sats:bc)
  =+  overall=(add commitment-tx-weight (mul num-htlcs htlc-output-weight))
  =?  overall  anchors
    (add overall 400)
  =+  fee=(fee-by-weight feerate overall)
  =?  fee  anchors
    (add fee 660)
  =?  fee  round
    (mul (div fee 1.000) 1.000)
  %-  malt
  %-  limo
  :~  [%local ?:(is-local-initiator fee 0)]
      [%remote ?.(is-local-initiator fee 0)]
  ==
::
++  commitment-number-blinding-factor
  =,  secp256k1:secp:crypto
  |=  [oc=point ac=point]
  ^-  hexb:bc
  %+  drop:byt:bcu  26
  %-  sha256:bcu
  %-  cat:byt:bcu
  :~  33^(compress-point oc)
      33^(compress-point ac)
  ==
::
++  obscure-commitment-number
  |=  [cn=commitment-number oc=point ac=point]
  ^-  @ud
  %+  mix
    dat:(commitment-number-blinding-factor oc ac)
  (abs:si cn)
::
++  unobscure-commitment-number
  |=  [a=@ud oc=point ac=point]
  ^-  commitment-number
  %+  mix
    (sun:si dat:(commitment-number-blinding-factor oc ac))
  a
::
++  invert-owner
  |=  o=owner
  ^-  owner
  ?-  o
    %local   %remote
    %remote  %local
  ==
::
++  htlc-sum
  |=  hs=(list update-add-htlc:msg)
  ^-  msats
  %+  roll  hs
  |=  [h=update-add-htlc:msg sum=msats]
  (add sum amount-msats.h)
::  +tx: transaction generation
::
++  tx
  |%
  ::  +tx:funding-output: generate multisig output
  ::
  ++  funding-output
    |=  [=local=pubkey =remote=pubkey =funding=sats:bc]
    |^  ^-  output:psbt
    =|  =output:psbt
    %=  output
      script-pubkey  script-pubkey
      value          funding-sats
    ==
    ++  script-pubkey
      =,  secp256k1:secp:crypto
      %-  p2wsh:script
      %+  funding-output:script
        local-pubkey
      remote-pubkey
    --
  ::  +tx:funding-input: generate spend from multisig output
  ::
  ++  funding-input
      =,  secp256k1:secp:crypto
    |=  $:  =local-funding=pubkey
            =remote-funding=pubkey
            =funding=outpoint
            sequence=@
        ==
    |^  ^-  input:psbt
    =|  =input:psbt
    %=  input
      prevout         [txid=txid.funding-outpoint idx=pos.funding-outpoint]
      nsequence       sequence
      witness-script  `witness-script
      trusted-value   `sats.funding-outpoint
      script-type     %p2wsh
      num-sigs        2
      pubkeys
        %+  sort  ~[local-funding-pubkey remote-funding-pubkey]
        |=  [a=pubkey b=pubkey]
        (lte (compress-point a) (compress-point b))
    ==
    ++  witness-script
      %-  en:btc-script
      %+  funding-output:script
        local-funding-pubkey
      remote-funding-pubkey
    --
  ::  +tx:commitment-outputs: outputs for commitment tx
  ::
  ++  commitment-outputs
    |=  $:  fees-per-participant=(map owner sats:bc)
            =local-funding=pubkey
            =remote-funding=pubkey
            =local-amount=msats
            =remote-amount=msats
            local-script=hexb:bc
            remote-script=hexb:bc
            htlcs=(list ^htlc)
            =dust-limit=sats:bc
            anchor=?
        ==
    |^  ^-  (list output:psbt)
    %+  turn  (sort-outputs:bip69-cltv outputs cltvs)
    |=  =out:tx:psbt
    (from-output:txout:psbt out)
    ++  local-fee
      ^-  sats:bc
      (~(gut by fees-per-participant) %local 0)
    ::
    ++  remote-fee
      ^-  sats:bc
      (~(gut by fees-per-participant) %remote 0)
    ::
    ++  to-local-amount
      ^-  sats:bc
      =+  amount=(msats-to-sats local-amount-msats)
      ?:  (gth local-fee amount)
        0
      (sub amount local-fee)
    ::
    ++  to-remote-amount
      ^-  sats:bc
      =+  amount=(msats-to-sats remote-amount-msats)
      ?:  (gth remote-fee amount)
        0
      (sub amount remote-fee)
    ::
    ++  to-local
      ^-  out:tx:psbt
      =|  =out:tx:psbt
      out(script-pubkey local-script, value to-local-amount)
    ::
    ++  to-remote
      ^-  out:tx:psbt
      =|  =out:tx:psbt
      out(script-pubkey remote-script, value to-remote-amount)
    ::
    ++  htlc-outputs
      ^-  (list out:tx:psbt)
      (turn htlcs htlc-output)
    ::
    ++  anchor-outputs
      ^-  (list out:tx:psbt)
      ?.  anchor  ~
      %-  zing
      :~
        ?:  (gte to-local-amount dust-limit-sats)
          ~[(anchor-output local-funding-pubkey)]
        ~
        ::
        ?:  (gte to-remote-amount dust-limit-sats)
          ~[(anchor-output remote-funding-pubkey)]
        ~
      ==
    ::
    ++  cltvs
      ^-  (list blocks)
      %-  zing
      :~
        ?:  (gte to-local-amount dust-limit-sats)
          ~[0]
        ~
        ::
        ?:  (gte to-remote-amount dust-limit-sats)
          ~[0]
        ~
        ::
        %+  turn    htlcs
        |=  h=^htlc  cltv-expiry.h
        ::
        %+  turn    anchor-outputs
        |=  =out:tx:psbt  0
      ==
    ::
    ++  outputs
      ^-  (list out:tx:psbt)
      %-  zing
      :~
        htlc-outputs
        ?:  (gte to-local-amount dust-limit-sats)
          ~[to-local]
        ~
        ?:  (gte to-remote-amount dust-limit-sats)
          ~[to-remote]
        ~
        anchor-outputs
      ==
    --
  ::  +tx:commitment: generate commitment transaction
  ::
  ++  commitment
    |=  $:  =commitment-number
            =local-funding=pubkey
            =remote-funding=pubkey
            =remote-payment=pubkey
            funder-payment-basepoint=point
            fundee-payment-basepoint=point
            =revocation=pubkey
            =delayed=pubkey
            to-self-delay=blocks
            =funding=outpoint
            local-amount=msats
            remote-amount=msats
            =dust-limit=sats:bc
            anchor-outputs=?
            htlcs=(list ^htlc)
            fees-per-participant=(map owner sats:bc)
        ==
    |^  ^-  psbt:psbt
    =|  =psbt:psbt
    %=  psbt
      inputs     ~[input]
      outputs    outputs
      nversion   2
      nlocktime  locktime
    ==
    ++  obscured-commitment-number
      ^-  @ud
      %^    obscure-commitment-number
          commitment-number
        funder-payment-basepoint
      fundee-payment-basepoint
    ::
    ++  locktime
      ^-  @ud
      %+  con  (lsh [3 3] 0x20)
      (dis 0xff.ffff obscured-commitment-number)
    ::
    ++  sequence
      ^-  @
      %+  con  (lsh [3 3] 0x80)
      %+  rsh  [3 3]
      (dis 0xffff.ff00.0000 obscured-commitment-number)
    ::
    ++  input
      %:  funding-input
        local-funding-pubkey
        remote-funding-pubkey
        funding-outpoint
        sequence
      ==
    ::
    ++  outputs
      ^-  (list output:psbt)
      %:  commitment-outputs
        fees-per-participant=fees-per-participant
        local-funding-pubkey=local-funding-pubkey
        remote-funding-pubkey=remote-funding-pubkey
        local-amount-msats=local-amount
        remote-amount-msats=remote-amount
        local-script=local-script
        remote-script=remote-script
        htlcs=htlcs
        dust-limit-sats=dust-limit-sats
        anchor=anchor-outputs
      ==
    ::
    ++  local-script
      ^-  hexb:bc
      %-  p2wsh:script
      %^    local-output:script
          revocation-pubkey
        delayed-pubkey
      to-self-delay
    ::
    ++  remote-script
      ^-  hexb:bc
      ?:  anchor-outputs
        %-  p2wsh:script
        (remote-output:script remote-payment-pubkey)
      (p2wpkh:script remote-payment-pubkey)
    --
  ::  +tx:htlc-output: output for htlc
  ::
  ++  htlc-output
    |=  h=^htlc
    ^-  out:tx:psbt
    =|  =out:tx:psbt
    %=  out
      script-pubkey  witness.h
      value          (msats-to-sats amount-msats.h)
    ==
  ::  +tx:anchor-output: output for anchor
  ::
  ++  anchor-output
    |=  =pubkey
    ^-  out:tx:psbt
    =+  ^=  script-pubkey
        ^-  hexb:bc
        %-  p2wsh:script
        %-  anchor-output:script
        pubkey
    =|  =out:tx:psbt
    %=  out
      script-pubkey  script-pubkey
      value          anchor-size
    ==
  ::  +tx:htlc: generate HTLC transaction for commitment
  ::
  ++  htlc
    |=  $:  =direction
            htlc=update-add-htlc:msg
            =commitment=outpoint
            =delayed=pubkey
            =other-revocation=pubkey
            =htlc=pubkey
            =other-htlc=pubkey
            to-self-delay=blocks
            feerate-per-kw=sats:bc
            anchor-outputs=?
        ==
    |^  ^-  psbt:psbt
    =|  tx=psbt:psbt
    %=  tx
      inputs     [input]~
      outputs    [output]~
      nlocktime  cltv-expiry.htlc
      nversion   2
    ==
    ++  weight
      ^-  @ud
      ?:  ?&(anchor-outputs =(direction %received))
        (add htlc-timeout-weight 3)
      ?:  =(direction %received)
        htlc-timeout-weight
      ?:  anchor-outputs
        (add htlc-success-weight 3)
      htlc-success-weight
    ::
    ++  fee
      ^-  sats:bc
      (fee-by-weight feerate-per-kw weight)
    ::
    ++  input
      ^-  input:psbt
      =|  =input:psbt
      %=  input
        prevout         [txid=txid.commitment-outpoint idx=pos.commitment-outpoint]
        nsequence       ?:(anchor-outputs 0x1 0x0)
        witness-script  `witness-script
        trusted-value   `(msats-to-sats amount-msats.htlc)
      ==
    ::
    ++  output
      ^-  output:psbt
      =|  =output:psbt
      =+  ^=  script-pubkey
          %-  p2wsh:script
          %:  htlc-spend:script
            revocation-pubkey=other-revocation-pubkey
            local-delayed-pubkey=delayed-pubkey
            to-self-delay=to-self-delay
          ==
      %=  output
        script-pubkey  script-pubkey
        value          (msats-to-sats (sub amount-msats.htlc fee))
      ==
    ::
    ++  witness-script
      ^-  hexb:bc
      %-  en:btc-script
      %:  htlc-witness:script
        direction=direction
        local-htlc-pubkey=htlc-pubkey
        remote-htlc-pubkey=other-htlc-pubkey
        remote-revocation-pubkey=other-revocation-pubkey
        payment-hash=payment-hash.htlc
        cltv-expiry=`cltv-expiry.htlc
        confirmed-spend=anchor-outputs
      ==
    --
  ::  +closing:tx:  cooperative-closing transaction
  ++  closing
    |=  $:  =local-funding=pubkey
            =remote-funding=pubkey
            =funding=outpoint
            outputs=(list output:psbt)
        ==
    ^-  psbt:psbt
    =|  tx=psbt:psbt
    =+  ^=  input
        %:  funding-input
          local-funding-pubkey
          remote-funding-pubkey
          funding-outpoint
          0xffff.ffff
        ==
    %=  tx
      inputs     ~[input]
      outputs    outputs
      nlocktime  0
      nversion   2
    ==
  --
::  +script: generators and utilities for bitcoin scripts
::
++  script
  |%
  ++  compress-point  compress-point:secp256k1:secp:crypto
  ::  +p2wsh: generate a p2wsh hash
  ::
  ++  p2wsh
    |=  s=script:btc-script
    ^-  hexb:bc
    %-  en:btc-script
    :~  %op-0
        :-  %op-pushdata
        %-  sha256:bcu  (en:btc-script s)
    ==
  ::  +p2wpkh: generate a p2wpkh hash
  ::
  ++  p2wpkh
    |=  p=pubkey
    ^-  hexb:bc
    %-  en:btc-script
    :~  %op-0
        [%op-pushdata (hash-160:bcu 33^(compress-point p))]
    ==
  ::  +script:funding-output:
  ::
  ++  funding-output
    |=  [p1=pubkey p2=pubkey]
    ^-  script:btc-script
    =+  a=33^(compress-point p1)
    =+  b=33^(compress-point p2)
    ;:  welp
      ~[%op-2]
      ?:  (lte +.a +.b)
        :~  [%op-pushdata a]
            [%op-pushdata b]
        ==
      :~  [%op-pushdata b]
          [%op-pushdata a]
      ==
      ~[%op-2 %op-checkmultisig]
    ==
  ::  +script:local-output:
  ::
  ++  local-output
    |=  $:  =revocation=pubkey
            =local-delayed=pubkey
            to-self-delay=@ud
        ==
   ^-  script:btc-script
   :~  %op-if
       [%op-pushdata 33^(compress-point revocation-pubkey)]
       %op-else
       [%op-pushdata (flip:byt:bcu 2^to-self-delay)]
       %op-checksequenceverify
       %op-drop
       [%op-pushdata 33^(compress-point local-delayed-pubkey)]
       %op-endif
       %op-checksig
    ==
  ::  +script:remote-output:
  ::
  ++  remote-output
    |=  =pubkey
    ^-  script:btc-script
    :~  [%op-pushdata 33^(compress-point pubkey)]
        %op-checksigverify
        %op-1
        %op-checksequenceverify
    ==
  ::  +script:anchor-output:
  ::
  ++  anchor-output
    |=  =pubkey
    ^-  script:btc-script
    :~  [%op-pushdata 33^(compress-point pubkey)]
        %op-checksig
        %op-ifdup
        %op-notif
        %op-16
        %op-checksequenceverify
        %op-endif
    ==
  ::  +script:htlc-prefix:
  ::
  ++  htlc-prefix
    |=  [=revocation=pubkey =remote-htlc=pubkey]
    ^-  script:btc-script
    :~  %op-dup
        %op-hash160
        [%op-pushdata (hash-160:bcu 33^(compress-point revocation-pubkey))]
        %op-equal
        %op-if
        %op-checksig
        %op-else
        [%op-pushdata 33^(compress-point remote-htlc-pubkey)]
        %op-swap
        %op-size
        [%op-pushdata [1 32]]
        %op-equal
    ==
  ::  +script:htlc-offered:
  ::
  ++  htlc-offered
    |=  $:  =local-htlc=pubkey
            =remote-htlc=pubkey
            =revocation=pubkey
            payment-hash=hexb:bc
            confirmed-spend=?
        ==
    ^-  script:btc-script
    ;:  welp
      %+  htlc-prefix  revocation-pubkey  remote-htlc-pubkey
      :~  %op-notif
          %op-drop
          %op-2
          %op-swap
          [%op-pushdata 33^(compress-point local-htlc-pubkey)]
          %op-2
          %op-checkmultisig
          %op-else
          %op-hash160
          [%op-pushdata [20 (ripemd-160:ripemd:crypto payment-hash)]]
          %op-equalverify
          %op-checksig
          %op-endif
      ==
      ?:  confirmed-spend
        :~  %op-1
            %op-checksequenceverify
            %op-drop
            %op-endif
        ==
      ~[%op-endif]
    ==
  ::  +script:htlc-received:
  ::
  ++  htlc-received
    |=  $:  =local-htlc=pubkey
            =remote-htlc=pubkey
            =revocation=pubkey
            payment-hash=hexb:bc
            cltv-expiry=@ud
            confirmed-spend=?
        ==
    ^-  script:btc-script
    ;:  welp
      %+  htlc-prefix  revocation-pubkey  remote-htlc-pubkey
      :~  %op-if
          %op-hash160
          [%op-pushdata [20 (ripemd-160:ripemd:crypto payment-hash)]]
          %op-equalverify
          %op-2
          %op-swap
          [%op-pushdata 33^(compress-point local-htlc-pubkey)]
          %op-2
          %op-checkmultisig
          %op-else
          %op-drop
          [%op-pushdata (flip:byt:bcu 2^cltv-expiry)]
          %op-checklocktimeverify
          %op-drop
          %op-checksig
          %op-endif
      ==
      ?.  confirmed-spend  ~
      :~  %op-1
          %op-checksequenceverify
          %op-drop
      ==
      ~[%op-endif]
    ==
  ::  +script:htlc-witness:
  ::
  ++  htlc-witness
    |=  $:  =direction
            =local-htlc=pubkey
            =remote-htlc=pubkey
            =remote-revocation=pubkey
            payment-hash=hexb:bc
            cltv-expiry=(unit blocks)
            confirmed-spend=?
        ==
    ^-  script:btc-script
    ?:  =(direction %received)
      %:  htlc-received:script
        local-htlc-pubkey=local-htlc-pubkey
        remote-htlc-pubkey=remote-htlc-pubkey
        revocation-pubkey=remote-revocation-pubkey
        payment-hash=payment-hash
        cltv-expiry=(need cltv-expiry)
        confirmed-spend=confirmed-spend
      ==
    %:  htlc-offered:script
      local-htlc-pubkey=local-htlc-pubkey
      remote-htlc-pubkey=remote-htlc-pubkey
      revocation-pubkey=remote-revocation-pubkey
      payment-hash=payment-hash
      confirmed-spend=confirmed-spend
    ==
  ::  +script:htlc-spend:
  ::
  ++  htlc-spend
    |=  $:  =revocation=pubkey
            =local-delayed=pubkey
            to-self-delay=@ud
        ==
    ^-  script:btc-script
    :~  %op-if
        [%op-pushdata 33^(compress-point revocation-pubkey)]
        %op-else
        [%op-pushdata (flip:byt:bcu 2^to-self-delay)]
        %op-checksequenceverify
        %op-drop
        [%op-pushdata 33^(compress-point local-delayed-pubkey)]
        %op-endif
        %op-checksig
    ==
  --
::  +bip69: BIP-69 transaction ordering
::
++  bip69
  |%
  ++  output-lte
    |=  [a=out:tx:psbt b=out:tx:psbt]
    ?.  =(value.a value.b)
      (lth value.a value.b)
    (lte dat.script-pubkey.a dat.script-pubkey.b)
  ::
  ++  input-lte
    |=  [a=in:tx:psbt b=in:tx:psbt]
    ?.  =(dat.txid.prevout.a dat.txid.prevout.b)
      (lth dat.txid.prevout.a dat.txid.prevout.b)
    (lte idx.prevout.a idx.prevout.b)
  ::
  ++  sort-outputs
    |=  os=(list out:tx:psbt)
    (sort os output-lte)
  ::
  ++  sort-inputs
    |=  is=(list in:tx:psbt)
    (sort is input-lte)
  --
::  +bip69-cltv: BIP-69 transaction ordering, with CLTV comparison
::
++  bip69-cltv
  |%
  ++  output-lte
    |=  [a=(pair out:tx:psbt blocks) b=(pair out:tx:psbt blocks)]
    ?.  =(value.p.a value.p.b)
      (lth value.p.a value.p.b)
    ?.  =(dat.script-pubkey.p.a dat.script-pubkey.p.b)
      (lte dat.script-pubkey.p.a dat.script-pubkey.p.b)
    (lte q.a q.b)
  ::
  ++  sort-outputs
    |=  [os=(list out:tx:psbt) cltvs=(list blocks)]
    |^  ^-  (list out:tx:psbt)
    %+  turn
      %+  sort  pairs  output-lte
    |=  pir=(pair out:tx:psbt blocks)
    p.pir
    ::
    ++  pairs
      ^-  (list (pair out:tx:psbt blocks))
      =/  outs=(list out:tx:psbt)  os
      =/  vals=(list blocks)        cltvs
      =|  pirs=(list (pair out:tx:psbt blocks))
      |-
      ?~  outs  pirs
      %=  $
        outs   +.outs
        vals   +.vals
        pirs  :-([p=(head outs) q=(head vals)] pirs)
      ==
    --
  --
::
++  keys
  =,  secp256k1:secp:crypto
  |%
  ++  point-hash
    |=  [a=point b=point]
    ^-  hexb:bc
    %-  sha256:bcu
    %-  cat:byt:bcu
    :~  33^(compress-point a)
        33^(compress-point b)
    ==
  ::
  ++  add-mul-hash
    |=  [a=point b=point c=point]
    %+  add-points
      %+  mul-point-scalar
        g:t
      dat:(point-hash a b)
    c
  ::
  ++  derive-pubkey
    |=  [base=point per-commitment-point=point]
    ^-  pubkey
    %^    add-mul-hash
        per-commitment-point
      base
    base
  ::
  ++  derive-privkey
    |=  [base=point =per-commitment=point secret=hexb:bc]
    ^-  privkey
    :-  32
    %+  mod
      %+  add
        dat:(point-hash per-commitment-point base)
      dat.secret
    n:t
  ::
  ++  derive-revocation-pubkey
    |=  [base=point =per-commitment=point]
    |^  ^-  pubkey
    %+  add-points
      (mul-point-scalar base dat:r)
    (mul-point-scalar per-commitment-point dat:c)
    ::
    ++  r  (point-hash base per-commitment-point)
    ++  c  (point-hash per-commitment-point base)
    --
  ::
  ++  derive-revocation-privkey
    |=  $:  revocation-basepoint=point
            revocation-basepoint-secret=hexb:bc
            per-commitment-point=point
            per-commitment-secret=hexb:bc
        ==
    |^  ^-  privkey
    :-  32
    %+  mod
      %+  add
        (mul dat.revocation-basepoint-secret dat:r)
      (mul dat.per-commitment-secret dat:c)
    n:t
    ++  r  (point-hash revocation-basepoint per-commitment-point)
    ++  c  (point-hash per-commitment-point revocation-basepoint)
    --
  --
::
++  secret
  =,  secp256k1:secp:crypto
  |%
  +$  index  @u
  +$  seed   hexb:bc
  +$  commit-secret  hexb:bc
  ::
  ++  compute-commitment-point
    |=  =commit-secret
    ^-  point
    %+  mul-point-scalar
      g.domain.curve
    dat:commit-secret
  ::
  ++  first-index
    ^-  @ud
    (dec (bex 48))
  ::
  ++  generate-from-seed
    |=  [=seed i=index bits=(unit @ud)]
    |^  ^-  commit-secret
    =/  p=@    dat.seed
    =/  b=@ud  (fall bits 48)
    |-
    =.  b  (dec b)
    =?  p  (test-bit b i)
      %+  shay  32
      %+  flip-bit  b  p
    ?:  =(0 b)
      :*
        wid=32
        dat=(swp 3 p)
      ==
    $(b b, p p)
    ::
    ++  test-bit
      |=  [n=@ p=@]
      =(1 (get-bit n p))
    ::
    ++  get-bit
      |=  [n=@ p=@]
      =/  byt=@  (div n 8)
      =/  bit=@  (mod n 8)
      %+  dis  0x1
      %+  rsh  [0 bit]
      %+  rsh  [3 byt]
      p
    ::
    ++  flip-bit
      |=  [n=@ b=@]
      =/  byt=@  (div n 8)
      =/  bit=@  (mod n 8)
      %+  mix  b
      %+  lsh  [0 bit]
      %+  lsh  [3 byt]
      1
    --
  ::
  ++  next
    |=  [=seed i=index]
    ^-  (pair commit-secret index)
    :-  (generate-from-seed seed i ~)
        (dec i)
  ::
  ++  init-from-seed
    |=  =seed
    ^-  (pair commit-secret index)
    %+  next
      seed
    first-index
  --
::  +revocation: BOLT-03 revocation storage
::
++  revocation
  |_  r=revocation-store
  ::
  ++  start-index
    ^-  @ud
    (dec (bex 48))
  ::
  ++  add-next
    |=  hash=hexb:bc
    ^-  revocation-store
    =+  element=[idx=idx.r secret=hash]
    =+  bucket=(count-trailing-zeros idx.r)
    =|  i=@ud
    |-
    ?:  =(i 0)
      :*
        idx=(dec idx.r)
        buckets=(~(put by buckets.r) bucket element)
      ==
    =/  this=shachain-element      (~(got by buckets.r) i)
    =/  e=(unit shachain-element)  (shachain-derive element idx.this)
    ~|  %hash-not-derivable
    ?>  =(`this e)
    $(i +(i))
  ::
  ++  retrieve
    |=  idx=@u
    ^-  hexb:bc
    ?>  (lte idx start-index)
    ~|  %unable-to-derive-secret
    =+  i=0
    |-
    =/  bucket=shachain-element          (~(got by buckets.r) i)
    =/  element=(unit shachain-element)  (shachain-derive bucket idx)
    ?~  element  $(i +(i))
    ?>  (lte i 48)
    secret.u.element
  ::
  ++  shachain-derive
    |=  [e=shachain-element to-index=@]
    |^  ^-  (unit shachain-element)
    =+  zeros=(count-trailing-zeros idx.e)
    ?.  =(idx.e (get-prefix to-index zeros))
      ~
    %-  some
    :*
      idx=to-index
      secret=(generate-from-seed:secret secret.e to-index `zeros)
    ==
    ++  get-prefix
      |=  [idx=@ud pos=@ud]
      =+  mask=(lsh [0 64] 1)
      =.  mask  (sub mask 1)
      =.  mask  (sub mask (sub (lsh [0 pos] 1) 1))
      (dis idx mask)
    --
  ::
  ++  count-trailing-zeros
    |=  idx=@u
    ^-  @u
    =+  a=idx
    =|  n=@u
    |-
    ?:  =(1 (dis a 1))
      n
    ?:  =(n 48)
      n
    $(a (rsh [0 1] a), n +(n))
  --
::
++  generate-keypair
  |=  [seed=hexb:bc =network family=family:key =idx:bc]
  |^  ^-  pair:key
  [pub=pub:node prv=private-key:node]
  ++  coin
    ?-  network
      %main     0
      %testnet  1
      %regtest  2
    ==
  ::
  ++  fam
    ?-  family
      %multisig         0
      %revocation-base  1
      %htlc-base        2
      %payment-base     3
      %delay-base       4
      %revocation-root  5
    ==
  ::
  ++  purpose    1.337
  ++  path       ~[purpose coin fam 0 idx]
  ++  generator  (from-seed:bip32 seed)
  ++  node       (derive-sequence:generator path)
  --
::  +extract-signature: parse DER-format signature or fail
::
++  extract-signature
  |=  =signature
  ^-  [r=@ s=@]
  =/  a=spec:asn1:der
    %-  need
    %-  de:der
    (flip:byt:bcu signature)
  ?.  ?=([%seq [%int @] [%int @] ~] a)
    !!
  [r=int.i.seq.a s=int.i.t.seq.a]
::  +ecdsa-verify: verify sig is a valid signature for pubkey
::
++  ecdsa-verify
  =,  secp256k1:secp:crypto
  |=  [hash=@ sig=[r=@ s=@] =pubkey]
  ^-  ?
  ?|  =(pubkey (ecdsa-raw-recover hash [0 r.sig s.sig]))
      =(pubkey (ecdsa-raw-recover hash [1 r.sig s.sig]))
  ==
::  +check-signature: verify that signature of hash is correct for pubkey
::
++  check-signature
  =,  secp256k1:secp:crypto
  |=  [hash=hexb:bc =signature =pubkey]
  ^-  ?
  =+  n=(dec wid.signature)
  =+  byts=(take:byt:bcu n signature)
  =+  sigh=(drop:byt:bcu n signature)
  ?.  =(sigh 1^0x1)  %.n
  %^    ecdsa-verify
      dat.hash
    (extract-signature byts)
  pubkey
::  +sign-commitment: sign commitment transaction using local private key
::
++  sign-commitment
    |=  [tx=psbt:psbt =local-config =remote-config]
    ^-  signature
    =+  privkey=32^prv.multisig-key.local-config
    =+  keys=(malt ~[[pub.multisig-key.local-config privkey]])
    =.  tx  (~(all sign:psbt tx) keys)
    %-  ~(got by partial-sigs:(snag 0 inputs.tx))
      pub.multisig-key.local-config
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
::  +channel: channel state manipulation
::
++  channel
  |_  c=chan
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
    |^  ^-  chan
    =|  =chan
    %=  chan
      id                id
      funding-outpoint  funding-outpoint
      constraints       constraints
      our.config        local-config
      her.config        remote-config
      our.htlcs         local-htlc-state
      her.htlcs         remote-htlc-state
    ==
    ++  constraints
      :*  initiator=initiator
          anchor-outputs=anchor-outputs
          capacity=capacity
          funding-tx-min-depth=funding-tx-min-depth
      ==
    ::
    ++  initial-fee-update
      ^-  fee-update
      =|  =fee-update
      %=  fee-update
        rate                      initial-feerate
        local-commitment-number   `--0
        remote-commitment-number  `--0
      ==
    ::
    ++  local-htlc-state
      =|  =htlc-state
      %=  htlc-state
        fee-updates     ~[initial-fee-update]
        revack-pending  %.n
      ==
    ::
    ++  remote-htlc-state
      =|  =htlc-state
      %=  htlc-state
        fee-updates     ~[initial-fee-update]
        revack-pending  %.n
      ==
    --
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
  ++  set-state
    |=  new-state=chan-state
    ^-  chan
    ?.  (~(has in state-transitions) [state.c new-state])
      ~|("illegal-state-transition: {<state.c>}->{<new-state>}" !!)
    c(state new-state)
  ::
  ++  funding-tx-min-depth
    ^-  sats:bc
    funding-tx-min-depth.constraints.c
  ::
  ++  feerate
    |=  [=owner =commitment-number]
    ^-  sats:bc
    (~(feerate htlcs c) owner commitment-number)
  ::
  ++  oldest-unrevoked-feerate
    |=  =owner
    ^-  sats:bc
    (~(oldest-unrevoked-feerate htlcs c) owner)
  ::
  ++  latest-feerate
    |=  =owner
    ^-  sats:bc
    (~(latest-feerate htlcs c) owner)
  ::
  ++  next-feerate
    |=  =owner
    ^-  sats:bc
    (~(next-feerate htlcs c) owner)
  ::
  ++  funding-address
    ^-  address:bc
    %^    make-funding-address
        network.our.config.c
      pub.multisig-key.our.config.c
    pub.multisig-key.her.config.c
  ::
  ++  sweep-address
    ^-  hexb:bc
    ~|(%unimplemented !!)
  ::
  ++  config-for
    |=  =owner
    ^-  channel-config
    ?-  owner
      %local   -.our.config.c
      %remote  -.her.config.c
    ==
  ::  +update-onchain-state: transition channel state based on funding utxo
  ::  TODO: handle closing utxos
  ::
  ++  update-onchain-state
    |=  [=utxo:bc block=@ud]
    ^-  chan
    =+  confs=(sub block height.utxo)
    ?:  ?&  (gte confs funding-tx-min-depth)
            =(state.c %opening)
        ==
      (set-state %funded)
    c
  ::  +can-add-htlc: can proposer add an HTLC of amount-msats msats
  ::
  ++  can-add-htlc
    |=  [proposer=owner =amount=msats]
    ^-  ?
    =+  receiver=(invert-owner proposer)
    =+  cn=(next-commitment-number receiver)
    =+  config=(config-for receiver)
    ?.  =(state.c %open)
      %.n
    ?:  ?&  =(proposer %local)
            ?!  can-update
        ==
      %.n
    ::  check htlc raw value
    ::
    ?:  (lte amount-msats 0)
      %.n
    ?:  (lth amount-msats htlc-minimum-msats.config)
      %.n
    ::  check proposer can afford htlc
    ::
    =+  max-can-send-msats=(available-to-spend proposer)
    ?:  (lth max-can-send-msats amount-msats)
      %.n
    ::  check max-accepted-htlcs
    ::
    ?:  %+  gth
          +((lent (~(by-direction htlcs c) receiver %received cn)))
        max-accepted-htlcs.config
      %.n
    ::  check max-htlc-value-in-flight
    ::
    =+  ^=  current-htlc-sum
        %-  htlc-sum
        (~(by-direction htlcs c) receiver %received cn)
    ?:  %+  gth
          (add current-htlc-sum amount-msats)
        max-htlc-value-in-flight-msats.config
      %.n
    %.y
  ::  +can-pay: can payment of amount-msats
  ::
  ++  can-pay
    |=  =amount=msats
    ^-  ?
    (can-add-htlc %local amount-msats)
  ::  +can-receive: can a payment of amount-msats be received
  ::
  ++  can-receive
    |=  =amount=msats
    ^-  ?
    (can-add-htlc %remote amount-msats)
  ::  +can-update: can commitment updates be sent
  ::
  ++  can-update
    ^-  ?
    ?|  =(state.c %open)
        =(state.c %closing)
    ==
  ::  +balance: 'whose' balance at a given commitment as viewed by 'owner'
  ::
  ++  balance
    |=  [whose=owner ctx-owner=owner cn=commitment-number]
    ^-  msats
    =+  initial=initial-msats:(config-for whose)
    (~(balance htlcs c) whose ctx-owner cn initial)
  ::  +balance-minus-outgoing-htlcs: channel balance less unremoved htlcs
  ::
  ++  balance-minus-outgoing-htlcs
    |=  [whose=owner ctx-owner=owner cn=commitment-number]
    ^-  msats
    =+  commited=(balance whose ctx-owner cn)
    =+  direction=?:(!=(whose owner) %received %sent)
    =+  ^=  in-htlcs
        (htlc-sum (~(by-direction htlcs c) ctx-owner direction cn))
    (sub commited in-htlcs)
  ::  +available-to-spend: usable balance of 'owner' in msats
  ::
  ++  available-to-spend
    |=  subject=owner
    ^-  msats
    =+  sender=subject
    =+  receiver=(invert-owner subject)
    =+  initiator=?:(initiator.constraints.c %local %remote)
    |^
    %+  max  0
    %+  min
      %+  max
        (consider-ctx receiver %.y)
      (consider-ctx receiver %.n)
    %+  max
      (consider-ctx sender %.y)
    (consider-ctx sender %.n)
    ::
    ++  consider-ctx
      |=  [ctx-owner=owner is-dust=?]
      ^-  msats
      =+  cn=(next-commitment-number ctx-owner)
      =+  sendr-balance=(balance-minus-outgoing-htlcs sender ctx-owner cn)
      =+  recvr-balance=(balance-minus-outgoing-htlcs receiver ctx-owner cn)
      =+  sendr-reserve=(sats-to-msats reserve-sats:(config-for receiver))
      =+  recvr-reserve=(sats-to-msats reserve-sats:(config-for sender))
      =+  num-sent=(lent (included-htlcs ctx-owner %sent `cn ~))
      =+  num-recd=(lent (included-htlcs ctx-owner %received `cn ~))
      =+  num-htlcs=(add num-sent num-recd)
      =+  fee-rate=(feerate ctx-owner cn)
      ::
      =+  ^=  ctx-fees
        %:  commitment-fee
          num-htlcs
          fee-rate
          initiator.constraints.c
          anchor-outputs.constraints.c
          %.n
        ==
      ::
      =+  htlc-fee-msats=(fee-for-htlc-output fee-rate)
      =+  ^=  htlc-trim-threshold-msats
          %-  sats-to-msats
          ?:  =(ctx-owner receiver)
            %^    received-htlc-trim-threshold
                dust-limit-sats:(config-for ctx-owner)
              fee-rate
            anchor-outputs.constraints.c
          %^    offered-htlc-trim-threshold
              dust-limit-sats:(config-for ctx-owner)
            fee-rate
          anchor-outputs.constraints.c
      ::
      =+  ^=  max-send-msats
          ?:  ?&  =(sender initiator)
                  =(initiator %local)
              ==
            =/  fee-spike-buffer=msats
              %.  sender
              %~  got  by
              %:  commitment-fee
                (add num-htlcs (add ?.(is-dust 1 0) 1))
                (mul 2 fee-rate)
                initiator.constraints.c
                anchor-outputs.constraints.c
                %.n
              ==
            (sub (sub sendr-balance sendr-reserve) fee-spike-buffer)
          (sub (sub sendr-balance sendr-reserve) (~(got by ctx-fees) sender))
      ::
      ?:  is-dust
        (min max-send-msats (dec htlc-trim-threshold-msats))
      ?:  =(sender initiator)
        (sub max-send-msats htlc-fee-msats)
      ?:  %+  lth  recvr-balance
          %+  add  recvr-reserve
          %+  add  (~(got by ctx-fees) receiver)
            htlc-fee-msats
        0
      max-send-msats
    --
  ::  +add-htlc: add a new local htlc to the channel
  ::
  ++  add-htlc
    |=  h=update-add-htlc:msg
    ^-  (pair update-add-htlc:msg chan)
    ~|  %cannot-add-htlc
    ?>  (can-add-htlc %local amount-msats.h)
    (~(send htlcs c) h)
  ::  +receive-htlc: add a new remote htlc to the channel
  ::
  ++  receive-htlc
    |=  h=update-add-htlc:msg
    ^-  (pair update-add-htlc:msg chan)
    ~|  %cannot-add-htlc
    ?>  (can-add-htlc %remote amount-msats.h)
    (~(receive htlcs c) h)
  ::  +included-htlcs: HTLCs for owner, optionally for commitment number
  ::
  ++  included-htlcs
    |=  [=owner =direction cn=(unit commitment-number) feerate=(unit sats:bc)]
    |^  ^-  (list update-add-htlc:msg)
    %+  skip  htlcs
    |=  h=update-add-htlc:msg
    %:  is-trimmed
      direction=direction
      h=h
      feerate=fee
      dust-limit-sats=dust-limit-sats:conf
      anchor=anchor-outputs.constraints.c
    ==
    ++  conf
      ^-  channel-config
      (config-for owner)
    ::
    ++  commit
      ^-  commitment-number
      %+  fall  cn
      (oldest-unrevoked-commitment-number owner)
    ::
    ++  fee
      ^-  sats:bc
      %+  fall  feerate
      (^feerate owner commit)
    ::
    ++  htlcs
      ^-  (list update-add-htlc:msg)
      (~(by-direction ^htlcs c) owner direction commit)
    --
  ::  +secret-and-point: owner's commitment secret (if known) and point
  ::
  ++  secret-and-point
    |=  [=owner =commitment-number]
    ^-  (pair (unit hexb:bc) point)
    ?>  !=((cmp:si commitment-number --0) -1)
    =+  ctn=(abs:si commitment-number)
    ?-    owner
        %remote
      =+  ^=  offset
          %+  dif:si  commitment-number
          (oldest-unrevoked-commitment-number owner)
      ~|  %no-remote-commitment
      ?>  !=((cmp:si offset --1) --1)
      =+  conf=her.config.c
      ?:  =(offset --1)
        [~ next-per-commitment-point.conf]
      ?:  =(offset --0)
        [~ current-per-commitment-point.conf]
      =/  secr=hexb:bc
        %-  ~(retrieve revocation revocations.c)
          (sub first-index:secret ctn)
      [`secr (compute-commitment-point:secret secr)]
    ::
        %local
      =+  conf=our.config.c
      =/  secr=hexb:bc
        %^    generate-from-seed:secret
            per-commitment-secret-seed.conf
          (sub first-index:secret ctn)
        ~
      [`secr (compute-commitment-point:secret secr)]
    ==
  ::  +secret-and-commitment: owner's commitment secret and transaction
  ::
  ++  secret-and-commitment
    |=  [=owner =commitment-number]
    ^-  (pair (unit hexb:bc) psbt:psbt)
    =/  [secret=(unit hexb:bc) =point]
      %+  secret-and-point
        owner
      commitment-number
    :-  secret
    %^    make-commitment
        owner
      point
    commitment-number
  ::  +commitment: owner's commitment transaction
  ::
  ++  commitment
    |=  [=owner =commitment-number]
    ^-  psbt:psbt
    +:(secret-and-commitment owner commitment-number)
  ::  +next-commitment: owner's next commitment transaction
  ::
  ++  next-commitment
    |=  =owner
    ^-  psbt:psbt
    %+  commitment
      owner
    (next-commitment-number owner)
  ::  +latest-commitment: owner's latest commitment transaction
  ::
  ++  latest-commitment
    |=  =owner
    ^-  psbt:psbt
    %+  commitment
      owner
    (latest-commitment-number owner)
  ::  +oldest-unrevoked-commitment: owner's last unrevoked commitment
  ::
  ++  oldest-unrevoked-commitment
    |=  =owner
    ^-  psbt:psbt
    %+  commitment
      owner
    (oldest-unrevoked-commitment-number owner)
  ::  +latest-commitment-number: owner's latest commitment number
  ::
  ++  latest-commitment-number
    |=  =owner
    ^-  commitment-number
    (~(latest-cn htlcs c) owner)
  ::  +next-commitment-number: owner's next commitment number
  ::
  ++  next-commitment-number
    |=  =owner
    ^-  commitment-number
    %+  sum:si  --1
    (latest-commitment-number owner)
  ::  +oldest-unrevoked-commitment-number: owner's oldest unrevoked commitment number
  ::
  ++  oldest-unrevoked-commitment-number
    |=  =owner
    (~(oldest-unrevoked-cn htlcs c) owner)
  ::  +open-with-first-commitment-point: initialize channel state after opening
  ::
  ++  open-with-first-commitment-point
    |=  [=remote=point =remote=signature]
    ^-  chan
    %~  channel-open-finished  htlcs
    %=  c
      current-per-commitment-point.her.config  remote-point
      current-commitment-signature.our.config  remote-signature
    ==
  ::  +htlc-output-indices: candidate indices for commitment HTLC outputs
  ::
  ++  htlc-output-indices
    |=  $:  subject=owner
            =direction
            =per-commitment=point
            commitment=psbt:psbt
            htlc=update-add-htlc:msg
        ==
    ^-  (set @u)
    =+  ^=  this-config
        ^-  channel-config
        (config-for subject)
    ::
    =+  ^=  that-config
        ^-  channel-config
        %-  config-for
        (invert-owner subject)
    ::
    =+  ^=  other-revocation-pubkey
        ^-  pubkey
        %:  derive-revocation-pubkey:keys
          base=pub.revocation.basepoints:that-config
          per-commitment-point=per-commitment-point
        ==
    ::
    =+  ^=  other-htlc-pubkey
        ^-  pubkey
        %:  derive-pubkey:keys
          base=pub.htlc.basepoints:that-config
          per-commitment-point=per-commitment-point
        ==
    ::
    =+  ^=  htlc-pubkey
        ^-  pubkey
        %:  derive-pubkey:keys
          base=pub.htlc.basepoints:this-config
          per-commitment-point=per-commitment-point
        ==
    ::
    =+  ^=  address
        ^-  hexb:bc
        %-  p2wsh:script
        %:  htlc-witness:script
          direction=direction
          local-htlc-pubkey=htlc-pubkey
          remote-htlc-pubkey=other-htlc-pubkey
          remote-revocation-pubkey=other-revocation-pubkey
          payment-hash=payment-hash.htlc
          cltv-expiry=`cltv-expiry.htlc
          confirmed-spend=anchor-outputs:this-config
        ==
    ::
    %-  silt
    %+  fand
      :~
        :*  script-pubkey=address
            value=(msats-to-sats amount-msats.htlc)
        ==
      ==
    %+  turn  outputs.commitment
    |=  =output:psbt
    :*  script-pubkey=script-pubkey.output
        value=value.output
    ==
  ::  +htlc-output-index-map: map of direction/HTLC pairs to output indices
  ::
  ++  htlc-output-index-map
    |=  $:  commitment=psbt:psbt
            =per-commitment=point
            subject=owner
            =commitment-number
        ==
    ^-  (map (pair direction update-add-htlc:msg) [idx=@u rel=@u])
    =+  ^=  unclaimed-indices
        ^-  (set @u)
        %-  silt
        %+  gulf  0
        %-  dec
        (lent outputs.commitment)
    ::
    =+  ^=  collect-indices
        |=  [[d=direction h=update-add-htlc:msg] idxs=(set @u)]
        ^-  (pair (pair (pair direction update-add-htlc:msg) @u) (set @u))
        =/  candidates=(set @u)
          %:  htlc-output-indices
            subject=subject
            direction=d
            per-commitment-point=per-commitment-point
            commitment=commitment
            htlc=h
          ==
        =/  idx-list=(list @u)  ~(tap in (~(int in candidates) idxs))
        ?^  idx-list
          :-  [[d h] (head idx-list)]
          (~(del in idxs) (head idx-list))
        ~|(%no-htlc-index !!)
    ::
    =+  ^=  htlc-lte
        |=  [a=update-add-htlc:msg b=update-add-htlc:msg]
        ^-  ?
        (lte cltv-expiry.a cltv-expiry.b)
    ::
    =+  ^=  offered
        ^-  (list (pair direction update-add-htlc:msg))
        %+  turn
          %+  sort
            (included-htlcs subject %sent `commitment-number ~)
          htlc-lte
        (lead %sent)
    ::
    =+  ^=  received
        ^-  (list (pair direction update-add-htlc:msg))
        %+  turn
          %+  sort
            (included-htlcs subject %received `commitment-number ~)
          htlc-lte
        (lead %received)
    ::
    =+  ^=  indexed
        ^-  (list (pair (pair direction update-add-htlc:msg) @u))
        %+  sort
          %-  head
          (spin (welp offered received) unclaimed-indices collect-indices)
        |=  $:  x=(pair (pair direction update-add-htlc:msg) @u)
                y=(pair (pair direction update-add-htlc:msg) @u)
            ==
        (lte q.x q.y)
    ::
    =|  acc=(map (pair direction update-add-htlc:msg) [idx=@u rel=@u])
    =+  i=0
    |-
    ?~  indexed  acc
    =+  elt=(head indexed)
    %=  $
      i        +(i)
      acc      (~(put by acc) p.elt [idx=q.elt rel=i])
      indexed  (tail indexed)
    ==
  ::  +sign-htlcs: sign htlc map, ordered by index
  ::
  ++  sign-htlcs
    |=  $:  htlcs=(map (pair direction update-add-htlc:msg) [idx=@u rel=@u])
            commitment=psbt:psbt
            =commitment-number
            =per-commitment=point
            htlc-privkey=hexb:bc
        ==
    |^  ^-  (list signature)
    (turn sorted tail)
    ++  signed
      ^-  (list (pair @u signature))
      (~(rep by htlcs) sign-one)
    ::
    ++  sorted
      ^-  (list (pair @u signature))
      %+  sort  signed
      |=  [a=(pair @u signature) b=(pair @u signature)]
      (lte p.a p.b)
    ::
    ++  sign-one
      |=  $:  [[=direction =update-add-htlc:msg] [idx=@u rel=@]]
              acc=(list (pair @u signature))
          ==
      ^-  (list (pair @u signature))
      =/  tx=psbt:psbt
        %:  make-htlc-tx
          subject=%remote
          commitment=commitment
          per-commitment-point=per-commitment-point
          commitment-number=commitment-number
          direction=direction
          htlc=update-add-htlc
          output-index=idx
        ==
      %+  snoc  acc
      [p=idx q=(~(one sign:psbt tx) 0 htlc-privkey ~)]
    --
  ::  +check-htlc-signature: verify signature of htlc
  ::
  ++  check-htlc-signature
    |=  $:  htlc=update-add-htlc:msg
            =signature
            =direction
            =per-commitment=point
            =commitment-number
            commitment=psbt:psbt
            idx=@u
        ==
    ^-  ?
    =+  ^=  tx
        ^-  psbt:psbt
        %:  make-htlc-tx
          subject=%local
          commitment=commitment
          per-commitment-point=per-commitment-point
          commitment-number=commitment-number
          direction=direction
          htlc=htlc
          output-index=idx
        ==
    ::
    =+  ^=  hash
        ^-  hexb:bc
        %-  dsha256:bcu:bc
        (~(witness-preimage sign:psbt tx) 0 ~)
    ::
    =+  ^=  remote-htlc-pubkey
        ^-  pubkey
        %:  derive-pubkey:keys
          base=pub.htlc.basepoints.her.config.c
          per-commitment-point=per-commitment-point
        ==
    ::
    (check-signature hash signature remote-htlc-pubkey)
  ::  +check-htlc-signatures: verify list of htlc signatures
  ::
  ++  check-htlc-signatures
    |=  $:  htlcs=(map (pair direction update-add-htlc:msg) [idx=@u rel=@u])
            sigs=(list signature)
            =per-commitment=point
            =commitment-number
            commitment=psbt:psbt
        ==
     ^-  ?
     %-  ~(rep by htlcs)
     |=  [[[=direction =update-add-htlc:msg] [idx=@u rel=@u]] acc=?]
     ?&  acc
       %:  check-htlc-signature
         htlc=update-add-htlc
         signature=(snag rel sigs)
         direction=direction
         per-commitment-point=per-commitment-point
         commitment-number=commitment-number
         commitment=commitment
         idx=idx
       ==
     ==
  ::  +sign-next-commitment: create signatures for next remote commitment tx
  ::
  ++  sign-next-commitment
    ^-  (pair (pair signature (list signature)) chan)
    =+  next-remote-cn=(next-commitment-number %remote)
    =+  pending-remote-commitment=(next-commitment %remote)
    ::
    =+  ^=  their-remote-htlc-privkey
        %^    derive-privkey:keys
            pub.htlc.basepoints.our.config.c
          next-per-commitment-point.her.config.c
        32^prv.htlc.basepoints.our.config.c
    ::
    =+  ^=  htlc-indices
        ^-  (map (pair direction update-add-htlc:msg) [idx=@u rel=@])
        %:  htlc-output-index-map
          commitment=pending-remote-commitment
          per-commitment-point=next-per-commitment-point.her.config.c
          subject=%remote
          commitment-number=next-remote-cn
        ==
    ::
    :_  ~(send-commitment htlcs c)
    :-  (sign-commitment pending-remote-commitment our.config.c her.config.c)
    %:  sign-htlcs
      htlcs=htlc-indices
      commitment=pending-remote-commitment
      commitment-number=next-remote-cn
      per-commitment-point=next-per-commitment-point.her.config.c
      htlc-privkey=their-remote-htlc-privkey
    ==
  ::  +receive-new-commitment: process signatures for our next local commitment
  ::
  ++  receive-new-commitment
    |=  [sig=signature htlc-sigs=(list signature)]
    |^  ^-  chan
    ~|  %invalid-commitment-signature
    ?>  (check-signature hash sig pub.multisig-key.her.config.c)
    ?>  check-htlc-sigs
    %~  receive-commitment  htlcs
    %=  c
      current-commitment-signature.our.config  sig
      current-htlc-signatures.our.config       htlc-sigs
    ==
    ++  next-local-cn
      ^-  commitment-number
      (next-commitment-number %local)
    ::
    ++  pending-local-commitment
      ^-  psbt:psbt
      (next-commitment %local)
    ::
    ++  per-commitment-point
      ^-  point
      +:(secret-and-point %local next-local-cn)
    ::
    ++  hash
      ^-  hexb:bc
      %-  dsha256:bcu:bc
      (~(witness-preimage sign:psbt pending-local-commitment) 0 ~)
    ::
    ++  htlc-map
      %:  htlc-output-index-map
        commitment=pending-local-commitment
        per-commitment-point=per-commitment-point
        subject=%local
        commitment-number=next-local-cn
      ==
    ::
    ++  check-htlc-sigs
      ^-  ?
      %:  check-htlc-signatures
         htlcs=htlc-map
         sigs=htlc-sigs
         per-commitment-point=per-commitment-point
         commitment-number=next-local-cn
         commitment=pending-local-commitment
       ==
    --
  ::  +revoke-current-commitment: generate a revoke-and-ack for the current commitment
  ::
  ++  revoke-current-commitment
    ^-  (pair revoke-and-ack:msg chan)
    =|  rev=revoke-and-ack:msg
    =+  new-number=(latest-commitment-number %local)
    =+  new-commit=(latest-commitment %local)
    ~|  %invalid-commitment-signature
    ?>  (signature-fits new-commit)
    =.  c  ~(send-revocation htlcs c)
    =/  [last-secret=(unit hexb:bc) =last=point]
      (secret-and-point %local (dif:si new-number --1))
    =/  [next-secret=(unit hexb:bc) =next=point]
      (secret-and-point %local (sum:si new-number --1))
    :_  c
    %=  rev
      channel-id                 id.c
      per-commitment-secret      (need last-secret)
      next-per-commitment-point  next-point
    ==
  ::  +receive-revocation: process a received revocation
  ::
  ++  receive-revocation
    =,  secp256k1:secp:crypto
    |=  =revoke-and-ack:msg
    ^-  chan
    =+  new-number=(latest-commitment-number %remote)
    =+  cur-point=current-per-commitment-point.her.config.c
    =/  derived-point=point
      (priv-to-pub dat.per-commitment-secret.revoke-and-ack)
    ~|  %revoked-secret-not-for-current-point
    ?>  =(cur-point derived-point)
    %~  receive-revocation  htlcs
    %=    c
        current-per-commitment-point.her.config
      next-per-commitment-point.her.config.c
    ::
        next-per-commitment-point.her.config
      next-per-commitment-point.revoke-and-ack
    ::
        revocations
      (~(add-next revocation revocations.c) per-commitment-secret.revoke-and-ack)
    ==
  ::  +total-msats: total msats sent/received
  ::
  ++  total-msats
    |=  =direction
    ^-  msats
    %-  htlc-sum
    %^    ~(all-settled-htlcs-by-direction htlcs c)
        %local
      direction
    ~
  ::  +settle-htlc: settle/fulfill a pending received HTLC
  ::
  ++  settle-htlc
    |=  [preimage=hexb:bc =htlc-id]
    ^-  chan
    ?.  can-update
      ~|(%cannot-update-channel !!)
    =+  htlc=(~(by-id htlcs c) %remote htlc-id)
    ?.  =(payment-hash.htlc (sha256:bcu:bc preimage))
      ~|(%htlc-invalid-preimage !!)
    ?:  (~(has by settles:(~(for-owner htlcs c) %remote)) htlc-id)
      ~|(%htlc-already-settled !!)
    (~(send-settle htlcs c) htlc-id)
  ::  +recive-htlc-settle: settle/fulfill a pending offered HTLC
  ::
  ++  receive-htlc-settle
    |=  [preimage=hexb:bc =htlc-id]
    ^-  chan
    ?.  can-update
      ~|(%cannot-update-channel !!)
    =+  htlc=(~(by-id htlcs c) %local htlc-id)
    ?.  =(payment-hash.htlc (sha256:bcu:bc preimage))
      ~|(%htlc-invalid-preimage !!)
    ?:  (~(has by settles:(~(for-owner htlcs c) %local)) htlc-id)
      ~|(%htlc-already-settled !!)
    (~(receive-settle htlcs c) htlc-id)
  ::  +fail-htlc: fail a pending received HTLC
  ::
  ++  fail-htlc
    |=  =htlc-id
    ^-  chan
    ~|  %cannot-update-channel
    ?>  can-update
    (~(send-fail htlcs c) htlc-id)
  ::  +receive-fail-htlc: fail a pending offered HTLC
  ::
  ++  receive-fail-htlc
    |=  =htlc-id
    ^-  chan
    (~(receive-fail htlcs c) htlc-id)
  ::  +update-fee: process a feerate update
  ::
  ++  update-fee
    |=  [feerate=sats:bc our=?]
    ^-  chan
    ?.  =(initiator.constraints.c our)
      ~|(%update-fee-wrong-initiator !!)
    =+  sender=?:(our %local %remote)
    =+  owner=(invert-owner sender)
    =+  ctn=(next-commitment-number owner)
    =+  ^=  sender-balance
        ^-  msats
        (balance-minus-outgoing-htlcs sender owner ctn)
    =+  ^=  sender-reserve
        ^-  msats
        (sats-to-msats reserve-sats:(config-for sender))
    =+  ^=  num-htlcs
        ^-  @ud
        %+  add
          (lent (included-htlcs owner %sent `ctn `feerate))
        (lent (included-htlcs owner %received `ctn `feerate))
    =+  ^=  commit-fees
        ^-  (map ^owner msats)
        %:  commitment-fee
          num-htlcs=num-htlcs
          feerate=feerate
          is-local-initiator=initiator.constraints.c
          anchor=anchor-outputs.constraints.c
          round=%.n
        ==
    ?:  (lth sender-balance (add sender-reserve (~(got by commit-fees) sender)))
      ~|(%update-fee-below-reserve !!)
    ?:  our
      ?>  can-update
      (~(send-update-fee htlcs c) feerate)
    (~(receive-update-fee htlcs c) feerate)
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
    |^  ^-  psbt:psbt
    %:  htlc:tx
      direction=direction
      htlc=htlc
      ^=  commitment-outpoint
        :*  txid=(txid:psbt (extract-unsigned:psbt commitment))
            pos=output-index
            sats=(msats-to-sats amount-msats.htlc)
        ==
      delayed-pubkey=delayed-pubkey
      other-revocation-pubkey=other-revocation-pubkey
      htlc-pubkey=htlc-pubkey
      other-htlc-pubkey=other-htlc-pubkey
      to-self-delay=to-self-delay:that-config
      feerate-per-kw=(feerate subject commitment-number)
      anchor-outputs=anchor-outputs:that-config
    ==
    ++  this-config
      ^-  channel-config
      (config-for subject)
    ::
    ++  that-config
      ^-  channel-config
      %-  config-for
      (invert-owner subject)
    ::
    ++  delayed-pubkey
      ^-  pubkey
      %:  derive-pubkey:keys
        base=pub.delayed-payment.basepoints:this-config
        per-commitment-point=per-commitment-point
      ==
    ::
    ++  other-revocation-pubkey
      ^-  pubkey
      %:  derive-revocation-pubkey:keys
        base=pub.revocation.basepoints:that-config
        per-commitment-point=per-commitment-point
      ==
    ::
    ++  other-htlc-pubkey
      ^-  pubkey
      %:  derive-pubkey:keys
        base=pub.htlc.basepoints:that-config
        per-commitment-point=per-commitment-point
      ==
    ++  htlc-pubkey
      ^-  pubkey
      %:  derive-pubkey:keys
        base=pub.htlc.basepoints:this-config
        per-commitment-point=per-commitment-point
      ==
    --
  ::  +make-commitment: generate owner's commitment transaction
  ::
  ++  make-commitment
    |=  [=owner =commitment=point =commitment-number]
    |^  ^-  psbt:psbt
    %:  commitment:tx
      commitment-number=commitment-number
      local-funding-pubkey=pub.multisig-key:this-config
      remote-funding-pubkey=pub.multisig-key:that-config
      remote-payment-pubkey=payment-pubkey
      funder-payment-basepoint=funder-payment-basepoint
      fundee-payment-basepoint=fundee-payment-basepoint
      revocation-pubkey=that-revocation-pubkey
      delayed-pubkey=delayed-pubkey
      to-self-delay=to-self-delay:that-config
      funding-outpoint=funding-outpoint.c
      local-amount=local-msats
      remote-amount=remote-msats
      dust-limit-sats=dust-limit-sats:this-config
      anchor-outputs=anchor-outputs.constraints.c
      htlcs=commitment-htlcs
      fees-per-participant=onchain-fees
    ==
    ++  local-msats
      ^-  msats
      %+  sub
        (balance owner owner commitment-number)
      (htlc-sum received-htlcs)
    ::
    ++  remote-msats
      ^-  msats
      %+  sub
        (balance (invert-owner owner) owner commitment-number)
      (htlc-sum received-htlcs)
    ::
    ++  onchain-fees
      ^-  (map ^owner msats)
      =+  num-htlcs=(lent commitment-htlcs)
      =+  fee-rate=(feerate owner commitment-number)
      =+  ^=  local-init
          ^-  ?
          =(initiator.constraints.c =(owner %local))
      %:  commitment-fee
        num-htlcs=num-htlcs
        feerate=fee-rate
        is-local-initiator=local-init
        anchor=anchor-outputs.constraints.c
        round=%.n
      ==
    ::
    ++  received-htlcs
      ^-  (list update-add-htlc:msg)
      (~(by-direction htlcs c) owner %received commitment-number)
    ::
    ++  offered-htlcs
      ^-  (list update-add-htlc:msg)
      (~(by-direction htlcs c) owner %sent commitment-number)
    ::
    ++  commitment-htlcs
      ^-  (list htlc)
      ;:  welp
        %+  turn  received-htlcs
        |=  h=update-add-htlc:msg
        :-  h
        %-  p2wsh:script
        %:  htlc-received:script
          local-htlc-pubkey=this-htlc-pubkey
          remote-htlc-pubkey=that-htlc-pubkey
          revocation-pubkey=that-revocation-pubkey
          payment-hash=payment-hash.h
          cltv-expiry=cltv-expiry.h
          confirmed-spend=anchor-outputs.constraints.c
        ==
      ::
        %+  turn  offered-htlcs
        |=  h=update-add-htlc:msg
        :-  h
        %-  p2wsh:script
        %:  htlc-offered:script
          local-htlc-pubkey=this-htlc-pubkey
          remote-htlc-pubkey=that-htlc-pubkey
          revocation-pubkey=that-revocation-pubkey
          payment-hash=payment-hash.h
          confirmed-spend=anchor-outputs.constraints.c
        ==
      ==
    ::
    ++  this-config
      ^-  channel-config
      (config-for owner)
    ::
    ++  that-config
      ^-  channel-config
      %-  config-for
      %-  invert-owner
        owner
    ::
    ++  this-htlc-pubkey
      ^-  pubkey
      %+  derive-pubkey:keys
        pub.htlc.basepoints:this-config
      commitment-point
    ::
    ++  that-htlc-pubkey
      ^-  pubkey
      %+  derive-pubkey:keys
        pub.htlc.basepoints:that-config
      commitment-point
    ::
    ++  that-revocation-pubkey
      ^-  pubkey
      %+  derive-revocation-pubkey:keys
        pub.revocation.basepoints:that-config
      commitment-point
    ::
    ++  payment-pubkey
      ^-  pubkey
      %+  derive-pubkey:keys
        pub.payment.basepoints:that-config
      commitment-point
    ::
    ++  delayed-pubkey
      ^-  pubkey
      %+  derive-pubkey:keys
        pub.delayed-payment.basepoints:this-config
      commitment-point
    ::
    ++  funder-payment-basepoint
      ^-  point
      ?:  initiator.constraints.c
        pub.payment.basepoints.our.config.c
      pub.payment.basepoints.her.config.c
    ::
    ++  fundee-payment-basepoint
      ^-  point
      ?.  initiator.constraints.c
        pub.payment.basepoints.our.config.c
      pub.payment.basepoints.her.config.c
    --
  ::
  ++  make-closing-tx
    |=  $:  local-script=hexb:bc
            remote-script=hexb:bc
            =fee=sats:bc
        ==
    ^-  [tx=psbt:psbt =signature]
    =+  our-cn=(oldest-unrevoked-commitment-number %local)
    =+  her-cn=(oldest-unrevoked-commitment-number %remote)
    =/  fees=(map owner sats:bc)
      %-  malt
      %-  limo
      :~  [%local ?:(initiator.constraints.c (mul fee-sats 1.000) 0)]
          [%remote ?.(initiator.constraints.c (mul fee-sats 1.000) 0)]
      ==
    =/  outputs=(list output:psbt)
      %:  commitment-outputs:tx
        fees-per-participant=fees
        local-funding-pubkey=pub.multisig-key.our.config.c
        remote-funding-pubkey=pub.multisig-key.her.config.c
        local-amount-msats=(balance %local %local our-cn)
        remote-amount-msats=(balance %remote %local her-cn)
        local-script=local-script
        remote-script=remote-script
        htlcs=~
        dust-limit-sats=dust-limit-sats:(config-for %local)
        anchor=anchor-outputs.constraints.c
      ==
    =/  tx=psbt:psbt
      %:  closing:tx
        local-funding-pubkey=pub.multisig-key.our.config.c
        remote-funding-pubkey=pub.multisig-key.her.config.c
        funding-outpoint=funding-outpoint.c
        outputs=outputs
      ==
    =+  ^=  signing-key
        ^-  hexb:bc
        32^prv.multisig-key.our.config.c
    :-  tx
    (~(one sign:psbt tx) 0 signing-key ~)
  ::
  ++  signature-fits
    |=  tx=psbt:psbt
    ^-  ?
    =+  remote-sig=current-commitment-signature.our.config.c
    =+  preimage=(~(witness-preimage sign:psbt tx) 0 ~)
    =+  hash=(dsha256:bcu:bc preimage)
    =+  pubkey=pub.multisig-key.her.config.c
    (check-signature hash remote-sig pubkey)
  ::
  ++  force-close-tx
    ^-  psbt:psbt
    =+  tx=(latest-commitment %local)
    ?>  (signature-fits tx)
    =+  local-config=our.config.c
    =+  privkey=32^prv.multisig-key.our.config.c
    =+  keys=(malt ~[[pub.multisig-key.local-config privkey]])
    =.  tx  (~(all sign:psbt tx) keys)
    =+  ^=  remote-sig
        %-  cat:byt:bcu:bc
        ~[current-commitment-signature.local-config 1^0x1]
    =.  tx
      %^    ~(add-signature update:psbt tx)
          0
        pub.multisig-key.her.config.c
      remote-sig
    ~|  %incomplete-force-close-tx
    ?>  (is-complete:psbt tx)
    tx
  ::
  ++  has-pending-changes
    |=  subject=owner
    ^-  ?
    =+  next-htlcs=(~(in-next-commitment htlcs c) subject)
    =+  latest-htlcs=(~(in-latest-commitment htlcs c) subject)
    ?!  ?&  =(next-htlcs latest-htlcs)
            =((next-feerate subject) (latest-feerate subject))
        ==
  ::
  ++  has-expiring-htlcs
    |=  block=@ud
    ^-  ?
    ::  TODO
    %.n
  --
::  +htlcs: htlc state manipulation
::
++  htlcs
  |_  c=chan
  ::
  ++  for-owner
    |=  =owner
    ^-  htlc-state
    ?-  owner
      %local   our.htlcs.c
      %remote  her.htlcs.c
    ==
  ::
  ++  feerate
    |=  [=owner =commitment-number]
    ^-  sats:bc
    ?<  ?&  (gth (lent fee-updates.our.htlcs.c) 1)
            (gth (lent fee-updates.her.htlcs.c) 1)
        ==
    =+  fee-log=fee-updates:(for-owner %local)
    =+  remote=fee-updates:(for-owner %remote)
    =?  fee-log  (gth (lent remote) 1)
      remote
    =+  left=0
    =+  right=(lent fee-log)
    |-
    =+  i=(div (add left right) 2)
    =+  update=(snag i fee-log)
    =+  ^=  ctn
        ?-  owner
          %local   local-commitment-number.update
          %remote  remote-commitment-number.update
        ==
    ?:  (lte (sub right left) 1)
      ?<  =((cmp:si (need ctn) commitment-number) --1)
      rate.update
    ?~  ctn
      $(right i)
    ?.  =((cmp:si u.ctn commitment-number) --1)
      $(left i)
    $(right i)
  ::
  ++  oldest-unrevoked-feerate
    |=  =owner
    ^-  sats:bc
    (feerate owner (oldest-unrevoked-cn owner))
  ::
  ++  latest-feerate
    |=  =owner
    ^-  sats:bc
    (feerate owner (latest-cn owner))
  ::
  ++  next-feerate
    |=  =owner
    ^-  sats:bc
    %+  feerate  owner
    %+  sum:si  --1
    (latest-cn owner)
  ::
  ++  balance
    |=  $:  whose=owner
            =commit=owner
            cn=commitment-number
            =initial=msats
        ==
    |^  ^-  msats
    (sub (add initial-msats recd-msats) sent-msats)
    ++  sent
      ^-  (map htlc-id htlc-info)
      settles:(for-owner whose)
    ::
    ++  recd
      ^-  (map htlc-id htlc-info)
      settles:(for-owner (invert-owner whose))
    ::
    ++  sent-msats
      ^-  msats
      %+  roll
      %+  turn  ~(tap in ~(key by sent))
        |=  =htlc-id
        =/  =htlc-info
          (~(got by sent) htlc-id)
        ?:  ?&  (~(has by htlc-info) commit-owner)
                (lte (~(got by htlc-info) commit-owner) cn)
            ==
            =/  htlc=update-add-htlc:msg
              (~(got by adds:(for-owner whose)) htlc-id)
            amount-msats.htlc
          0
      add
    ::
    ++  recd-msats
      ^-  msats
      %+  roll
      %+  turn  ~(tap in ~(key by recd))
        |=  =htlc-id
        =/  =htlc-info
          (~(got by recd) htlc-id)
        ?:  ?&  (~(has by htlc-info) commit-owner)
                (lte (~(got by htlc-info) commit-owner) cn)
            ==
          =/  htlc=update-add-htlc:msg
            (~(got by adds:(for-owner (invert-owner whose))) htlc-id)
          amount-msats.htlc
        0
      add
    --
  ::
  ++  next-id
    |=  =owner
    ^-  htlc-id
    next-htlc-id:(for-owner owner)
  ::
  ++  is-revack-pending
    |=  =owner
    ^-  ?
    revack-pending:(for-owner owner)
  ::
  ++  oldest-unrevoked-cn
    |=  =owner
    ^-  commitment-number
    commitment-number:(for-owner owner)
  ::
  ++  latest-cn
    |=  =owner
    ^-  commitment-number
    %+  sum:si
      (oldest-unrevoked-cn owner)
    ?:((is-revack-pending owner) --1 --0)
  ::
  ++  is-active
    |=  [=owner cn=commitment-number proposer=owner =htlc-id]
    ^-  ?
    ?:  (gte htlc-id (next-id proposer))
      %.n
    =+  proposer-htlcs=(for-owner proposer)
    =+  settles=settles.proposer-htlcs
    =+  fails=fails.proposer-htlcs
    =+  commits=(~(got by locked-in.proposer-htlcs) htlc-id)
    ?:  ?&  (~(has by commits) owner)
            !=((cmp:si (~(got by commits) owner) cn) --1)
        ==
      =*  a  (~(got by settles) htlc-id)
      =+  ^=  not-settled
        ?|  !(~(has by settles) htlc-id)
            !(~(has by a) owner)
            =((cmp:si (~(got by a) owner) cn) --1)
        ==
      =*  b  (~(got by fails) htlc-id)
      =+  ^=  not-failed
        ?|  !(~(has by fails) htlc-id)
            !(~(has by b) owner)
            =((cmp:si (~(got by b) owner) cn) --1)
        ==
      ?&(not-settled not-failed)
    %.n
  ::
  ++  by-direction
    |=  [subject=owner dir=direction cn=commitment-number]
    ^-  (list update-add-htlc:msg)
    =/  party=owner
      ?-  dir
        %sent      subject
        %received  (invert-owner subject)
      ==
    ::
    =+  ^=  htlcs
      ^-  (list htlc-id)
      %~  tap  in
      %~  key  by
      locked-in:(for-owner party)
    ::
    =.  htlcs
      %+  skim  htlcs
      |=  =htlc-id
      (is-active subject cn party htlc-id)
    ::
    %+  turn  htlcs
    |=  =htlc-id
    (~(got by adds:(for-owner party)) htlc-id)
  ::
  ++  by-id
    |=  [=owner =htlc-id]
    ^-  update-add-htlc:msg
    (~(got by adds:(for-owner owner)) htlc-id)
  ::
  ++  all
    |=  [subject=owner cn=(unit commitment-number)]
    ^-  (list (pair direction update-add-htlc:msg))
    =+  ctn=(fall cn (oldest-unrevoked-cn subject))
    %+  welp
    %+  turn  (by-direction subject %sent ctn)
    |=  h=update-add-htlc:msg  [%sent h]
    %+  turn  (by-direction subject %received ctn)
    |=  h=update-add-htlc:msg  [%received h]
  ::
  ++  in-oldest-unrevoked-commitment
    |=  subject=owner
    ^-  (list (pair direction update-add-htlc:msg))
    %+  all  subject
    %-  some
    (oldest-unrevoked-cn subject)
  ::
  ++  in-latest-commitment
    |=  subject=owner
    ^-  (list (pair direction update-add-htlc:msg))
    %+  all  subject
    %-  some
    (latest-cn subject)
  ::
  ++  in-next-commitment
    |=  subject=owner
    ^-  (list (pair direction update-add-htlc:msg))
    %+  all  subject
    %-  some
    %+  sum:si  --1
    (latest-cn subject)
  ::
  ++  all-settled-htlcs-by-direction
    |=  [subject=owner =direction cn=(unit commitment-number)]
    ^-  (list update-add-htlc:msg)
    =+  ctn=(fall cn (oldest-unrevoked-cn subject))
    =+  party=?:(=(direction %sent) subject (invert-owner subject))
    =+  settles=settles:(for-owner party)
    =+  adds=adds:(for-owner party)
    %-  head
    %+  ~(rib by settles)  *(list update-add-htlc:msg)
    |=  [[k=htlc-id v=htlc-info] acc=(list update-add-htlc:msg)]
    ?:  ?&  (~(has by v) party)
            (lte (~(got by v) party) ctn)
        ==
      :-  (snoc acc (~(got by adds) k))
      [k v]
    [acc [k v]]
  ::
  ++  channel-open-finished
    ^-  chan
    %=  c
      commitment-number.our.htlcs  --0
      commitment-number.her.htlcs  --0
    ::
      revack-pending.our.htlcs  %.n
      revack-pending.her.htlcs  %.n
    ==
  ::
  ++  send
    |=  h=update-add-htlc:msg
    ^-  (pair update-add-htlc:msg chan)
    ~|  %unexpected-htlc-id
    ?>  =(next-htlc-id.our.htlcs.c htlc-id.h)
    :-  h
    %=    c
        adds.our.htlcs
      %+  ~(put by adds.our.htlcs.c)
        htlc-id.h
      h
    ::
        locked-in.our.htlcs
      %+  ~(put by locked-in.our.htlcs.c)
        htlc-id.h
      (malt ~[remote+(sum:si (latest-cn %remote) --1)])
    ::
        next-htlc-id.our.htlcs
      +(next-htlc-id.our.htlcs.c)
    ==
  ::
  ++  receive
    |=  h=update-add-htlc:msg
    ^-  (pair update-add-htlc:msg chan)
    ~|  %unexpected-htlc-id
    ?>  =(next-htlc-id.her.htlcs.c htlc-id.h)
    :-  h
    %=    c
        adds.her.htlcs
      %+  ~(put by adds.her.htlcs.c)
        htlc-id.h
      h
    ::
        locked-in.her.htlcs
      %+  ~(put by locked-in.her.htlcs.c)
        htlc-id.h
      (malt ~[local+(sum:si (latest-cn %local) --1)])
    ::
        next-htlc-id.her.htlcs
      +(next-htlc-id.her.htlcs.c)
    ==
  ::
  ++  send-settle
    |=  =htlc-id
    ^-  chan
    =+  next-ctn=(sum:si (latest-cn %remote) --1)
    ?.  (is-active %remote next-ctn %remote htlc-id)
      ~|(%no-active-htlc !!)
    %=    c
        settles.her.htlcs
      %+  ~(put by settles.her.htlcs.c)
        htlc-id
      (malt ~[remote+next-ctn])
    ==
  ::
  ++  receive-settle
    |=  =htlc-id
    ^-  chan
    =+  next-ctn=(sum:si (latest-cn %local) --1)
    ?.  (is-active %local next-ctn %local htlc-id)
      ~|(%no-active-htlc !!)
    %=    c
        settles.our.htlcs
      %+  ~(put by settles.our.htlcs.c)
        htlc-id
      (malt ~[local+next-ctn])
    ==
  ::
  ++  send-fail
    |=  =htlc-id
    ^-  chan
    =+  next-ctn=(sum:si (latest-cn %remote) --1)
    ?.  (is-active %remote next-ctn %remote htlc-id)
      ~|(%no-active-htlc !!)
    %=    c
        fails.her.htlcs
      %+  ~(put by fails.her.htlcs.c)
        htlc-id
      (malt ~[remote+next-ctn])
    ==
  ::
  ++  receive-fail
    |=  =htlc-id
    ^-  chan
    =+  next-ctn=(sum:si (latest-cn %local) --1)
    ?.  (is-active %local next-ctn %local htlc-id)
      ~|(%no-active-htlc !!)
    %=    c
        fails.our.htlcs
      %+  ~(put by fails.our.htlcs.c)
        htlc-id
      (malt ~[local+next-ctn])
    ==
  ::
  ++  send-update-fee
    |=  feerate=sats:bc
    ^-  chan
    =|  =fee-update
    =.  rate.fee-update
      feerate
    =.  remote-commitment-number.fee-update
      `(sum:si (latest-cn %remote) --1)
    %=    c
        fee-updates.our.htlcs
      (append-to-fee-updates fee-updates.our.htlcs.c fee-update)
    ==
  ::
  ++  receive-update-fee
    |=  feerate=sats:bc
    ^-  chan
    =|  =fee-update
    =.  rate.fee-update
      feerate
    =.  local-commitment-number.fee-update
      `(sum:si (latest-cn %local) --1)
    %=    c
        fee-updates.her.htlcs
      (append-to-fee-updates fee-updates.her.htlcs.c fee-update)
    ==
  ::
  ++  append-to-fee-updates
    |=  [updates=(list fee-update) update=fee-update]
    ^-  (list fee-update)
    =+  n=(lent updates)
    ?:  =(0 n)  ~[update]
    =+  last=(snag (dec n) updates)
    ?:  ?&  ?|  ?=(~ local-commitment-number.last)
                (gth u.local-commitment-number.last (latest-cn %local))
            ==
            ?|  ?=(~ remote-commitment-number.last)
                (gth u.remote-commitment-number.last (latest-cn %remote))
            ==
        ==
      (snap updates (dec n) update)
    (snoc updates update)
  ::
  ++  send-commitment
    ^-  chan
    ?>  =((latest-cn %remote) (oldest-unrevoked-cn %remote))
    c(revack-pending.her.htlcs %.y)
  ::
  ++  receive-commitment
    ^-  chan
    ?>  =((latest-cn %local) (oldest-unrevoked-cn %local))
    c(revack-pending.our.htlcs %.y)
  ::
  ++  send-revocation
    |^  ^-  chan
    %=    c
        commitment-number.our.htlcs  (sum:si commitment-number.our.htlcs.c --1)
        revack-pending.our.htlcs     %.n
    ::
        locked-in.her.htlcs
      (~(run by locked-in.her.htlcs.c) update-locked)
    ::
        settles.our.htlcs
      (~(rut by settles.our.htlcs.c) update-htlc-info)
    ::
        fails.our.htlcs
      (~(rut by fails.our.htlcs.c) update-htlc-info)
    ::
        fee-updates.her.htlcs
      (turn fee-updates.her.htlcs.c update-fee)
    ==
    ++  update-locked
      |=  info=htlc-info
      ^-  htlc-info
      ?:  ?&  !(~(has by info) %remote)
              !=((cmp:si (~(got by info) %local) (latest-cn %local)) --1)
          ==
        (~(put by info) %remote (sum:si (latest-cn %remote) --1))
      info
    ::
    ++  update-htlc-info
      |=  [id=htlc-id info=htlc-info]
      ^-  htlc-info
      ?:  ?&  (~(has by locked-in.our.htlcs.c) id)
              !(~(has by info) %remote)
              !=((cmp:si (~(got by info) %local) (latest-cn %local)) --1)
          ==
        (~(put by info) %remote (sum:si (latest-cn %remote) --1))
      info
    ::
    ++  update-fee
      |=  update=fee-update
      ^-  fee-update
      ?:  ?&  ?=(~ remote-commitment-number.update)
              ?=(^ local-commitment-number.update)
              !=((cmp:si u.local-commitment-number.update (latest-cn %local)) --1)
          ==
        update(remote-commitment-number `(sum:si (latest-cn %remote) --1))
      update
    --
  ::
  ++  receive-revocation
    |^  ^-  chan
    %=    c
        commitment-number.her.htlcs  (sum:si commitment-number.her.htlcs.c --1)
        revack-pending.her.htlcs     %.n
    ::
        locked-in.our.htlcs
      (~(run by locked-in.our.htlcs.c) update-locked)
    ::
        settles.her.htlcs
      (~(rut by settles.her.htlcs.c) update-htlc-info)
    ::
        fails.her.htlcs
      (~(rut by fails.her.htlcs.c) update-htlc-info)
    ::
        fee-updates.our.htlcs
      (turn fee-updates.our.htlcs.c update-fee)
    ==
    ++  update-locked
      |=  info=htlc-info
      ^-  htlc-info
      ?:  ?&  !(~(has by info) %local)
              !=((cmp:si (~(got by info) %remote) (latest-cn %remote)) --1)
          ==
        (~(put by info) %local (sum:si (latest-cn %local) --1))
      info
    ::
    ++  update-htlc-info
      |=  [id=htlc-id info=htlc-info]
      ^-  htlc-info
      ?:  ?&  (~(has by locked-in.her.htlcs.c) id)
              !(~(has by info) %local)
              !=((cmp:si (~(got by info) %remote) (latest-cn %remote)) --1)
          ==
        (~(put by info) %local (sum:si (latest-cn %local) --1))
      info
    ::
    ++  update-fee
      |=  update=fee-update
      ^-  fee-update
      ?:  ?&  ?=(~ local-commitment-number.update)
              ?=(^ remote-commitment-number.update)
              !=((cmp:si u.remote-commitment-number.update (latest-cn %remote)) --1)
          ==
        update(local-commitment-number `(sum:si (latest-cn %local) --1))
      update
    --
  --
--
