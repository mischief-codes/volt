/-  *bolt
/+  bc=bitcoin, bolt11=bolt-bolt11
/+  bip32, der, psbt
|%
++  bcu  bcu:bc
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
++  fee-by-weight
  |=  [feerate-per-kw=@ud weight=@ud]
  ^-  sats:bc
  (div (mul weight feerate-per-kw) 1.000)
::
++  htlc-sum
  |=  hs=(list update-add-htlc:msg)
  ^-  msats
  %+  roll  hs
  |=  [h=update-add-htlc:msg sum=msats]
  (add sum amount-msats.h)
::
++  bip32-prime
  ^-  @
  0x8000.0000
::
++  encode-key-family
  |=  =family:key
  ^-  @
  ?-  family
    %multisig         (con 0 bip32-prime)
    %revocation-base  (con 1 bip32-prime)
    %htlc-base        (con 2 bip32-prime)
    %payment-base     (con 3 bip32-prime)
    %delay-base       (con 4 bip32-prime)
    %revocation-root  (con 5 bip32-prime)
    %node-key         6
  ==
::
++  encode-coin-network
  |=  =network
  ^-  @
  ?-  network
    %main     0
    %testnet  1
    %regtest  2
  ==
::  +generate-keypair: make keypair from seed
::
++  generate-keypair
  |=  [seed=hexb:bc =network =family:key]
  ^-  pair:key
  =+  %-  derive-sequence:(from-seed:bip32 seed)
      :~  1.337
          (encode-coin-network network)
          (encode-key-family family)
          0  0
      ==
  [pub=pub prv=prv]
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
--
