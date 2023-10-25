/-  *volt
|_  upd=update
++  grab
  |%
  ++  noun  update
  --
++  grow
  |%
  ++  noun  upd
  ++  json
    =,  enjs:format
    ^-  json
    ?+    -.upd  !!
        %new-invoice
      %-  pairs
      :~  ['payreq' s/payreq.upd]
      ==
  --
++  grad  %noun
--