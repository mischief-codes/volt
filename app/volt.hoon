::  volt.hoon
::
::
/-  *volt
/+  bolt11=bolt-bolt11, bcu=bitcoin-utils
/+  server, default-agent, dbug
::
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
      pays=(map hash payment)
      invs=(map hash invoice)
      reqs=(map hash payment-request)
      tmp-pays=(map ship payment)
      tmp-invs=(map ship invoice)
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
  ==
  [cards this]
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  `this
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
    ``noun+!>(~(val by invs))
  ?:  ?=([%x %payments *] pax)
    ``noun+!>(~(val by pays))
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
    ~|  "volt: payment with {<to.command>} already in-flight"
    ?<  (~(has by tmp-pays) to.command)
    =|  paym=payment
    =.  payer.paym          our.bowl
    =.  payee.paym          to
    =.  status.paym         %'UNKNOWN'
    =.  creation-time.paym  now.bowl
    =.  value-msats.paym    amt-msats
    :_  state(tmp-pays (~(put by tmp-pays) to.command paym))
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
    :_  state(invs (~(put by invs) hash invo))
    ~[(add-invoice amt-msats memo `r-preimage.invo `r-hash.invo)]
  ::
      %cancel-invoice
    ?.  (~(has by invs) payment-hash.command)
      `state
    =+  invo=(~(got by invs) payment-hash.command)
    =/  in-temp=?
      ?&  (~(has by tmp-invs) payer.invo)
          =+  tmp=(~(got by tmp-invs) payer.invo)
          =+  hsh=`payment-hash.command
          =(hsh r-hash.tmp)
      ==
    :-  ~[(cancel-invoice payment-hash.command)]
    state(tmp-invs ?:(in-temp (~(del by tmp-invs) payer.invo) tmp-invs))
  ::
      %pay-invoice
    =+  +.command
    ?.  (~(has by reqs) payment-hash)
      `state
    =+  invoice=(~(got by reqs) payment-hash)
    :_  state
    ~[(send-payment payreq.invoice)]
  ::
      %reset
    ~&  >>>  "resetting payment state"
    `state(tmp-invs *(map ship invoice), tmp-pays *(map ship payment))
  ==
::
++  handle-action
  |=  =action
  ^-  (quip card _state)
  ?-    -.action
      %request-invoice
    ?:  (~(has by tmp-invs) src.bowl)
      ::  invoice already generated, send it back:
      ::
      =+  invo=(~(got by tmp-invs) src.bowl)
      :_  state
      ~[(request-payment src.bowl payment-request.invo)]
    ::  generate a new invoice
    ::
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
          tmp-invs  (~(put by tmp-invs) src.bowl invo)
          invs      (~(put by invs) hash invo)
        ==
    ~[(add-invoice value-msats.invo ~ `preimage `hash)]
  ::
      %request-payment
    =/  invoice=(unit invoice:bolt11)
      %-  de:bolt11  payreq.action
    ~|  %invalid-payment-request
    ?~  invoice  !!
    ?:  ?&  (~(has by tmp-pays) src.bowl)
            =+  paym=(~(got by tmp-pays) src.bowl)
            (check-invoice u.invoice paym)
        ==
        ::  invoice for unconditional payment:
        ::
        =+  paym=(~(got by tmp-pays) src.bowl)
        =.  request.paym  payreq.action
        =.  hash.paym     payment-hash.u.invoice
        :_  %_  state
              tmp-pays  (~(put by tmp-pays) payee.paym paym)
              pays      (~(put by pays) payment-hash.u.invoice paym)
            ==
        ~[(send-payment payreq.action)]
    ::  unrequested invoice:
    ::
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
    =+  preq=(~(get by reqs) payment-hash)
    ?~  preq
      ~|(%invalid-payment-hash !!)
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
    ?.  (~(has by invs) r-hash.result)
      `state
    =+  invo=(~(got by invs) r-hash.result)
    =/  for-temp=?
      ?&  (~(has by tmp-invs) payer.invo)
          =(`r-hash.result r-hash:(~(got by tmp-invs) payer.invo))
      ==
    =.  payment-request.invo  payment-request.result
    :_  %_  state
          tmp-invs  ?:(for-temp (~(put by tmp-invs) payer.invo invo) tmp-invs)
          invs      (~(put by invs) r-hash.result invo)
        ==
    ~[(request-payment payer.invo payment-request.result)]
  ::
      %channel-update
    `state
  ::
      %payment-update
    ?.  (~(has by pays) hash.result)  `state
    =+  paym=(~(got by pays) hash.result)
    =/  for-temp=?
      ?&  (~(has by tmp-pays) payee.paym)
          =(hash.result hash:(~(got by tmp-pays) payee.paym))
      ==
    =.  paym
      :*  payer=payer.paym
          payee=payee.paym
          +.result
      ==
    ?-    status.result
        %'SUCCEEDED'
      :_  %_  state
            tmp-pays  ?:(for-temp (~(del by tmp-pays) payee.paym) tmp-pays)
            pays      (~(put by pays) hash.result paym)
          ==
      ~[(send-update [%& %payment-sent payee.paym value-msats.paym])]
    ::
        %'FAILED'
      :_  %_  state
            tmp-pays  ?:(for-temp (~(del by tmp-pays) payee.paym) tmp-pays)
            pays      (~(put by pays) hash.result paym)
          ==
      ~[(send-update [%| %payment-failed hash.result failure-reason.result])]
    ::
        %'UNKNOWN'    `state
        %'IN_FLIGHT'  `state
    ==
  ::
      %invoice-update
    ?.  (~(has by invs) r-hash.result)
      `state
    =+  invo=(~(got by invs) r-hash.result)
    =/  for-temp=?
      ?&  (~(has by tmp-invs) payer.invo)
          =(r-hash.result r-hash:(~(got by tmp-invs) payer.invo))
      ==
    =.  invo
      :*  payer=payer.invo
          payee=payee.invo
          +.result
      ==
    ?-    state.result
        %'SETTLED'

      :_  %_  state
            tmp-invs  ?:(for-temp (~(del by tmp-invs) payer.invo) tmp-invs)
            invs      (~(put by invs) r-hash.result invo)
          ==
      :~  (send-update [%& %invoice-settled r-hash.result])
          (payment-receipt r-hash.result payer.invo)
      ==
    ::
        %'CANCELED'
      :_  %_  state
            tmp-invs  ?:(for-temp (~(del by tmp-invs) payer.invo) tmp-invs)
            invs      (~(put by invs) r-hash.result invo)
          ==
      ~[(send-update [%& %invoice-canceled r-hash.result])]
    ::
        %'OPEN'      `state
        %'ACCEPTED'  `state
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
  [%add-invoice amt-msats memo prem hash]
::
++  cancel-invoice
  |=  =payment=hash
  ^-  card
  %+  provider-action  /invoice
  [%cancel-invoice payment-hash]
::
++  send-payment
  |=  invoice=cord
  ^-  card
  %+  provider-action  /payment
  [%send-payment invoice]
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
  ?~  +.amount  (mul -.amount 100.000.000)
  ?-  +>.amount
    %m  (mul -.amount 100.000.000)
    %u  (mul -.amount 100.000)
    %n  (mul -.amount 100)
    %p  (div -.amount 10)
  ==
--
