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
:: ;<  eny=@uvJ  bind:m  get-entropy:io
:: =.  id.action  eny
:: =/  id  (scot %uv eny)
~&  >  "attempt {<try>} to watch btcp result"
;<  ~  bind:m  (watch-our:io /btcp-update/[id.action] %btc-provider /clients/[id.action])
?:  (lte try crash-after)
  (request act)
(pure:m [%fail ~])
++  request
  |=  act=action:bp
  ^-  form:m
  =/  m  (strand ,~)
  ;<  ~  bind:m  (backoff:io try crash-after)
  ;<  ~  bind:m  (poke-our:io %btc-provider [%btc-provider-action !>(act)])
  ~&  >  "attempt {<try>} to poke btcp"
  ;<  =update:bp  bind:m  (take-fact:io /btcp-update/[id.action])
  ?:  ?=(%& -.upd)
    ~&  >  "btcp result received"
    (pure:m +.update)
  ~&  >  "%volt: attempt {<try>} at %btc-provider action failed with"
  ~&  >  "{<+.+.update>}"
  ;<  ~  bind:m  (leave-our:io /clients/[id.action])
  ^$(try +(try))
--