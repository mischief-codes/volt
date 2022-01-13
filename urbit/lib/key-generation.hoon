/-  *bolt
/+  bc=bitcoin
=,  secp256k1:secp:crypto
|%
++  bcu  bcu:bc
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
