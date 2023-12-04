/-  volt
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
    create-funding+(ot ~[temporary-channel-id+(se %ud) psbt+so])
    close-channel+(se %ud)
    send-payment+(ot ~[payreq+so who+(mu ship)])
    add-invoice+(ot ~[amount+ni memo+so:dejs-soft:format network+(mu network)])
    test-invoice+(ot ~[ship+ship msats+ni network+network])
    ==
  ::
  ++  ship  (su ;~(pfix sig fed:ag))
  ++  network  (su (perk %main %testnet %regtest ~))
  --

++  enjs
  =,  enjs:format
  |%
  ++  update
    |=  upd=update:volt
    ^-  json
    ?+    -.upd  !!
        %new-invoice
      %-  pairs
      :~  ['payreq' s+payreq.upd]
      ==
        %initial-state
      %-  pairs
      :~  ['chans' a+(turn chans.upd chan-info)]
      ['txs' a+(turn txs.upd pay-info)]  ::a+(turn txs.upd pay-info)]
      ==
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
  ::
  ++  pay-info
    |=  info=pay-info:volt
    ^-  json
    ~
  ::   %-  pairs
  ::   :~  ['payreq' s+payreq.info]
  ::   ['chan' s+`@t`(scot %ud chan.info)]
  ::   ['amt' (numb amt.info)]
  ::   ['pat-p' ~] ::
  ::   ['node-id' ~] :: ?~(-.node-id.info ~ s+(scow %ud -.node-id.info))]
  ::   ['done' ~]
  ::   ==
  --
--
