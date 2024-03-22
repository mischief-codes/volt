/-  volt, bitcoin  :: psbt
/+  psbt
|%
++  dejs
  =,  dejs:format
  |%
  ++  command
    |=  jon=json
    ^-  command:volt
    ~&  jon
    %.  jon
    %-  of
    :~  set-provider+(mu ship)
        open-channel+(ot ~[who+ship funding-sats+ni push-msats+ni network+network])
        create-funding+(ot ~[temporary-channel-id+(se %ud) psbt+psbt])
        close-channel+(se %ud)
        send-payment+(ot ~[payreq+so who+(mu ship)])
        add-invoice+(ot ~[amount+ni memo+so:dejs-soft:format network+(mu network)])
        test-invoice+(ot ~[ship+ship msats+ni network+network])
    ==
  ::
  ++  psbt
    |=  jon=json
    ^-  psbt:^psbt
    ?.  ?=([%s @t] jon)
      ~|  "%volt: invalid psbt"
        !!
    (need (from-base64:create:^psbt +.jon))
  ::
  ++  provider
    |%
    ++  command
      |=  jon=json
      ^-  command:provider:volt
    %.  jon
    %-  of
    :~  set-url+so
    ==
  --
  ++  ship  (su ;~(pfix sig fed:ag))
  ++  network  (su (perk %main %testnet %regtest ~))
  --
::
++  enjs
  =,  enjs:format
  |%
  ++  provider
    |%
    ++  status
      |=  s=status:provider:volt
      ^-  json
      (frond 'connected' b+=(s %connected))
    ::
    ++  update
      |=  upd=update:provider:volt
      ^-  json
      ?-  -.upd
        %res
          ?+  +<.upd  !!
            %node-info
          (frond 'node-info' ~)
          ==
        %err
          ?-  +<.upd
            %rpc-error
          (frond 'error' s+'rpc-error')
            %not-connected
          (frond 'error' s+'not-connected')
            %bad-request
          (frond 'error' s+'not-connected')
          ==
      ==
  --
  ++  update
    |=  upd=update:volt
    ^-  json
    ?+    -.upd  (frond 'type' s+'unimplemented')
        %on-chain-fee-estimate
      %-  pairs
        :~  ['type' s+'on-chain-fee-estimate']
            ['sats-per-vbyte' (numb sats-per-vbyte.upd)]
        ==
      ::
        %need-funding
      %-  pairs
        :~  ['type' s+'need-funding']
            ['funding-info' a+(turn funding-info.upd funding-info)]

            ::  (funding-info funding-info.upd)]
        ==
      ::
        %channel-state
      %-  pairs
      :~  ['type' s+'channel-state']
          ['id' s+`@t`(scot %ud chan-id.upd)]
          ['status' s+chan-state.upd]
      ==
    ::
        %new-invoice
      %-  pairs
      :~  ['type' s+'new-invoice']
          ['payment-request' (payment-request payment-request.upd)]
      ==
    ::
        %new-channel
      %-  pairs
      :~  ['type' s+'new-channel']
          ['chan-info' (chan-info chan-info.upd)]
      ==
    ::
        %channel-deleted
      %-  pairs
      :~  ['type' s+'channel-deleted']
          ['id' s+`@t`(scot %ud id.upd)]
      ==
    ::
        %initial-state
      %-  pairs
      :~  ['type' s+'initial-state']
          ['chans' a+(turn chans.upd chan-info)]
          ['txs' a+(turn txs.upd pay-info)]
          ['invoices' a+(turn invoices.upd payment-request)]
      ==
    ==
  ::
  ++  funding-info
    |=  info=funding-info:volt
    %-  pairs
    :~  ['temporary-channel-id' s+`@t`(scot %ud temporary-channel-id.info)]
        ['tau-address' (bitcoin-address tau-address.info)]
        ['funding-address' (bitcoin-address funding-address.info)]
        ['msats' (numb msats.info)]
    ==
  ::
  ++  chan-info
    |=  info=chan-info:volt
    ^-  json
    %-  pairs
    :~  ['id' s+`@t`(scot %ud id.info)]
        ['who' (ship who.info)]
        ['our' (numb our.info)]
        ['his' (numb his.info)]
        ['status' s+status.info]
    ==
  ++  bitcoin-address
    |=  =address:bitcoin
    ^-  json
    ?-   -.address
      %base58
    !!
      %bech32
    s++.address
    ==
  ::
  ++  payment-request
    |=  payment-request=payment-request:volt
    ^-  json
    %-  pairs
    :~  ['amount-msats' (numb amount-msats.payment-request)]
        ['payreq' (payreq payreq.payment-request)]
    ==
  ::
  ++  payreq
    |=  payreq=payreq:volt
    ^-  json
    s+payreq
  ::
  ++  pay-info
    |=  info=pay-info:volt
    ^-  json
    ~
  ::
  ++  hexb
    |=  h=hexb:bitcoin
    ^-  json
    %-  pairs
    :~  wid+(numb:enjs wid.h)
        dat+s+(scot %ux dat.h)
    ==
  --
--
