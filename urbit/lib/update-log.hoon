::  update-log.hoon: update-log manipulation
/-  *bolt
|_  log=update-log
::
++  append-update
  |=  =update
  ^-  update-log
  ?>  =(index.update update-count.log)
  %=  log
    list          (snoc list.log update)
    update-index  (~(put by update-index.log) update-count.log update)
    update-count  +(update-count.log)
  ==
::
++  append-htlc
  |=  =update
  ^-  update-log
  ?>  =(index.update update-count.log)
  %=  log
    list          (snoc list.log update)
    update-count  +(update-count.log)
    htlc-index    (~(put by htlc-index.log) htlc-count.log update)
    htlc-count    +(htlc-count.log)
  ==
::
++  lookup-htlc
  |=  =htlc-id
  ^-  (unit update)
  (~(get by htlc-index.log) htlc-id)
::
++  remove-update
  |=  index=@
  ^-  update-log
  =+  entry=(~(get by update-index.log) index)
  ?~  entry  log
  %=  log
    list          (oust [index 1] list.log)
    update-index  (~(del by update-index.log) index)
  ==
::
++  remove-htlc
  |=  =htlc-id
  ^-  update-log
  =+  entry=(~(get by htlc-index.log) htlc-id)
  ?~  entry  log
  =+  index=(find ~[entry] list.log)
  ?~  index  log
  %=  log
    list        (oust [u.index 1] list.log)
    htlc-index  (~(del by htlc-index.log) htlc-id)
  ==
--
