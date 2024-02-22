/-  spider, volt
/+  strand, io=strandio
=,  strand=strand:spider
^-  thread:spider
|=  v=vase
=/  m  (strand ,vase)
=+  !<(=command:volt arg)
?>  ?=(%send-payment -.command)
;<  =bowl:spider  bind:m  get-bowl:io
;<  ~  bind:m  (watch-our:io /[payreq.command] %volt /latest-invoice)
;<  ~  bind:m  (poke-our:io %volt %volt-command !>(command))
;<  =cage  bind:m  (take-fact:io /[payreq.command])
?>  =(%volt-update p.cage)
(pure:m q.cage)
