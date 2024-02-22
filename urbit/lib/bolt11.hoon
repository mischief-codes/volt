::  BOLT 11: Invoice Protocol for Lightning Payments
::  https://github.com/lightningnetwork/lightning-rfc/blob/master/11-payment-encoding.md
::
/+  bc=bitcoin
|%
+$  network     ?(network:bc %signet %regtest)
+$  multiplier  ?(%m %u %n %p)
+$  amount      [@ud (unit multiplier)]
::
++  bcu         bcu:bc
::
++  prefixes
  ^-  (map network tape)
  %-  my
  :~  [%main "bc"]
      [%testnet "tb"]
      [%signet "tbs"]
      [%regtest "bcrt"]
  ==
::
++  networks
  ^-  (map @t network)
  %-  my
  :~  ['bc' %main]
      ['tb' %testnet]
      ['tbs' %signet]
      ['bcrt' %regtest]
  ==
::
++  base58-prefixes
  ^-  (map network [@ @])
  %-  my
  :~  [%main [0 5]]
      [%testnet [111 196]]
  ==
::
+$  signature
  $:  v=@
      r=@
      s=@
  ==
::
+$  invoice
  $:  =network
      timestamp=time
      payment-hash=hexb:bc
      payment-secret=(unit hexb:bc)
      =signature
      pubkey=hexb:bc
      expiry=@dr
      min-final-cltv-expiry=@ud
      amount=(unit amount)
      description=(unit @t)
      description-hash=(unit hexb:bc)
      unknown-tags=(map @tD hexb:bc)
      fallback-address=(unit address:bc)
      route=(list route)
      feature-bits=bits:bc
  ==
::
+$  route
  $:  pubkey=hexb:bc
      short-channel-id=@ud
      feebase=@ud
      feerate=@ud
      cltv-expiry-delta=@ud
  ==
::
++  valid-amount
  |=  amt=(unit amount)
  ?|  =(amt ~)
      ?&(=(+.amt %p) =((mod -.amt 10) 0))
      %.y
  ==
::  sats = 10^-8
::  msat = 10^-11
::  mbtc = 10^-3  -> 11-3  =  8
::  ubtc = 10^-6  -> 11-6  =  5
::  nbtc = 10^-9  -> 11-9  =  2
::  pbtc = 10^-12 -> 11-12 = -1
::
++  amount-to-msats
  |=  =amount
  ^-  @ud
  =/  [q=@ud mult=(unit multiplier)]
    amount
  ?~  mult  (mul 100.000.000.000 q)
  ?-  u.mult
    %m  (mul q 100.000.000)
    %u  (mul q 100.000)
    %n  (mul q 100)
    %p  (div q 10)
  ==
::
++  msats-to-amount
  |=  msats=@
  ^-  amount
  [(mul 10 msats) `%p]
::
++  to-hexb
  |=  =bits:bc
  :*  wid=(div wid.bits 8)
      dat=`@ux`(rsh [0 (mod wid.bits 8)] dat.bits)
  ==
::
++  to-bits
  |=  a=@
  ^-  bits:bc
  [wid=(met 0 a) dat=`@ub`a]
::
++  to-bytes
  |=  a=@
  ^-  hexb:bc
  [wid=(met 3 a) dat=`@ux`a]
::
++  tape-to-bits
  |=  =tape
  ^-  bits:bc
  :*  wid=(mul (lent tape) 8)
      dat=`@ub`(swp 3 (crip tape))
  ==
::
++  read-bits
  |=  [n=@ bs=bits:bc]
  [(take:bit:bcu n bs) (drop:bit:bcu n bs)]
::
++  pad-bits
  |=  [m=@ data=bits:bc]
  ^-  bits:bc
  |-
  ?:  =(0 (mod wid.data m))  data
  %=  $  data
    :*  wid=(add wid.data 1)
        dat=(lsh [0 1] dat.data)
     ==
  ==
::
++  left-pad-bits
  |=  [n=@ud a=bits:bc]
  |-
  ?:  =(0 (mod wid.a n))  a
  $(wid.a (add 1 wid.a))
::
++  bytes-to-bits
  |=  =hexb:bc
  [wid=(mul wid.hexb 8) dat=`@ub`dat.hexb]
::
++  sig-wid  (mul 8 65)
::
++  extract-signature
  |=  =bits:bc
  :-  (cut 3 [0 65] dat.bits)
  :*  wid=(sub wid.bits sig-wid)
      dat=(rsh [0 sig-wid] dat.bits)
  ==
::
++  decode-signature
  |=  sig=@
  =/  v=@  (dis sig 0xff)
  =.  sig  (rsh [3 1] sig)
  =/  s=@  (cut 4 [0 16] sig)
  =/  r=@  (rsh [3 32] sig)
  [v=v r=r s=s]
::  +recover-pubkey: recover public key from signature
::  returns compressed public key (as hexb)
::
++  recover-pubkey
  =,  secp:crypto
  |=  [sig=signature hrp=tape raw=bits:bc]
  ^-  (unit hexb:bc)
  ?.  (lte v.sig 3)
    ~&  >>>  "%recover-pubkey: invalid recid {<v.sig>}"
    ~
  =/  hash=@  (signature-hash hrp raw)
  =+  point=(ecdsa-raw-recover:secp256k1 hash sig)
  (some 33^(compress-point:secp256k1 point))
::
++  sign-data
  =,  secp:crypto
  |=  [key=hexb:bc hrp=tape data=bits:bc]
  ^-  bits:bc
  =/  hash=@  (signature-hash hrp data)
  =+  (ecdsa-raw-sign:secp256k1 hash dat.key)
  %-  cat:bit:bcu
  :~  data
      [wid=(mul 32 8) dat=r]
      [wid=(mul 32 8) dat=s]
      [wid=8 dat=v]
  ==
::
++  signature-hash
  |=  [hrp=tape raw=bits:bc]
  |^  ^-  @
  dat:hash
  ::
  ++  hash
    ^-  hexb:bc
    %-  sha256:bcu
    %-  to-hexb
    %-  cat:bit:bcu
    ~[(tape-to-bits hrp) (pad-bits 8 raw)]
  --
::
++  parse-fallback
  |=  [=network f=bits:bc]
  ^-  (unit address:bc)
  ?.  ?|(=(network %main) =(network %testnet))  ~
  =^  wver=bits:bc  f  (read-bits 5 f)
  ?:  =(dat.wver 17)
    %+  bind  (~(get by base58-prefixes) network)
    |=  n=[@ @]
    =/  b=bits:bc
      %-  cat:bit:bcu
      ~[[wid=8 dat=`@ub`-.n] f]
    [%base58 `@uc`dat.b]
  ::
  ?:  =(dat.wver 18)
    %+  bind  (~(get by base58-prefixes) network)
    |=  n=[@ @]
    =/  b=bits:bc
      %-  cat:bit:bcu
      ~[[wid=8 dat=`@ub`+.n] f]
    [%base58 `@uc`dat.b]
  ::
  ?:  (lte dat.wver 16)
    %+  bind  (~(get by prefixes) network)
    |=  prefix=tape
    =/  enc=cord
      %+  encode-raw:bech32  prefix
      [0v0 (to-atoms:bit:bcu 5 f)]
    [%bech32 enc]
  ~
::
++  encode-fallback
  |=  [=network =address:bc]
  ^-  bits:bc
  ?-    -.address
      %bech32
    %-  need
    %+  bind  (decode-raw:bech32 +.address)
    |=  raw=raw-decoded:bech32
    =/  data=bits:bc  (from-atoms:bit:bcu 5 data.raw)
    =/  wver=@ud      dat:(read-bits 8 data)
    ~|  "Invalid witness version {<wver>}"
    ?>  (lte wver 16)
    data
  ::
      %base58
    =/  addr=hexb:bc  [21 `@ux`+.address]
    =/  byte=hexb:bc  (take:byt:bcu 1 addr)
    =/  wver=@
      ?:  (is-p2pkh network dat.byte)  17
      ?:  (is-p2sh network dat.byte)   18
      ~|("Unknown address for type {<network>}" !!)
    %-  cat:bit:bcu
    :~  [wid=5 dat=wver]
        %-  bytes-to-bits
        %+  drop:byt:bcu  1
        addr
    ==
  ==
::
++  is-p2pkh
  |=  [n=network c=@]
  ^-  ?
  %-  need
  %+  bind  (~(get by base58-prefixes) n)
  |=  p=[@ @]  =(c -.p)
::
++  is-p2sh
  |=  [n=network c=@]
  ^-  ?
  %-  need
  %+  bind  (~(get by base58-prefixes) n)
  |=  p=[@ @]  =(c +.p)
::
++  tagged
  |=  [t=@tD b=bits:bc]
  ^-  bits:bc
  =/  c=@  (need (charset-to-value:bech32 t))
  =.  b    (pad-bits 5 b)
  %-  cat:bit:bcu
  :~  [wid=5 dat=c]
      [wid=5 dat=(div (div wid.b 5) 32)]
      [wid=5 dat=(mod (div wid.b 5) 32)]
      b
  ==
::
++  tagged-bytes
  |=  [tag=@tD bytes=hexb:bc]
  ^-  bits:bc
  %+  tagged  tag
  %-  bytes-to-bits  bytes
::
++  pull-tagged
  |=  in=bits:bc
  ^-  [[(unit @tD) @ud bits:bc] bits:bc]
  =^  typ  in  (read-bits 5 in)
  =^  hig  in  (read-bits 5 in)
  =^  low  in  (read-bits 5 in)
  =/  len      (add (mul dat.hig 32) dat.low)
  =^  dta  in  (read-bits (mul len 5) in)
  =/  tag      (value-to-charset:bech32 dat.typ)
  [[tag len dta] in]
::
++  en
  |=  [in=invoice key=hexb:bc]
  |^  ^-  cord
  =/  hrp=tape     (encode-hrp in)
  =/  inv=bits:bc  (encode-invoice in)
  %+  encode-raw:bech32  hrp
  %+  to-atoms:bit:bcu  5
  %^    sign-data
      key
    hrp
  inv
  ::
  ++  encode-invoice
    |=  in=invoice
    ^-  bits:bc
    =|  data=bits:bc
    =/  unix=@ud
      %+  div
      %+  sub  timestamp.in  ~1970.1.1
      ~s1
    ::
    =.  data
    %-  cat:bit:bcu  ~[data [wid=35 dat=`@ub`unix]]
    ::
    =.  data
    %-  cat:bit:bcu
    ~[data (tagged-bytes 'p' payment-hash.in)]
    ::
    =?  data  ?=(^ payment-secret.in)
    %-  cat:bit:bcu
    :~  data
      %+  tagged-bytes  's'
      %-  need  payment-secret.in
    ==
    ::
    =?  data  !=(~ route.in)
    %-  cat:bit:bcu
    :~  data
      %+  tagged  'r'
      %+  roll  route.in
      |=  [r=route acc=bits:bc]
      %-  cat:bit:bcu
      :~  acc
          [wid=264 dat=`@ub`dat.pubkey.r]
          [wid=64 dat=`@ub`short-channel-id.r]
          [wid=32 dat=`@ub`feebase.r]
          [wid=32 dat=`@ub`feerate.r]
          [wid=16 dat=`@ub`cltv-expiry-delta.r]
      ==
    ==
    ::
    =?  data  ?=(^ fallback-address.in)
    %-  cat:bit:bcu
    :~  data
      %+  tagged  'f'
      %+  encode-fallback  network.in
      %-  need  fallback-address.in
    ==
    ::
    =.  data
    %-  cat:bit:bcu
    :~  data
      %+  tagged  'c'
      %+  left-pad-bits  5
      %-  to-bits  min-final-cltv-expiry.in
    ==
    ::
    =?  data  ?=(^ description.in)
    =/  desc  (need description.in)
    %-  cat:bit:bcu
    :~  data
      %+  tagged-bytes  'd'
      %-  to-bytes  (swp 3 desc)
    ==
    ::
    =?  data  !=(~h1 expiry.in)
    %-  cat:bit:bcu
    :~  data
      %+  tagged  'x'
      %+  left-pad-bits  5
      %-  to-bits
      (div expiry.in ~s1)
    ==
    ::
    =?  data  ?=(^ description-hash.in)
    %-  cat:bit:bcu
    :~  data
      %+  tagged-bytes  'h'
      %-  need  description-hash.in
    ==
    ::
    =?  data  !=(0 wid.pubkey.in)
    %-  cat:bit:bcu
    ~[data (tagged-bytes 'n' pubkey.in)]
    ::
    =?  data  !=(0 dat.feature-bits.in)
    %-  cat:bit:bcu
    ~[data (tagged '9' feature-bits.in)]
    ::
    data
  ::
  ++  encode-hrp
    |=  =invoice
    |^  ^-  tape
    ;:  weld  "ln"
      %-  network-to-tape  network.invoice
      %-  amount-to-tape   amount.invoice
    ==
    ::
    ++  network-to-tape
      |=  =network
      (need (~(get by prefixes) network))
    ::
    ++  amount-to-tape
      |=  amt=(unit amount)
      %+  fall
      %+  bind  amt
      |=  =amount
      %+  weld
        %+  murn
        %+  scow  %ud  -.amount
        |=(a=@tD ?:(=(a '.') ~ (some a)))
        ::
        %+  fall
        %+  bind  +.amount
        |=  =multiplier
        (scow %tas multiplier)
        ""
      ""
    --
  --
::
++  de
  |=  body=cord
  |^  ^-  (unit invoice)
  %+  biff  (decode-raw:bech32 body)
  |=  raw=raw-decoded:bech32
  =/  =bits:bc  (from-atoms:bit:bcu 5 data.raw)
  ?:  (lth wid.bits sig-wid)
    ~&  >>>  '&de: too short to contain a signature'
    ~
  %+  biff  (rust hrp.raw hum)
  |=  [=network amt=(unit amount)]
  ?.  (valid-amount amt)
    ~&  >>>  '&de: invalid amount'
    ~
  =^  sig=@  bits  (extract-signature bits)
  =/  sig-data=bits:bc  bits
  =|  =invoice
  =:  network.invoice    network
      amount.invoice     amt
      signature.invoice  (decode-signature sig)
      expiry.invoice     ~s3600
      min-final-cltv-expiry.invoice  18
  ==
  =^  date  bits  (read-bits 35 bits)
  =.  timestamp.invoice
    %-  from-unix:chrono:userlib  dat.date
  |-
  ?.  =(0 wid.bits)
  =^  datum  bits  (pull-tagged bits)
  %_  $
    bits     bits
    invoice  (add-tagged invoice datum)
  ==
  ?.  =(0 wid.pubkey.invoice)  (some invoice)
  %+  bind  (recover-pubkey signature.invoice hrp.raw sig-data)
  |=  key=hexb:bc  invoice(pubkey key)
  ::
  ++  add-tagged
    |=  [=invoice tag=(unit @tD) len=@ud data=bits:bc]
    ^-  ^invoice
    ?~  tag  invoice
    ?:  =(u.tag 'p')
      ?.  =(len 52)
        (unknown-tag invoice u.tag data)
      invoice(payment-hash (to-hexb data))
    ::
    ?:  =(u.tag 's')
      ?.  =(len 52)
        (unknown-tag invoice u.tag data)
      invoice(payment-secret (some (to-hexb data)))
    ::
    ?:  =(u.tag 'd')
      =/  bytes  (to-hexb data)
      =/  desc
        %-  some
        ^-  @t
        %+  swp  3  dat.bytes
      invoice(description desc)
    ::
    ?:  =(u.tag 'h')
      ?.  =(len 52)
        (unknown-tag invoice u.tag data)
      invoice(description-hash (some (to-hexb data)))
    ::
    ?:  =(u.tag 'n')
      ?.  =(len 53)
        (unknown-tag invoice u.tag data)
      invoice(pubkey (to-hexb data))
    ::
    ?:  =(u.tag 'x')
      invoice(expiry `@dr`(mul ~s1 dat.data))
    ::
    ?:  =(u.tag 'c')
      invoice(min-final-cltv-expiry `@ud`dat.data)
    ::
    ?:  =(u.tag 'f')
      invoice(fallback-address (parse-fallback network.invoice data))
    ::
    ?:  =(u.tag 'r')
      =|  routes=(list route)
      |-
      =|  =route
      ?:  (lth wid.data route-lent)
        invoice(route (flop routes))
      =^  pkey  data  (read-bits 264 data)
      =^  chid  data  (read-bits 64 data)
      =^  febs  data  (read-bits 32 data)
      =^  fert  data  (read-bits 32 data)
      =^  xpry  data  (read-bits 16 data)
      =:  pubkey.route             (to-hexb pkey)
          short-channel-id.route   dat.chid
          feebase.route            dat.febs
          feerate.route            dat.fert
          cltv-expiry-delta.route  dat.xpry
      ==
      $(routes [route routes], data data)
    ::
    ?:  =(u.tag '9')
      invoice(feature-bits data)
    ::
    (unknown-tag invoice u.tag data)
  ::
  ++  unknown-tag
    |=  [=invoice tag=@tD =bits:bc]
    invoice(unknown-tags (~(put by unknown-tags.invoice) tag (to-hexb bits)))
  ::
  ++  route-lent  ^~
    %+  add  264
    %+  add  64
    %+  add  32
    %+  add  32
    16
  ::
  ++  hum  ;~(pfix pre ;~(plug net ;~(pose ;~((bend) (easy ~) amt) (easy ~))))
  ++  pre  (jest 'ln')
  ++  net
    %+  sear  ~(get by networks)
    ;~  pose
      (jest 'bcrt')
      (jest 'bc')
      (jest 'tbs')
      (jest 'tb')
    ==
  ++  mpy  (cook multiplier (mask "munp"))
  ++  amt
    ;~  plug
      (cook @ud dem)
      (cook (unit multiplier) ;~((bend) (easy ~) mpy))
    ==
  --
::
::  need modified bech32 decoder because 90 char length restriction is lifted
::
++  bech32
  =,  bc
  =,  bcu
  |%
  ++  charset  "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
  +$  raw-decoded  [hrp=tape data=(list @) checksum=(list @)]
  ::  below is a port of: https://github.com/bitcoinjs/bech32/blob/master/index.js
  ::
  ++  polymod
    |=  values=(list @)
    |^  ^-  @
    =/  gen=(list @ux)
      ~[0x3b6a.57b2 0x2650.8e6d 0x1ea1.19fa 0x3d42.33dd 0x2a14.62b3]
    =/  chk=@  1
    |-  ?~  values  chk
    =/  top  (rsh [0 25] chk)
    =.  chk
      (mix i.values (lsh [0 5] (dis chk 0x1ff.ffff)))
    $(values t.values, chk (update-chk chk top gen))
  ::
    ++  update-chk
      |=  [chk=@ top=@ gen=(list @ux)]
      =/  is  (gulf 0 4)
      |-  ?~  is  chk
      ?:  =(1 (dis 1 (rsh [0 i.is] top)))
        $(is t.is, chk (mix chk (snag i.is gen)))
      $(is t.is)
    --
  ::
  ++  expand-hrp
    |=  hrp=tape
    ^-  (list @)
    =/  front  (turn hrp |=(p=@tD (rsh [0 5] p)))
    =/  back   (turn hrp |=(p=@tD (dis 31 p)))
    (zing ~[front ~[0] back])
  ::
  ++  verify-checksum
    |=  [hrp=tape data-and-checksum=(list @)]
    ^-  ?
    %-  |=(a=@ =(1 a))
    %-  polymod
    (weld (expand-hrp hrp) data-and-checksum)
  ::
  ++  checksum
    |=  [hrp=tape data=(list @)]
    ^-  (list @)
    ::  xor 1 with the polymod
    ::
    =/  pmod=@
      %+  mix  1
      %-  polymod
      (zing ~[(expand-hrp hrp) data (reap 6 0)])
    %+  turn  (gulf 0 5)
    |=(i=@ (dis 31 (rsh [0 (mul 5 (sub 5 i))] pmod)))
  ::
  ++  charset-to-value
    |=  c=@tD
    ^-  (unit @)
    (find ~[c] charset)
  ++  value-to-charset
    |=  value=@
    ^-  (unit @tD)
    ?:  (gth value 31)  ~
    `(snag value charset)
  ::
  ++  is-valid
    |=  [bech=tape last-1-pos=@]  ^-  ?
    ::  to upper or to lower is same as bech
    ?&  ?|(=((cass bech) bech) =((cuss bech) bech))
        (gte last-1-pos 1)
        (lte (add last-1-pos 7) (lent bech))
    ::  (lte (lent bech) 90)
        (levy bech |=(c=@tD (gte c 33)))
        (levy bech |=(c=@tD (lte c 126)))
    ==
  ::  data should be 5bit words
  ::
  ++  encode-raw
    |=  [hrp=tape data=(list @)]
    ^-  cord
    =/  combined=(list @)
      (weld data (checksum hrp data))
    %-  crip
    (zing ~[hrp "1" (tape (murn combined value-to-charset))])
  ::
  ++  decode-raw
    |=  body=cord
    ^-  (unit raw-decoded)
    =/  bech  (cass (trip body))              ::  to lowercase
    =/  pos  (flop (fand "1" bech))
    ?~  pos  ~
    =/  last-1=@  i.pos
    ::  check bech32 validity (not segwit validity or checksum)
    ?.  (is-valid bech last-1)
      ~
    =/  hrp  (scag last-1 bech)
    =/  encoded-data-and-checksum=(list @)
      (slag +(last-1) bech)
    =/  data-and-checksum=(list @)
      %+  murn  encoded-data-and-checksum
      charset-to-value
    ::  ensure all were in CHARSET
    ?.  =((lent encoded-data-and-checksum) (lent data-and-checksum))
      ~
    ?.  (verify-checksum hrp data-and-checksum)
      ~
    =/  checksum-pos  (sub (lent data-and-checksum) 6)
    `[hrp (scag checksum-pos data-and-checksum) (slag checksum-pos data-and-checksum)]
  ::  +from-address: BIP173 bech32 address encoding to hex
  ::  https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki
  ::  expects to drop a leading 5-bit 0 (the witness version)
  ::
  ++  from-address
    |=  body=cord
    ^-  hexb
    ~|  "Invalid bech32 address"
    =/  d=(unit raw-decoded)  (decode-raw body)
    ?>  ?=(^ d)
    =/  bs=bits  (from-atoms:bit 5 data.u.d)
    =/  byt-len=@  (div (sub wid.bs 5) 8)
    ?>  =(5^0b0 (take:bit 5 bs))
    ?>  ?|  =(20 byt-len)
            =(32 byt-len)
        ==
    [byt-len `@ux`dat:(take:bit (mul 8 byt-len) (drop:bit 5 bs))]
  ::  pubkey is the 33 byte ECC compressed public key
  ::
  ++  encode-pubkey
    |=  [network=?(%main %testnet %regtest) pubkey=byts]
    ^-  (unit cord)
    ?.  =(33 wid.pubkey)
      ~|('pubkey must be a 33 byte ECC compressed public key' !!)
    =/  prefix  (~(get by prefixes) network)
    ?~  prefix  ~
    :-  ~
    %+  encode-raw  u.prefix
    [0v0 (to-atoms:bit 5 [160 `@ub`dat:(hash-160 pubkey)])]
  --
--
