/-  *bolt
/+  *test, bolt, bc=bitcoin, bcu=bitcoin-utils
|%
::  +channel: utilities for channel operation tests
::
++  channel
  |%
  ++  make-channel
    |=  $:  initiator=?
            anchor=?
            =local-funding=pubkey
            =remote-funding=pubkey
            =local=basepoints
            =remote=basepoints
            local-csv=blocks
            remote-csv=blocks
            =local-dust-limit=sats:bc
            =remote-dust-limit=sats:bc
            local-amount=msats
            remote-amount=msats
            =first-per-commitment=point
            =next-per-commitment=point
            local-seed=hexb:bc
            initial-feerate=(unit sats:bc)
        ==
    |^  ^-  chan
    :*
      id=chanid
      state=%open
      funding-output=funding-outpoint:tx-test
      constraints=constraints
      config=[our=local-cfg her=remote-cfg]
      htlcs=[our=local-htlc-state her=remote-htlc-state]
      revocations=*revocation-store
    ==
    ++  chanid
      %+  make-channel-id:bolt
        txid:funding-outpoint:tx-test
      pos:funding-outpoint:tx-test
    ::
    ++  initial-fee-update
      ^-  fee-update
      =|  =fee-update
      =.  rate.fee-update
        ?~  initial-feerate
          6.000
        u.initial-feerate
      =.  local-commitment-number.fee-update   `--0
      =.  remote-commitment-number.fee-update  `--0
      fee-update
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
        revack-pending  %.n
        fee-updates     ~[initial-fee-update]
      ==
    ::
    ++  local-cfg
      ^-  local-config
      =|  conf=local-config
      %=  conf
        ship                            ?:(initiator ~zod ~bus)
        basepoints                      local-basepoints
        pub.multisig-key                local-funding-pubkey
        prv.multisig-key
          prv:(generate-keypair:bolt local-seed %main %multisig)
        to-self-delay                   local-csv
        dust-limit-sats                 local-dust-limit-sats
        max-htlc-value-in-flight-msats  (mul (sats-to-msats:bolt 100.000.000) 5)
        max-accepted-htlcs              5
        initial-msats                   local-amount
        reserve-sats                    0
        per-commitment-secret-seed
          32^prv:(generate-keypair:bolt local-seed %main %revocation-root)
        funding-locked-received         %.y
        htlc-minimum-msats              1
        upfront-shutdown-script         0^0x0
        anchor-outputs                  anchor
        seed                            local-seed
      ==
    ::
    ++  remote-cfg
      ^-  remote-config
      =|  conf=remote-config
      %=  conf
        ship                            ?.(initiator ~zod ~bus)
        basepoints                      remote-basepoints
        pub.multisig-key                remote-funding-pubkey
        to-self-delay                   remote-csv
        dust-limit-sats                 remote-dust-limit-sats
        max-htlc-value-in-flight-msats  (mul (sats-to-msats:bolt 100.000.000) 5)
        max-accepted-htlcs              5
        initial-msats                   remote-amount
        reserve-sats                    0
        htlc-minimum-msats              1
        upfront-shutdown-script         0^0x0
        anchor-outputs                  anchor
        next-per-commitment-point       next-per-commitment-point
        current-per-commitment-point    first-per-commitment-point
      ==
    ::
    ++  constraints
      :*  initiator=initiator
          anchor-outputs=anchor
          capacity=sats:funding-outpoint:tx-test
          funding-tx-min-depth=3
      ==
    --
  ::
  ++  make-test-channels
    |=  $:  initial-feerate=(unit sats:bc)
            local-msats=(unit msats)
            remote-msats=(unit msats)
            eny=@uvJ
        ==
    ^-  [alice=chan bob=chan]
    =+  rng=~(. og eny)
    =^  funding-txid  rng  (rads:rng (bex 256))
    =+  funding-index=0
    =+  ^=  funding-sats
        ?:  ?&  ?=(^ local-msats)
                ?=(^ remote-msats)
            ==
          %-  msats-to-sats:bolt
          %+  add
            u.local-msats
          u.remote-msats
        (mul 100.000.000 10)
    =+  funding-outpoint=[txid=32^funding-txid pos=0 sats=funding-sats]
    ::
    =+  ^=  local-amount
        %+  fall  local-msats
        (div (sats-to-msats:bolt funding-sats) 2)
    ::
    =+  ^=  remote-amount
        %+  fall  remote-msats
        (div (sats-to-msats:bolt funding-sats) 2)
    ::
    =+  feerate=(fall initial-feerate 6.000)
    =^  alice-seed  rng  (rads:rng (bex 256))
    =+  alice-revocation-root=(generate-keypair:bolt 32^alice-seed %main %revocation-root)
    =+  alice-multisig=(generate-keypair:bolt 32^alice-seed %main %multisig)
    =+  alice-pubkey=pub.alice-multisig
    =+  ^=  alice-basepoints
        ^-  basepoints
        :*  revocation=(generate-keypair:bolt 32^alice-seed %main %revocation-base)
            payment=(generate-keypair:bolt 32^alice-seed %main %payment-base)
            delayed-payment=(generate-keypair:bolt 32^alice-seed %main %delay-base)
            htlc=(generate-keypair:bolt 32^alice-seed %main %htlc-base)
        ==
    =+  ^=  alice-first
        ^-  point
        %-  compute-commitment-point:secret:bolt
        %^    generate-from-seed:secret:bolt
            32^prv.alice-revocation-root
          first-index:secret:bolt
        ~
    ::
    =^  bob-seed  rng  (rads:rng (bex 256))
    =+  bob-revocation-root=(generate-keypair:bolt 32^bob-seed %main %revocation-root)
    =+  bob-multisig=(generate-keypair:bolt 32^bob-seed %main %multisig)
    =+  bob-pubkey=pub.bob-multisig
    =+  ^=  bob-basepoints
        ^-  basepoints
        :*  revocation=(generate-keypair:bolt 32^bob-seed %main %revocation-base)
            payment=(generate-keypair:bolt 32^bob-seed %main %payment-base)
            delayed-payment=(generate-keypair:bolt 32^bob-seed %main %delay-base)
            htlc=(generate-keypair:bolt 32^bob-seed %main %htlc-base)
        ==
    =+  ^=  bob-first
        ^-  point
        %-  compute-commitment-point:secret:bolt
        %^    generate-from-seed:secret:bolt
            32^prv.bob-revocation-root
          first-index:secret:bolt
        ~
    ::
    =+  ^=  alice
        %:  make-channel
          initiator=%.y
          anchor=%.n
          local-funding-pubkey=alice-pubkey
          remote-funding-pubkey=bob-pubkey
          local-basepoints=alice-basepoints
          remote-basepoints=bob-basepoints
          local-csv=5
          remote-csv=4
          local-dust-limit-sats=200
          remote-dust-limit-sats=1.300
          local-amount=local-amount
          remote-amount=remote-amount
          first-per-commitment-point=*point
          next-per-commitment-point=bob-first
          local-seed=32^alice-seed
          initial-feerate=`feerate
        ==
    ::
    =+  ^=  bob
        %:  make-channel
          initiator=%.n
          anchor=%.n
          local-funding-pubkey=bob-pubkey
          remote-funding-pubkey=alice-pubkey
          local-basepoints=bob-basepoints
          remote-basepoints=alice-basepoints
          local-csv=4
          remote-csv=5
          local-dust-limit-sats=1.300
          remote-dust-limit-sats=200
          local-amount=remote-amount
          remote-amount=local-amount
          first-per-commitment-point=*point
          next-per-commitment-point=alice-first
          local-seed=32^bob-seed
          initial-feerate=`feerate
        ==
    ::
    =.  commitment-number.our.htlcs.alice  --0
    =.  commitment-number.our.htlcs.bob    --0
    ::
    =+  alice-outputs=outputs:(~(latest-commitment channel:bolt alice) %local)
    =+  bob-outputs=outputs:(~(next-commitment channel:bolt bob) %remote)
    ?>  =(alice-outputs bob-outputs)
    ::
    =^  [sig-from-bob=hexb:bc a-htlc-sigs=(list hexb:bc)]  bob
      ~(sign-next-commitment channel:bolt bob)
    =^  [sig-from-alice=hexb:bc b-htlc-sigs=(list hexb:bc)]  alice
      ~(sign-next-commitment channel:bolt alice)
    ::
    ?>  =(0 (lent a-htlc-sigs))
    ?>  =(0 (lent b-htlc-sigs))
    ::
    =.  alice
      %+  ~(open-with-first-commitment-point channel:bolt alice)
        bob-first
      sig-from-bob
    ::
    =.  bob
      %+  ~(open-with-first-commitment-point channel:bolt bob)
        alice-first
      sig-from-alice
    ::
    =+  ^=  alice-second
        %-  compute-commitment-point:secret:bolt
        %^    generate-from-seed:secret:bolt
            32^prv.alice-revocation-root
          (dec first-index:secret:bolt)
        ~
    ::
    =+  ^=  bob-second
        %-  compute-commitment-point:secret:bolt
        %^    generate-from-seed:secret:bolt
            32^prv.bob-revocation-root
          (dec first-index:secret:bolt)
        ~
    ::
    =.  alice
      alice(next-per-commitment-point.her.config bob-second)
    ::
    =.  bob
      bob(next-per-commitment-point.her.config alice-second)
    ::
    [alice=alice bob=bob]
  --
::  +test-channel: test channel operations
::
++  test-channel
  =+  (make-test-channels:channel ~ ~ ~ `@uvJ`42)
  =+  preimage=32^(fil 3 32 0x1)
  =+  payment-hash=(sha256:bcu:bc preimage)
  =+  ^=  htlc
      ^-  update-add-htlc:msg
      =|  h=update-add-htlc:msg
      %=  h
        htlc-id       next-htlc-id.our.htlcs.alice
        payment-hash  payment-hash
        amount-msats  (sats-to-msats:bolt 100.000.000)
        cltv-expiry   5
      ==
  =^  alice-htlc  alice  (~(add-htlc channel:bolt alice) htlc)
  =^  bob-htlc    bob    (~(receive-htlc channel:bolt bob) htlc)
  |^
  ;:  weld
    %+  category  "check-concurrent-reversed-payment"
    check-concurrent-reversed-payment
  ::
    %+  category  "check-simple-add-settle-workflow"
    check-simple-add-settle-workflow
  ::
    %+  category  "check-update-fee-sender-commits"
    check-update-fee-sender-commits
  ::
    %+  category  "check-update-fee-receiver-commits"
    check-update-fee-receiver-commits
  ==
  ++  check-concurrent-reversed-payment
    =/  htlc-2=update-add-htlc:msg
      %=  htlc
        htlc-id       next-htlc-id.our.htlcs.bob
        payment-hash  (sha256:bcu:bc 32^(fil 3 32 0x2))
        amount-msats  (add amount-msats.htlc 1.000)
      ==
    =/  [bob-htlc=update-add-htlc:msg bob-2=chan]
      (~(add-htlc channel:bolt bob) htlc-2)
    =/  [alice-htlc=update-add-htlc:msg alice-2=chan]
      (~(receive-htlc channel:bolt alice) htlc-2)
    =/  [bob-sigs=(pair hexb:bc (list hexb:bc)) bob-3=chan]
      ~(sign-next-commitment channel:bolt bob-2)
    =/  alice-3=chan
      (~(receive-new-commitment channel:bolt alice-2) bob-sigs)
    =/  [alice-rev=revoke-and-ack:msg alice-4=chan]
      ~(revoke-current-commitment channel:bolt alice-3)
    ;:  weld
    ::  alice added the HTLC:
    ::
      %+  expect-eq
        !>  2
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-2) %local))
    ::
        %+  expect-eq
        !>  3
        !>  (lent outputs:(~(next-commitment channel:bolt alice-2) %local))
    ::
        %+  expect-eq
        !>  2
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-2) %remote))
    ::
        %+  expect-eq
        !>  3
        !>  (lent outputs:(~(next-commitment channel:bolt alice-2) %remote))
    ::  alice received bob's signatures:
    ::
        %+  expect-eq
        !>  3
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-3) %local))
    ::
        %+  expect-eq
        !>  3
        !>  (lent outputs:(~(next-commitment channel:bolt alice-3) %local))
    ::
        %+  expect-eq
        !>  2
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-3) %remote))
    ::
        %+  expect-eq
        !>  3
        !>  (lent outputs:(~(next-commitment channel:bolt alice-3) %remote))
    ::  alice revoked current commitment:
    ::
        %+  expect-eq
        !>  3
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-4) %local))
    ::
        %+  expect-eq
        !>  3
        !>  (lent outputs:(~(next-commitment channel:bolt alice-4) %local))
    ::
        %+  expect-eq
        !>  2
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-4) %remote))
    ::
        %+  expect-eq
        !>  4
        !>  (lent outputs:(~(next-commitment channel:bolt alice-4) %remote))
    ==
  ::
  ++  check-simple-add-settle-workflow
    =/  alice=chan  alice
    =/  bob=chan    bob
    =/  htlc=update-add-htlc:msg        htlc
    =/  bob-htlc=update-add-htlc:msg    bob-htlc
    =/  alice-htlc=update-add-htlc:msg  alice-htlc
    =/  one-bitcoin-in-msats=msats      (sats-to-msats:bolt 100.000.000)
    ::
    =+  ^=  local-outs
        ^-  (list output:psbt:bolt)
        %+  sort  outputs:(~(latest-commitment channel:bolt alice) %local)
        |=  [a=output:psbt:bolt b=output:psbt:bolt]
        (lte wid.script-pubkey.a wid.script-pubkey.b)
    ::
    =+  ^=  remote-outs
        ^-  (list output:psbt:bolt)
        %+  sort  outputs:(~(latest-commitment channel:bolt alice) %remote)
        |=  [a=output:psbt:bolt b=output:psbt:bolt]
        (lte wid.script-pubkey.a wid.script-pubkey.b)
    ::  Next alice commits this change by sending a signature message. Since
    ::  we expect the messages to be ordered, Bob will receive the HTLC we
    ::  just sent before he receives this signature, so the signature will
    ::  cover the HTLC.
    ::
    =/  [[alice-sig=signature alice-htlc-sigs=(list signature)] alice-2=chan]
      ~(sign-next-commitment channel:bolt alice)
    ::  Bob receives this signature message, and checks that this covers the
    ::  state he has in his remote log. This includes the HTLC just sent
    ::  from Alice.
    ::
    =/  bob-2=chan
      %+  ~(receive-new-commitment channel:bolt bob)
        alice-sig
      alice-htlc-sigs
    ::  Bob revokes his prior commitment given to him by Alice, since he now
    ::  has a valid signature for a newer commitment.
    ::
    =/  [bob-revocation=revoke-and-ack:msg bob-3=chan]
      ~(revoke-current-commitment channel:bolt bob-2)
    ::  Bob finally sends a signature for Alice's commitment transaction.
    ::  This signature will cover the HTLC, since Bob will first send the
    ::  revocation just created. The revocation also acks every received
    ::  HTLC up to the point where Alice sent her signature.
    ::
    =/  [[bob-sig=signature bob-htlc-sigs=(list signature)] bob-4=chan]
      ~(sign-next-commitment channel:bolt bob-3)
    ::  Alice then processes this revocation, sending her own revocation for
    ::  her prior commitment transaction. Alice shouldn't have any HTLCs to
    ::  forward since she's sending an outgoing HTLC.
    ::
    =/  alice-3=chan
      (~(receive-revocation channel:bolt alice-2) bob-revocation)
    ::  Alice then processes bob's signature, and since she just received
    ::  the revocation, she expect this signature to cover everything up to
    ::  the point where she sent her signature, including the HTLC.
    ::
    =/  alice-4=chan
      (~(receive-new-commitment channel:bolt alice-3) bob-sig bob-htlc-sigs)
    ::
    =/  tx0=psbt:psbt:bolt  ~(force-close-tx channel:bolt alice)
    =/  tx1=psbt:psbt:bolt  ~(force-close-tx channel:bolt alice-4)
    ::  Alice then generates a revocation for bob.
    ::
    =/  [alice-revocation=revoke-and-ack:msg alice-5=chan]
      ~(revoke-current-commitment channel:bolt alice-4)
    =/  tx2=psbt:psbt:bolt  ~(force-close-tx channel:bolt alice-5)
    ::  Finally Bob processes Alice's revocation, at this point the new HTLC
    ::  is fully locked in within both commitment transactions. Bob should
    ::  also be able to forward an HTLC now that the HTLC has been locked
    ::  into both commitment transactions.
    ::
    =/  bob-5=chan
      (~(receive-revocation channel:bolt bob-4) alice-revocation)
    :: Now we'll repeat a similar exchange, this time with Bob settling the
    :: HTLC once he learns of the preimage.
    ::
    =/  bob-6=chan
      (~(settle-htlc channel:bolt bob-5) preimage htlc-id.bob-htlc)
    ::
    =/  alice-6=chan
      (~(receive-htlc-settle channel:bolt alice-5) preimage htlc-id.alice-htlc)
    ::
    =/  tx3=psbt:psbt:bolt  ~(force-close-tx channel:bolt alice-6)
    ::
    =/  [[bob-sig-2=signature bob-htlc-sigs-2=(list signature)] bob-7=chan]
      ~(sign-next-commitment channel:bolt bob-6)
    ::
    =/  alice-7=chan
      (~(receive-new-commitment channel:bolt alice-6) bob-sig-2 bob-htlc-sigs-2)
    ::
    =/  tx4=psbt:psbt:psbt  ~(force-close-tx channel:bolt alice-7)
    ::
    =/  [alice-revocation-2=revoke-and-ack:msg alice-8=chan]
      ~(revoke-current-commitment channel:bolt alice-7)
    ::
    =/  [[alice-sig-2=signature alice-htlc-sigs-2=(list signature)] alice-9=chan]
      ~(sign-next-commitment channel:bolt alice-8)
    ::
    =/  bob-8=chan
      (~(receive-revocation channel:bolt bob-7) alice-revocation-2)
    ::
    =/  bob-9=chan
      %+  ~(receive-new-commitment channel:bolt bob-8)
        alice-sig-2
      alice-htlc-sigs-2
    ::
    =/  [bob-revocation-2=revoke-and-ack:msg bob-10=chan]
      ~(revoke-current-commitment channel:bolt bob-9)
    ::
    =/  alice-10=chan
      (~(receive-revocation channel:bolt alice-9) bob-revocation-2)
    ::
    ;:  weld
      %-  expect
        !>  (lth value:(head (tail local-outs)) (mul 5 (pow 10 8)))
      %+  expect-eq
        !>  (mul 5 (pow 10 8))
        !>  value:(head local-outs)
    ::
      %-  expect
        !>  (lth value:(head remote-outs) (mul 5 (pow 10 8)))
      %+  expect-eq
        !>  (mul 5 (pow 10 8))
        !>  value:(head (tail remote-outs))
    ::
      %-  expect
        !>  %-  ~(signature-fits channel:bolt alice)
            (~(latest-commitment channel:bolt alice) %local)
    ::
      %-  expect
        !>  ?=  ^
          (~(included-htlcs channel:bolt alice) %remote %received `--1 ~)
    ::
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt alice) %remote %received `--0 ~)
      %+  expect-eq
        !>  ~[htlc]
        !>  (~(included-htlcs channel:bolt alice) %remote %received `--1 ~)
    ::
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt bob) %remote %sent `--0 ~)
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt bob) %remote %sent `--1 ~)
    ::
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt alice) %remote %sent `--0 ~)
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt alice) %remote %sent `--1 ~)
    ::
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt bob) %remote %received `--0 ~)
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt bob) %remote %received `--1 ~)
    ::
      %+  expect-eq
        !>  --0
        !>  (~(oldest-unrevoked-commitment-number channel:bolt alice) %local)
    ::
      %-  expect
        !>  %-  ~(signature-fits channel:bolt alice)
            (~(latest-commitment channel:bolt alice) %local)
    ::
      %+  expect-eq
        !>  1
        !>  (lent alice-htlc-sigs)
      %-  expect
        !>  %-  ~(signature-fits channel:bolt alice-2)
            (~(latest-commitment channel:bolt alice-2) %local)
      %+  expect-eq
        !>  outputs:(~(latest-commitment channel:bolt alice-2) %remote)
        !>  outputs:(~(next-commitment channel:bolt bob) %local)
    ::
      %-  expect
        !>  %-  ~(signature-fits channel:bolt bob-2)
            (~(latest-commitment channel:bolt bob-2) %local)

      %-  expect
        !>  %-  ~(signature-fits channel:bolt bob-2)
            (~(latest-commitment channel:bolt bob-2) %local)
    ::
      %+  expect-eq
        !>  --0
        !>  (~(oldest-unrevoked-commitment-number channel:bolt bob-2) %remote)
      %+  expect-eq
        !>  ~[htlc]
        !>  (~(included-htlcs channel:bolt bob-2) %local %received `--1 ~)
    ::
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt alice-2) %remote %received `--0 ~)
      %+  expect-eq
        !>  ~[htlc]
        !>  (~(included-htlcs channel:bolt alice-2) %remote %received `--1 ~)
    ::
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt alice-2) %remote %sent `--0 ~)
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt alice-2) %remote %sent `--1 ~)
    ::
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt bob-2) %remote %received `--0 ~)
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt bob-2) %remote %received `--1 ~)
    ::
      %-  expect
        !>  %-  ~(signature-fits channel:bolt bob-3)
            (~(latest-commitment channel:bolt bob-3) %local)
    ::
      %-  expect
        !>  %-  ~(signature-fits channel:bolt bob-4)
            (~(latest-commitment channel:bolt bob-4) %local)
    ::
      %+  expect-eq
        !>  1
        !>  (lent bob-htlc-sigs)
    ::
      %-  expect
        !>  %-  ~(signature-fits channel:bolt alice-2)
            (~(latest-commitment channel:bolt alice-2) %local)
    ::
      %+  expect-eq
        !>  2
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-2) %local))
      %+  expect-eq
        !>  2
        !>  (lent outputs:(~(next-commitment channel:bolt alice-2) %local))
      %+  expect-eq
        !>  2
        !>  (lent outputs:(~(oldest-unrevoked-commitment channel:bolt alice-2) %remote))
      %+  expect-eq
        !>  3
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-2) %remote))
    ::
      %-  expect
        !>  %-  ~(signature-fits channel:bolt alice-3)
            (~(latest-commitment channel:bolt alice-3) %local)
    ::
      %+  expect-eq
        !>  2
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-3) %local))
      %+  expect-eq
        !>  3
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-3) %remote))
      %+  expect-eq
        !>  2
        !>  (lent outputs:~(force-close-tx channel:bolt alice-3))
    ::
      %+  expect-eq
        !>  1
        !>  (lent ~(val by adds.our.htlcs.alice-3))
      %+  expect-eq
        !>  outputs:(~(next-commitment channel:bolt alice-3) %local)
        !>  outputs:(~(latest-commitment channel:bolt bob-4) %remote)
    ::
      %+  expect-eq
        !>  3
        !>  (lent outputs:(~(latest-commitment channel:bolt alice-4) %remote))
      %+  expect-eq
        !>  3
        !>  (lent outputs:~(force-close-tx channel:bolt alice-4))
    ::
      %+  expect-eq
        !>  1
        !>  (lent ~(val by adds.our.htlcs.alice-4))
    ::
      %-  expect
        !>  !=(tx0 tx1)
    ::
      %+  expect-eq
        !>  tx1
        !>  tx2
    ::
      %-  expect
        !>  %-  ~(signature-fits channel:bolt bob-4)
            (~(latest-commitment channel:bolt bob-4) %local)
    ::
      %+  expect-eq
        !>  0
        !>  (~(total-msats channel:bolt alice-5) %sent)
      %+  expect-eq
        !>  0
        !>  (~(total-msats channel:bolt alice-5) %received)
      %+  expect-eq
        !>  0
        !>  (~(total-msats channel:bolt bob-5) %sent)
      %+  expect-eq
        !>  0
        !>  (~(total-msats channel:bolt bob-5) %received)
      %+  expect-eq
        !>  --1
        !>  (~(oldest-unrevoked-commitment-number channel:bolt bob-5) %local)
      %+  expect-eq
        !>  --1
        !>  (~(oldest-unrevoked-commitment-number channel:bolt alice-5) %local)
    ::
      %+  expect-eq
        !>  3
        !>  (lent outputs:(~(next-commitment channel:bolt alice-5) %local))
      %+  expect-eq
        !>  3
        !>  (lent outputs:(~(next-commitment channel:bolt bob-5) %local))
    ::
    ::  check output values
    ::
      %+  expect-eq
        !>  tx2
        !>  tx3
    ::
      %+  expect-eq
        !>  0
        !>  (lent bob-htlc-sigs-2)
    ::
      %+  expect-eq
        !>  ~[htlc]
        !>  %:  ~(by-direction htlcs:bolt alice-6)
              %remote
              %received
              (~(oldest-unrevoked-commitment-number channel:bolt alice-6) %remote)
            ==
    ::
      %+  expect-eq
        !>  ~[htlc]
        !>  %:  ~(included-htlcs channel:bolt alice-6)
              owner=%remote
              direction=%received
              cn=`(~(oldest-unrevoked-commitment-number channel:bolt alice-6) %remote)
              feerate=~
            ==
    ::
      %+  expect-eq
        !>  ~[htlc]
        !>  (~(included-htlcs channel:bolt alice-6) %remote %received `--1 ~)
      %+  expect-eq
        !>  ~[htlc]
        !>  (~(included-htlcs channel:bolt alice-6) %remote %received `--2 ~)
    ::
      %+  expect-eq
        !>  ~[htlc]
        !>  (~(included-htlcs channel:bolt bob-7) %remote %sent `--1 ~)
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt bob-7) %remote %sent `--2 ~)
    ::
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt alice-6) %remote %sent `--1 ~)
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt alice-6) %remote %sent `--2 ~)
    ::
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt bob-7) %remote %received `--1 ~)
      %+  expect-eq
        !>  ~
        !>  (~(included-htlcs channel:bolt bob-7) %remote %received `--2 ~)
    ::
      %+  expect-eq
        !>  outputs:(~(latest-commitment channel:bolt bob-7) %remote)
        !>  outputs:(~(next-commitment channel:bolt alice-6) %local)
    ::
      %-  expect
        !>  !=(tx3 tx4)
    ::
      %+  expect-eq
        !>  500.000.000.000
        !>  %:  ~(balance channel:bolt alice-7)
              %local
              %local
              (~(oldest-unrevoked-commitment-number channel:bolt alice-7) %local)
            ==
      %+  expect-eq
        !>  --1
        !>  (~(oldest-unrevoked-commitment-number channel:bolt alice-7) %local)
      %+  expect-eq
        !>  0
        !>  (lent (~(included-htlcs channel:bolt alice-7) %local %received `--2 ~))
    ::
      %+  expect-eq
        !>  ~
        !>  alice-htlc-sigs-2
      %+  expect-eq
        !>  3
        !>  (lent outputs:(~(latest-commitment channel:bolt bob-6) %local))
    ::
      %+  expect-eq
        !>  one-bitcoin-in-msats
        !>  (~(total-msats channel:bolt alice-10) %sent)
      %+  expect-eq
        !>  0
        !>  (~(total-msats channel:bolt alice-10) %received)
      %+  expect-eq
        !>  one-bitcoin-in-msats
        !>  (~(total-msats channel:bolt bob-10) %received)
      %+  expect-eq
        !>  0
        !>  (~(total-msats channel:bolt bob-10) %sent)
      %+  expect-eq
        !>  --2
        !>  (~(latest-commitment-number channel:bolt bob-10) %local)
      %+  expect-eq
        !>  --2
        !>  (~(latest-commitment-number channel:bolt alice-10) %local)
    ::
    ::  TODO: check fee invariance?
    ==
  ::
  ++  alice-to-bob-fee-update
    |=  [alice=chan bob=chan feerate=(unit sats:bc)]
    ^-  [fee=sats:bc alice=chan bob=chan]
    =+  fee=(fall feerate 111)
    =/  aoldctx=(list output:psbt:bolt)
      outputs:(~(next-commitment channel:bolt alice) %remote)
    =.  alice  (~(update-fee channel:bolt alice) fee %.y)
    =/  anewctx=(list output:psbt:bolt)
      outputs:(~(next-commitment channel:bolt alice) %remote)
    =/  boldctx=(list output:psbt:bolt)
      outputs:(~(next-commitment channel:bolt bob) %local)
    =.  bob  (~(update-fee channel:bolt bob) fee %.n)
    =/  bnewctx=(list output:psbt:bolt)
      outputs:(~(next-commitment channel:bolt bob) %local)
    ?>  !=(aoldctx anewctx)
    ?>  !=(boldctx bnewctx)
    ?>  =(anewctx bnewctx)
    [fee=fee alice=alice bob=bob]
  ::
  ++  check-update-fee-sender-commits
    =/  alice=chan  alice
    =/  bob=chan    bob
    =/  old-feerate=sats:bc
      (~(next-feerate channel:bolt alice) %local)
    =/  [fee=sats:bc alice=chan bob=chan]
      (alice-to-bob-fee-update alice bob ~)
    =/  [[alice-sig=signature alice-htlc-sigs=(list signature)] alice-2=chan]
      ~(sign-next-commitment channel:bolt alice)
    =/  bob-2=chan
      (~(receive-new-commitment channel:bolt bob) alice-sig alice-htlc-sigs)
    =/  [bob-rev=revoke-and-ack:msg bob-3=chan]
      ~(revoke-current-commitment channel:bolt bob-2)
    =/  alice-3=chan
      (~(receive-revocation channel:bolt alice-2) bob-rev)
    =/  [[bob-sig=signature bob-htlc-sigs=(list signature)] bob-4=chan]
      ~(sign-next-commitment channel:bolt bob-3)
    =/  alice-4=chan
      (~(receive-new-commitment channel:bolt alice-3) bob-sig bob-htlc-sigs)
    =/  [alice-rev=revoke-and-ack:msg alice-5=chan]
      ~(revoke-current-commitment channel:bolt alice-4)
    =/  bob-5=chan
      (~(receive-revocation channel:bolt bob-4) alice-rev)
    ;:  weld
      %+  expect-eq
        !>  old-feerate
        !>  (~(next-feerate channel:bolt alice) %local)
      %-  expect
        !>  !=(fee (~(oldest-unrevoked-feerate channel:bolt bob-2) %local))
      %+  expect-eq
        !>  fee
        !>  (~(latest-feerate channel:bolt bob-2) %local)
      %+  expect-eq
        !>  fee
        !>  (~(oldest-unrevoked-feerate channel:bolt bob-3) %local)
      %-  expect
        !>  !=(fee (~(oldest-unrevoked-feerate channel:bolt alice-4) %local))
      %+  expect-eq
        !>  fee
        !>  (~(latest-feerate channel:bolt alice-4) %local)
      %+  expect-eq
        !>  fee
        !>  (~(oldest-unrevoked-feerate channel:bolt alice-5) %local)
      %+  expect-eq
        !>  fee
        !>  (~(oldest-unrevoked-feerate channel:bolt bob-5) %local)
      %+  expect-eq
        !>  fee
        !>  (~(latest-feerate channel:bolt bob-5) %local)
    ==
  ::
  ++  check-update-fee-receiver-commits
    =/  alice=chan  alice
    =/  bob=chan    bob
    =/  [fee=sats:bc alice=chan bob=chan]
      (alice-to-bob-fee-update alice bob ~)
    =/  [[bob-sig=signature bob-htlc-sigs=(list signature)] bob=chan]
      ~(sign-next-commitment channel:bolt bob)
    =/  alice=chan
      (~(receive-new-commitment channel:bolt alice) bob-sig bob-htlc-sigs)
    =/  [alice-rev=revoke-and-ack:msg alice=chan]
      ~(revoke-current-commitment channel:bolt alice)
    =/  bob=chan
      (~(receive-revocation channel:bolt bob) alice-rev)
    =/  [[alice-sig=signature alice-htlc-sigs=(list signature)] alice=chan]
      ~(sign-next-commitment channel:bolt alice)
    =/  bob=chan
      (~(receive-new-commitment channel:bolt bob) alice-sig alice-htlc-sigs)
    =/  [bob-rev=revoke-and-ack:msg bob-2=chan]
      ~(revoke-current-commitment channel:bolt bob)
    =/  [[bob-sig=signature bob-htlc-sigs=(list signature)] bob-3=chan]
      ~(sign-next-commitment channel:bolt bob-2)
    =/  alice=chan
      (~(receive-revocation channel:bolt alice) bob-rev)
    =/  alice=chan
      (~(receive-new-commitment channel:bolt alice) bob-sig bob-htlc-sigs)
    =/  [alice-rev=revoke-and-ack:msg alice-2=chan]
      ~(revoke-current-commitment channel:bolt alice)
    =/  bob-4=chan
      (~(receive-revocation channel:bolt bob-3) alice-rev)
    ;:  weld
      %-  expect
        !>  !=(fee (~(oldest-unrevoked-feerate channel:bolt bob) %local))
      %+  expect-eq
        !>  fee
        !>  (~(latest-feerate channel:bolt bob) %local)
      %+  expect-eq
        !>  fee
        !>  (~(oldest-unrevoked-feerate channel:bolt bob-2) %local)
    ::
      %-  expect
        !>  !=(fee (~(oldest-unrevoked-feerate channel:bolt alice) %local))
      %+  expect-eq
        !>  fee
        !>  (~(latest-feerate channel:bolt alice) %local)
      %+  expect-eq
        !>  fee
        !>  (~(oldest-unrevoked-feerate channel:bolt alice-2) %local)
    ::
      %+  expect-eq
        !>  fee
        !>  (~(oldest-unrevoked-feerate channel:bolt bob-4) %local)
      %+  expect-eq
        !>  fee
        !>  (~(latest-feerate channel:bolt bob-4) %local)
    ==
  ::
  ++  force-state-transition
    |=  [a=chan b=chan]
    ^-  [a=chan b=chan]
    =^  a-sigs  a  ~(sign-next-commitment channel:bolt a)
    =.  b  (~(receive-new-commitment channel:bolt b) a-sigs)
    =^  b-rev   b  ~(revoke-current-commitment channel:bolt b)
    =^  b-sigs  b  ~(sign-next-commitment channel:bolt b)
    =.  a  (~(receive-revocation channel:bolt a) b-rev)
    =.  a  (~(receive-new-commitment channel:bolt a) b-sigs)
    =^  a-rev  a  ~(revoke-current-commitment channel:bolt a)
    =.  b  (~(receive-revocation channel:bolt b) a-rev)
    [a=a b=b]
  --
--
