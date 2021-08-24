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
      hahs=(map hash ship)
      pays=(map ship payment)
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
  ?-    -.sign
      %poke-ack
    ?+    -.wire  (on-agent:def wire sign)
        %invoices
      =/  who=@p  (slav %p +<.wire)
      ?.  (~(has by pays) who)  `this
      =/  paym=payment  (~(got by pays) who)
      `this(pays (~(put by pays) who (update-payment-status:hc paym)))
    ==
  ::
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
    |^
    ?~  provider.command
      ?~  prov  `state
      :_  state(prov ~)
      (leave-provider host.u.prov)
    :_  state(prov `[u.provider.command %.n])
    ?~  prov
      (watch-provider u.provider.command)
    %-  zing
    :~  (leave-provider host.u.prov)
        (watch-provider u.provider.command)
    ==
    ::
    ++  leave-provider
      |=  who=@p
      ^-  (list card)
      :-  :*  %pass   /set-provider/[(scot %p who)]
              %agent  [who %volt-provider]  %leave  ~
          ==
        ~
    --
  ::
      %reset
    ~&  >>>  "resetting payment state"
    `state(hahs *(map hash ship), pays *(map ship payment))
  ::
      %wallet-balance
    :_  state
    ~[(provider-action /balance command)]
  ::
      %send-payment
    ~|  "volt: payment with {<to.command>} already in-flight"
    ?<  (~(has by pays) to.command)
    =|  paym=payment
    =.  stat.paym  %pending-invoice
    =.  dire.paym  %outgoing
    =.  amnt.paym  amt-msats.command
    =.  pyee.paym  to.command
    =.  pyer.paym  our.bowl
    :_  state(pays (~(put by pays) to.command paym))
    ~[(request-invoice pyee.paym amnt.paym)]
  ::
      %add-invoice
    =+  +.command
    :_  state
    ~[(provider-action /invoice [%add-invoice amt-msats memo ~ ~])]
  ::
      %open-channel
    `state
  ::
      %close-channel
    `state
  ==
::
++  handle-action
  |=  =action
  ^-  (quip card _state)
  ?-    -.action
      %request-invoice
    |^
    ?:  (~(has by pays) src.bowl)
      =/  paym=payment  (~(got by pays) src.bowl)
      ~|  "invalid payment state"
      ?>  =(dire.paym %incoming)
      ::  invoice already generated, send it back
      :_  state
      ~[(request-payment src.bowl (need pyre.paym))]
    ::
    =|  paym=payment
    =.  stat.paym  %pending-invoice
    =.  dire.paym  %incoming
    =.  pyer.paym  src.bowl
    =.  pyee.paym  our.bowl
    =.  amnt.paym  amt-msats.action
    =/  =preimage  (generate-preimage)
    =/  =hash      (sha256:bcu preimage)
    =.  prem.paym  (some preimage)
    =.  hash.paym  (some hash)
    :_  %_  state
          pays  (~(put by pays) src.bowl paym)
          hahs  (~(put by hahs) hash src.bowl)
        ==
    ~[(provider-action /invoice (add-invoice-action paym))]
    ::
    ++  generate-preimage
      |.
      ^-  preimage
      :-  32
      %-  ~(rad og eny.bowl)
      (lsh [0 256] 1)
    ::
    ++  add-invoice-action
      |=  paym=payment
      ^-  action:provider
      :*  %add-invoice
          amt-msats=amnt.paym
          memo=~
          preimage=prem.paym
          hash=hash.paym
      ==
    --
  ::
      %request-payment
    |^
    ~|  "no payment associated with {<src.bowl>}"
    ?>  (~(has by pays) src.bowl)
    =/  paym=payment  (~(got by pays) src.bowl)
    ~|  "invalid payment sate {<stat.paym>}"
    ?>  ?&  =(dire.paym %outgoing)
            =(stat.paym %pending-invoice)
        ==
    =/  =invoice:bolt11
      %-  need
      (de:bolt11 invoice.action)
    ~|  "invalid payment request"
    ?>  (check-invoice invoice paym)
    =.  stat.paym  %sent-payment
    =.  pyre.paym  (some invoice.action)
    =.  hash.paym  (some payment-hash.invoice)
    :-  ~[(provider-action /payment [%send-payment invoice.action])]
    %_  state
      pays  (~(put by pays) src.bowl paym)
      hahs  (~(put by hahs) payment-hash.invoice src.bowl)
    ==
    ::
    ++  check-invoice
      |=  [=invoice:bolt11 paym=payment]
      ^-  ?
      %.y
    ::
    ++  amount-msats
      |=  =amount:bolt11
      ^-  msats
      ?~  +.amount  -.amount
      %+  div  -.amount
      ?-  +>.amount
        %m  1
        %u  10
        %n  100
        %p  1.000
      ==
    --
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
  ?:  ?=([%rpc-error *] error)
    ~&  >>>  "volt: rpc error: {<message.error>}"
    `state
  ~&  >>>  "volt: provider error: {<error>}"
  `state
::
++  handle-provider-result
  |=  =result:provider
  ^-  (quip card _state)
  ?-    -.result
      %node-info
    `state(node-info node-info.result)
  ::
      %invoice-added
    %+  fall
      %+  biff  (~(get by hahs) r-hash.result)
      |=  who=ship
      %+  bind  (~(get by pays) who)
      |=  paym=payment
      ~|  "invalid payment state"
      ?>  ?&  =(dire.paym %incoming)
              =(stat.paym %pending-invoice)
          ==
      =.  stat.paym  %pending-payment
      =.  pyre.paym  (some payment-request.result)
      :_  state(pays (~(put by pays) who paym))
      ~[(request-payment pyer.paym payment-request.result)]
    %-  (slog leaf+"{<r-hash.result>}" ~)
    `state
  ::
      %channel-update
    `state
  ::
      %payment-update
    %+  fall
      %+  biff  (~(get by hahs) hash.result)
      |=  who=ship
      %+  bind  (~(get by pays) who)
      |=  paym=payment
      ~|  "invalid payment state"
      ?>  ?&  =(dire.paym %outgoing)
              =(stat.paym %sent-payment)
          ==
      ?:  =(%'IN_FLIGHT' status.result)
        `state
       :_
         %_  state
           hahs  (~(del by hahs) hash.result)
           pays  (~(del by pays) who)
         ==
       ~
    `state
  ::
      %invoice-update
    %+  fall
      %+  biff  (~(get by hahs) r-hash.result)
      |=  who=ship
      %+  bind  (~(get by pays) who)
      |=  paym=payment
      ~|  "invalid payment state"
      ?>  ?&  =(dire.paym %incoming)
              =(stat.paym %pending-payment)
          ==
      ?.  settled.result
        `state
      :_
        %_  state
          hahs  (~(del by hahs) r-hash.result)
          pays  (~(del by pays) who)
        ==
      ~
    `state
  ::
      %balance-update
    %.  `state
    (slog leaf+"balance: {<total-balance.result>}" ~)
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
++  update-payment-status
  |=  paym=payment
  ^-  payment
  ?+    stat.paym  paym
      %sent-invoice-request
    paym(stat %pending-invoice)
  ::
      %sent-payment-request
    paym(stat %pending-payment)
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
    :*  %pass   pir
        %agent  dock
        %watch  /clients/[(scot %p our.bowl)]
    ==
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
++  request-payment
  |=  [who=@p req=cord]
  ^-  card
  :*  %pass   /payments/[(scot %p who)]
      %agent  [who %volt]
      %poke   %volt-action
      !>([%request-payment req])
  ==
::
++  request-invoice
  |=  [who=@p =amt=msats]
  ~&  >  "requesting invoice from {<who>} for {<amt-msats>}"
  ^-  card
  :*  %pass   /invoices/[(scot %p who)]
      %agent  [who %volt]
      %poke   %volt-action
      !>([%request-invoice amt-msats])
  ==
--
