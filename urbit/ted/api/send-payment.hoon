/-  spider, volt
/+  strand, io=strandio
=,  strand=strand:spider
|%
++  poke-volt
  |=  =command:volt
  :: ?>  =(%send-payment -.command)
  ?>  ?=([%send-payment =payreq:volt who=(unit @p)] command)
  ~&  payreq.command
  (poke-our:io %volt %volt-command !>(command))
++  watch-volt
  |=  =payreq:volt
  =/  m  (strand ,~)
  ;<  =bowl:spider  bind:m  get-bowl:io
  (watch-our:io /payment/outgoing/[payreq] %volt /payment/outgoing/[payreq])
++  take-result
  |=  =payreq:volt
  (take-fact:io /payment/outgoing/[payreq])
--
^-  thread:spider
|=  v=vase
=/  m  (strand ,vase)
=+  !<(=command:volt v)
:: ?>  =(%send-payment -.command)
?>  ?=([%send-payment =payreq:volt who=(unit @p)] command)
;<  ~  bind:m  (watch-volt payreq.command)
;<  ~  bind:m  (poke-volt command)
;<  =cage  bind:m  (take-result payreq.command)
?>  =(%volt-update p.cage)
(pure:m q.cage)
