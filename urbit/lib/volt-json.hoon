/-  volt
|%
++  dejs
  =,  dejs:format
  |%
  ++  command
    |=  jon=json
    ^-  command:volt
    %.  jon
    %-  of
    :~  set-provider+(mu ship)
    open-channel+(ot ~[who+ship funding-sats+ni push-msats+ni network+network])
    create-funding+(ot ~[temporary-channel-id+(se %a) psbt+ni])
    close-channel+(se %a)
    send-payment+(ot ~[payreq+so who+(mu ship)])
    add-invoice+(ot ~[amount+ni memo+so:dejs-soft:format network+(mu network)])
    test-invoice+(ot ~[ship+ship msats+ni network+network])
    ==
  ::
  ++  ship  (su ;~(pfix sig fed:ag))
  ++  network  (su (perk %main %testnet %regtest ~))
  --
--
