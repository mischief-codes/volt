::  volt.hoon
::
::
/-  *volt
/+  bolt11=bolt-bolt11, bcu=bitcoin-utils
/+  server, default-agent, dbug
|%
::
+$  card  card:agent:gall
::
+$  provider-state  [host=ship connected=?]
::
+$  versioned-state
  $%  state-0
  ==
::
+$  state-0
  $:  %0
      =node-info
      prov=(unit provider-state)
    ::
      ::  our payments
      $=  pays
      $:  by-hash=(map hash payment)
          by-ship=(map ship payment)
      ==
    ::
      ::  our invoices
      $=  invs
      $:  by-hash=(map hash invoice)
          by-ship=(map ship invoice)
      ==
    ::
      ::  received payreqs
      reqs=(map hash payment-request)
  ==
--
::
%-  agent:dbug
::
=|  state-0
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def  ~(. (default-agent this %|) bowl)
    hc   ~(. +> bowl)
::
++  on-init
  ^-  (quip card _this)
  `this(state *state-0)
::
++  on-save
  ^-  vase
  !>(state)
::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  `this(state !<(versioned-state old-state))
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  =^  cards  state
  ?+    mark  (on-poke:def mark vase)
      %volt-command
    ?>  (team:title our.bowl src.bowl)
    (handle-command:hc !<(command vase))
  ::
      %volt-action
    (handle-action:hc !<(action vase))
  ::
      %volt-wallet-result
    %-  (slog leaf+"{<dap.bowl>}: {<!<(result:wallet vase)>}" ~)
    (handle-wallet-result:hc !<(result:wallet vase))
  ==
  [cards this]
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  ?=([%invoice-timeout *] wire)
    `this
    ::  TODO: expire the invoice (tmp-invs (remove-expired-invoices:hc tmp-invs))
  (on-arvo:def wire sign-arvo)
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    -.sign  (on-agent:def wire sign)
      %kick
    ?:  ?=(%set-provider -.wire)
      :_  this(prov [~ src.bowl %.n])
      (watch-provider:hc src.bowl)
    `this
  ::
      %fact
    =^  cards  state
      ?+    p.cage.sign  `state
          %volt-provider-status
        (handle-provider-status:hc !<(status:provider q.cage.sign))
      ::
          %volt-provider-update
        (handle-provider-update:hc !<(update:provider q.cage.sign))
      ==
    [cards this]
  ::
      %watch-ack
    ?:  ?=(%set-provider -.wire)
      ?~  p.sign
        `this
      =/  =tank  leaf+"subscribe to provider {<dap.bowl>} failed"
      %-  (slog tank u.p.sign)
      `this(prov ~)
    `this
  ==
::
++  on-peek
  |=  pax=path
  ^-  (unit (unit cage))
  ?:  ?=([%x %pubkey ~] pax)
    ``noun+!>(identity-pubkey.node-info)
  ?:  ?=([%x %invoices *] pax)
    ``noun+!>(~(val by by-hash.invs))
  ?:  ?=([%x %payments *] pax)
    ``noun+!>(~(val by by-hash.pays))
  (on-peek:def pax)
::
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
::
++  handle-command
  |=  =command
  ^-  (quip card _state)
  ?-    -.command
      %set-provider
    ?~  provider.command
      ?~  prov  `state
      :_  state(prov ~)
      ~[(leave-provider host.u.prov)]
    :_  state(prov `[u.provider.command %.n])
    ?~  prov
      (watch-provider u.provider.command)
    %-  zing
    :~  ~[(leave-provider host.u.prov)]
        (watch-provider u.provider.command)
    ==
  ::
      %send-payment
    =+  +.command
    =|  paym=payment
    =.  payer.paym          our.bowl
    =.  payee.paym          to
    =.  fee-limit.paym      fee-limit
    =.  status.paym         %'UNKNOWN'
    =.  creation-time.paym  now.bowl
    =.  value-msats.paym    amt-msats
    :_  state(by-ship.pays (~(put by by-ship.pays) to.command paym))
    ~[(request-invoice payee.paym value-msats.paym)]
  ::
      %send-invoice
    =+  +.command
    =|  invo=invoice
    =.  payer.invo        to
    =.  payee.invo        src.bowl
    =.  memo.invo         (fall memo '')
    =/  =preimage         (generate-preimage)
    =/  =hash             (sha256:bcu preimage)
    =.  r-preimage.invo   preimage
    =.  r-hash.invo       hash
    =.  value-msats.invo  amt-msats
    =.  settled.invo      %.n
    :_  state(by-hash.invs (~(put by by-hash.invs) hash invo))
    ~[(add-invoice amt-msats memo `r-preimage.invo `r-hash.invo)]
  ::
      %cancel-invoice
    ?.  (~(has by by-hash.invs) payment-hash.command)
      `state
    =+  invo=(~(got by by-hash.invs) payment-hash.command)
    =/  for-ship=?
      ?&  (~(has by by-ship.invs) payer.invo)
          =+  inv=(~(got by by-ship.invs) payer.invo)
          =+  hsh=`payment-hash.command
          =(hsh r-hash.inv)
      ==
    :-  ~[(cancel-invoice payment-hash.command)]
    state(by-ship.invs ?:(for-ship (~(del by by-ship.invs) payer.invo) by-ship.invs))
  ::
      %request-invoice
    :_  state
    ~[(request-invoice from.command amt-msats.command)]
  ::
      %pay-invoice
    =+  +.command
    ?.  (~(has by reqs) payment-hash)
      ~&  >>>  "volt: no invoice for payment {<dat.payment-hash>}"
      `state
    =+  invoice=(~(got by reqs) payment-hash)
    :_  state
    ~[(send-payment payreq.invoice fee-limit)]
  ::
      %reset
    ~&  >>>  "volt: resetting payment state"
    `state(by-ship.invs *(map ship invoice), by-ship.pays *(map ship payment))
  ==
::
++  handle-action
  |=  =action
  ^-  (quip card _state)
  ?-    -.action
      %request-invoice
    =+  old-invo=(~(get by by-ship.invs) src.bowl)
    ?:  ?&  ?=(^ old-invo)
            =(value-msats.u.old-invo amt-msats.action)
        ==
      ::  invoice for ship already generated
      ::
      ~&  >  "volt: repeated request for invoice: {<amt-msats.action>}"
      :_  state
      ~[(request-payment src.bowl payment-request.u.old-invo)]
    ::  generate a new invoice
    ::
    ~&  >  "volt: got request for invoice: {<amt-msats.action>}"
    =|  invo=invoice
    =.  payer.invo        src.bowl
    =.  payee.invo        our.bowl
    =/  =preimage         (generate-preimage)
    =/  =hash             (sha256:bcu preimage)
    =.  r-preimage.invo   preimage
    =.  r-hash.invo       hash
    =.  value-msats.invo  amt-msats.action
    =.  settled.invo      %.n
    :_  %_  state
          by-ship.invs  (~(put by by-ship.invs) src.bowl invo)
          by-hash.invs  (~(put by by-hash.invs) hash invo)
        ==
    %+  weld
      ~[(add-invoice value-msats.invo ~ `preimage `hash)]
    ?~  old-invo
      ~
    ~[(cancel-invoice r-hash.u.old-invo)]
  ::
      %request-payment
    =/  invoice=(unit invoice:bolt11)
      %-  de:bolt11  payreq.action
    ?~  invoice  ~|(%invalid-payment-request !!)
    ?:  ?&  (~(has by by-ship.pays) src.bowl)
            =+  paym=(~(got by by-ship.pays) src.bowl)
            (check-invoice u.invoice paym)
        ==
        ~&  >  "volt: got invoice for our request: {<payreq.action>}"
        ::  invoice for unconditional payment:
        ::
        =+  paym=(~(got by by-ship.pays) src.bowl)
        =.  request.paym  payreq.action
        =.  hash.paym     payment-hash.u.invoice
        :_  %_  state
              by-ship.pays  (~(put by by-ship.pays) payee.paym paym)
              by-hash.pays  (~(put by by-hash.pays) payment-hash.u.invoice paym)
            ==
        ~[(send-payment payreq.action fee-limit.paym)]
    ::
    ~&  >  "volt: got request: {<payreq.action>}"
    =|  payreq=payment-request
    =.  payer.payreq          our.bowl
    =.  payee.payreq          src.bowl
    =.  amount-msats.payreq   (amount-msats (fall amount.u.invoice [0 ~]))
    =.  received-at.payreq    now.bowl
    =.  payreq.payreq         payreq.action
    =.  status.payreq         %'UNKNOWN'
    :_  state(reqs (~(put by reqs) payment-hash.u.invoice payreq))
    ~[(send-update [%& %payment-requested payreq])]
  ::
      %payment-receipt
    =+  action
    ~&  >  "volt: got receipt for: {<dat.payment-hash>}"
    =+  preq=(~(get by reqs) payment-hash)
    ?~  preq  `state
    =.  status.u.preq  %'SUCCEEDED'
    `state(reqs (~(put by reqs) payment-hash u.preq))
  ==
::
++  handle-provider-update
  |=  =update:provider
  ^-  (quip card _state)
  ?-    -.update
    %&  (handle-provider-result +.update)
    %|  (handle-provider-error +.update)
  ==
::
++  handle-provider-error
  |=  =error:provider
  ^-  (quip card _state)
  =^  cards  state
    ?:  ?=([%rpc-error *] error)
      ~&  >>>  "volt: rpc error: {<message.error>}"
      `state
    ~&  >>>  "volt: provider error: {<error>}"
    `state
  :_  state
  [(send-update [%| %provider-error error]) cards]
::
++  handle-provider-result
  |=  =result:provider
  ^-  (quip card _state)
  ?-    -.result
      %node-info
    `state(node-info node-info.result)
  ::
      %htlc
    `state
  ::
      %invoice-added
    ?.  (~(has by by-hash.invs) r-hash.result)
      `state
    =+  invo=(~(got by by-hash.invs) r-hash.result)
    =/  for-ship=?
      ?&  (~(has by by-ship.invs) payer.invo)
          =(r-hash.result r-hash:(~(got by by-ship.invs) payer.invo))
      ==
    =.  payment-request.invo  payment-request.result
    :_  %_  state
          by-hash.invs  (~(put by by-hash.invs) r-hash.result invo)
        ::
          by-ship.invs
            ?:  for-ship
              ~&  >  "volt: invoice for unrequested payment added: {<dat.r-hash.result>}"
              (~(put by by-ship.invs) payer.invo invo)
            by-ship.invs
        ==
    ~[(request-payment payer.invo payment-request.result)]
  ::
      %channel-update
    `state
  ::
      %payment-update
    ?.  (~(has by by-hash.pays) hash.result)  `state
    =+  paym=(~(got by by-hash.pays) hash.result)
    =/  for-ship=?
      ?&  (~(has by by-ship.pays) payee.paym)
          =(hash.result hash:(~(got by by-ship.pays) payee.paym))
      ==
    =.  paym
      :*  payer=payer.paym
          payee=payee.paym
          fee-limit=fee-limit.paym
          +.result
      ==
    ?-    status.result
        %'SUCCEEDED'
      :_  %_  state
            by-hash.pays  (~(put by by-hash.pays) hash.result paym)
          ::
            by-ship.pays
              ?:  for-ship
                (~(del by by-ship.pays) payee.paym)
              by-ship.pays
          ==
      ~[(send-update [%& %payment-sent payee.paym value-msats.paym])]
    ::
        %'FAILED'
      :_  %_  state
            by-hash.pays  (~(put by by-hash.pays) hash.result paym)
          ::
            by-ship.pays
              ?:  for-ship
                (~(del by by-ship.pays) payee.paym)
              by-ship.pays
          ==
      ~[(send-update [%| %payment-failed hash.result failure-reason.result])]
    ::
        %'UNKNOWN'    `state
        %'IN_FLIGHT'  `state
    ==
  ::
      %invoice-update
    ?.  (~(has by by-hash.invs) r-hash.result)
      `state
    =+  invo=(~(got by by-hash.invs) r-hash.result)
    =/  for-ship=?
      ?&  (~(has by by-ship.invs) payer.invo)
          =(r-hash.result r-hash:(~(got by by-ship.invs) payer.invo))
      ==
    =.  invo
      :*  payer=payer.invo
          payee=payee.invo
          +.result
      ==
    :_  %_  state
            by-hash.invs
              %+  ~(put by by-hash.invs)
                r-hash.result
              invo
          ::
            by-ship.invs
              ?:  for-ship
                %-  ~(del by by-ship.invs)
                  payer.invo
              by-ship.invs
          ==
    ?-    state.result
        %'SETTLED'
      :~  (send-update [%& %invoice-settled r-hash.result])
          (payment-receipt r-hash.result payer.invo)
      ==
    ::
        %'CANCELED'
      ~[(send-update [%& %invoice-canceled r-hash.result])]
    ::
        %'OPEN'
      ?:  for-ship
        ~[set-invoice-timeout]
      ~
    ::
        %'ACCEPTED'
      ~
    ==
  ::
      %balance-update
    `state
  ==
::
++  handle-provider-status
  |=  =status:provider
  ^-  (quip card _state)
  ?~  prov  `state
  ?-    status
      %connected
    `state(connected.u.prov %.y)
  ::
      %disconnected
    `state(connected.u.prov %.n)
  ==
::
++  handle-wallet-result
  |=  =result:wallet
  ^-  (quip card _state)
  `state
::
++  watch-provider
  |=  who=@p
  ^-  (list card)
  =/  =dock      [who %volt-provider]
  =/  wir=wire  /set-provider/[(scot %p who)]
  =/  pir=wire  (welp wir [%priv ~])
  :~
    :*  %pass   wir
        %agent  dock
        %watch  /clients
    ==
  ==
::
++  leave-provider
  |=  who=@p
  ^-  card
  :*  %pass   /set-provider/[(scot %p who)]
      %agent  [who %volt-provider]  %leave  ~
  ==
::
++  provider-action
  |=  [=wire =action:provider]
  ^-  card
  :*  %pass  wire  %agent
      [our.bowl %volt-provider]  %poke
      %volt-provider-action  !>(action)
  ==
::
++  provider-command
  |=  [=wire =command:provider]
  ^-  card
  :*  %pass  wire  %agent
      [our.bowl %volt-provider]  %poke
      %volt-provider-command  !>(command)
  ==
::
++  send-update
  |=  =update
  ^-  card
  %-  ?:  ?=(%& -.update)
        same
      ~&(>> "volt: error: {<-.p.update>}" same)
  [%give %fact ~[/events] %volt-update !>(update)]
::
++  request-payment
  |=  [who=@p req=cord]
  ^-  card
  :*  %pass   /payment/[(scot %p who)]
      %agent  [who %volt]
      %poke   %volt-action
      !>([%request-payment req])
  ==
::
++  request-invoice
  |=  [who=@p =amt=msats]
  ^-  card
  :*  %pass   /invoice/[(scot %p who)]
      %agent  [who %volt]
      %poke   %volt-action
      !>([%request-invoice amt-msats])
  ==
::
++  add-invoice
  |=  [=amt=msats memo=(unit cord) prem=(unit preimage) hash=(unit hash)]
  ^-  card
  %+  provider-action  /invoice
  [%add-invoice amt-msats memo prem hash `~m2]
::
++  set-invoice-timeout
  ^-  card
  :*  %pass  /invoice-timeout
      %arvo  %b
      %wait  (add now.bowl (add ~s30 ~m2))
  ==
::
++  remove-expired-invoices
  |=  invs=(map ship invoice)
  ^-  (map ship invoice)
  ~&  >>  "%volt: removing expired invoices"
  %-  ~(rep by invs)
  |=  [[k=ship v=invoice] acc=(map ship invoice)]
  ?:  (gte (add creation-date.v expiry.v) now.bowl)
    acc
  (~(put by acc) k v)
::
++  cancel-invoice
  |=  =payment=hash
  ^-  card
  %+  provider-action  /invoice
  [%cancel-invoice payment-hash]
::
++  send-payment
  |=  [invoice=cord fee-limit=(unit sats:bc)]
  ^-  card
  %+  provider-action  /payment
  [%send-payment invoice ~ fee-limit]
::
++  payment-receipt
  |=  [=payment=hash who=ship]
  ^-  card
  :*  %pass   /payment/[(scot %p who)]
      %agent  [who %volt]
      %poke    %volt-action
      !>([%payment-receipt payment-hash])
  ==
::
++  generate-preimage
  |.
  ^-  preimage
  :-  32
  %-  ~(rad og eny.bowl)
  (lsh [0 256] 1)
::
++  check-invoice
  |=  [=invoice:bolt11 paym=payment]
  ^-  ?
  ?~  amount.invoice  %.y
  =(value-msats.paym (amount-msats u.amount.invoice))
::
++  amount-msats
  |=  =amount:bolt11
  ^-  msats
  ?~  +.amount  (mul -.amount 100.000.000.000)
  ?-  +>.amount
    %m  (mul -.amount 100.000.000)
    %u  (mul -.amount 100.000)
    %n  (mul -.amount 100)
    %p  (div -.amount 10)
  ==
--
