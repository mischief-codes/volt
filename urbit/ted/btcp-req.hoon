/-  spider, bp=btc-provider
/+  strand, io=strandio
=,  strand=strand:spider
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
=/  =action:bp !<(action:bp arg)
=/  crash-after  3
=|  try=@
|^  ^-  form:m
;<  eny=@uvJ  bind:m  get-entropy:io
=.  action.id  eny
=/  id  (scot %uv eny)
;<  ~  bind:m  (watch-our:io /btcp-update/[id] %btc-provider /clients/[id])
?:  (lte try crash-after)
  (request id act)
(pure:m [%fail ~])
++  request
  |=  [id=@uvJ act=action:bp]
  ^-  form:m
  =/  m  (strand ,~)
  ;<  ~  bind:m  (backoff:io try crash-after)
  ;<  ~  bind:m  (poke-our:io %btc-provider [%btc-provider-action !>(act)])
  ;<  =update:bp  bind:m  (take-fact:io /btcp-update/[id])
  ?:  ?=(%& -.upd)
    (pure:m +.update)
  ~&  >  "%volt: attempt {<try>} at %btc-provider action failed with"
  ~&  >  "{<+.+.update>}"
  ^$(try +(try))
--