/-  spider, volt
/+  strand, io=strandio
=,  strand=strand:spider
|%
++  poke-volt
  |=  =command:volt
  ?>  =(%send-payment -.command)
  (poke-our:io %volt %volt-command !>(command))
++  watch-volt
  =/  m  (strand ,~)
  ;<  =bowl:spider  bind:m  get-bowl:io
  (watch-our:io /[payreq.command] %volt /[payreq.command])
++  take-result
  (take-fact:io /[payreq.command])
--
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
=+  !<(=command:volt vase)
;<  ~  bind:m  watch-volt
;<  ~  bind:m  (poke-volt command)
;<  =cage  bind:m  take-result
?>  =(%volt-update p.cage)
(pure:m q.cage)