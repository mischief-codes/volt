/-  volt
|%
:: dejs-soft:format
++  dejs
  =,  dejs:format
  |%
  ++  command
    |=  jon=json
    ^-  command:volt
    ~&  'json is'  ~&  jon
    %.  jon
    %-  of
    :~  set-provider+(mu ship)
    :: open-channel+(ot ~[who+(se %p) funding+ni push+ni network+ni])
    :: create-funding+(ot ~[temporary-channel-id+so psbt+ni])
    :: close-channel+chan-id
    :: send-payment+(ot ~[payreq+ni who+ship])
    :: add-invoice+(ot ~[amount+so memo+ni network+ni])
    :: test-invoice+(ot ~[ship+ship msats+ni network+ni])
    ==
  ::
  ++  ship  (su ;~(pfix sig fed:ag))
  --
--

      :: %-  ot
      :: :~  [%count ni]
      ::     [%hex (cu from-cord:hxb:bcu so)]
      ::     [%max ni]
      ::     [%root (cu:dejs-soft:format from-cord:hxb:bcu so:dejs-soft:format)]
      ::     [%branch (ar (cu from-cord:hxb:bcu so))]
      :: ==


  :: $%  [%set-provider provider=(unit ship)]
  ::     [%open-channel who=ship =funding=sats:bc =push=msats =network:bolt]
  ::     [%create-funding temporary-channel-id=@ psbt=@t]
  ::     [%close-channel =chan-id]
  ::     [%send-payment =payreq who=(unit ship)]
  ::     [%add-invoice =amount=msats memo=(unit @t) network=(unit network:bolt)]
  ::     [%test-invoice =ship =msats =network:bolt]
