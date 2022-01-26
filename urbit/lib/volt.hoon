::
::  lib/volt.hoon
::
/-  spider, volt, bc=bitcoin
/+  *strandio, bcu=bitcoin-utils
=,  strand=strand:spider
|%
++  rpc
  |_  =host-info:provider:volt
  ::
  ++  enjs
    =,  enjs:format
    |%
    ++  action
      |=  act=action:rpc:volt
      |^  ^-  json
      ?+  -.act  ~|("Unknown request type" !!)
        %open-channel        (open-channel +.act)
        %settle-htlc         (settle-htlc +.act)
        %fail-htlc           (fail-htlc +.act)
        %send-payment        (send-payment +.act)
        %add-invoice         (add-invoice +.act)
      ==
      ++  open-channel
        |=  [=pubkey:volt local-amt=sats:bc push-amt=sats:bc]
        ^-  json
        %-  pairs
        :~  ['node_pubkey' [%s (en:base64:mimes:html pubkey)]]
            ['local_funding_amount' (numb local-amt)]
            ['push_sat' (numb push-amt)]
        ==
      ::
      ++  settle-htlc
        |=  [ck=circuit-key:rpc:volt preimage=hexb:bc]
        ^-  json
        %-  pairs
        :~  ['circuit_key' (circuit-key ck)]
            ['action' [%s 'SETTLE']]
            ['preimage' [%s (en:base64:mimes:html preimage)]]
        ==
      ::
      ++  fail-htlc
        |=  ck=circuit-key:rpc:volt
        ^-  json
        %-  pairs
        :~  ['circuit_key' (circuit-key ck)]
            ['action' [%s 'FAIL']]
        ==
      ::
      ++  send-payment
        |=  [invoice=cord timeout=(unit @dr) fee-limit=(unit sats:bc)]
        ^-  json
        %-  pairs
        :~  ['payment_request' [%s invoice]]
            ['timeout_seconds' (numb (div (fall timeout ~s30) ~s1))]
            ['fee_limit_sat' (numb (fall fee-limit 0))]
        ==
      ::
      ++  add-invoice
        |=  $:  amt=msats:volt
                memo=(unit cord)
                preimage=(unit preimage:volt)
                hash=(unit hash:volt)
                expiry=(unit @dr)
            ==
        |^  ^-  json
        %-  pairs
        :~  ['memo' [%s (fall memo '')]]
            ['value_msat' (numb amt)]
            ['r_hash' [%s r-hash]]
            ['r_preimage' [%s r-preimage]]
            ['expiry' expiry-time]
        ==
        ++  expiry-time
          %-  numb
          %+  div
            (fall expiry ~h1)
          ~s1
        ::
        ++  r-hash
          %+  fall
            %+  bind  hash
            |=  h=hash:volt
            %-  en:base64:mimes:html
            %-  flip:byt:bcu  h
          ''
        ::
        ++  r-preimage
          %+  fall
            %+  bind  preimage
            |=  pre=preimage:volt
            %-  en:base64:mimes:html
            %-  flip:byt:bcu  pre
          ''
        --
      ::
      ++  circuit-key
        |=  ck=circuit-key:rpc:volt
        ^-  json
        %-  pairs
        :~  ['chan_id' (numb chan-id.ck)]
            ['htlc_id' (numb htlc-id.ck)]
        ==
      --
    --
  ::
  ++  dejs
    =,  dejs:format
    |%
    ++  base64
      %+  cu  flip:byt:bcu
      %-  su  parse:base64:mimes:html
    ::
    ++  hex     (su rule:base16:mimes:html)
    ::
    ++  channel-update
      |=  =json
      |^  ^-  channel-update:rpc:volt
      ?+    (update-type json)  ~|('Unknown update type' !!)
          %'OPEN_CHANNEL'
        [%open-channel (open-channel json)]
      ::
          %'CLOSED_CHANNEL'
        [%closed-channel (closed-channel json)]
      ::
          %'ACTIVE_CHANNEL'
        [%active-channel (active-channel json)]
      ::
          %'INACTIVE_CHANNEL'
        [%inactive-channel (inactive-channel json)]
      ::
          %'PENDING_OPEN_CHANNEL'
        [%pending-channel (pending-channel json)]
      ==
      ++  update-type
        %-  ot  ['type' so]~
      ::
      ++  channel-data
        |*  [k=cord a=fist]
        %-  ot  [k a]~
      ::
      ++  active-channel
        %+  channel-data  'active_channel'
        %-  ot
        :~  ['funding_txid_bytes' base64]
            ['output_index' ni]
        ==
      ::
      ++  inactive-channel
        %+  channel-data  'inactive_channel'
        %-  ot
        :~  ['funding_txid_bytes' base64]
            ['output_index' ni]
        ==
      ::
      ++  closed-channel
        %+  channel-data  'closed_channel'
        %-  ot
        :~  ['channel_point' so]
            ['chan_id' (su dim:ag)]
            ['chain_hash' so]
            ['closing_tx_hash' so]
            ['remote_pubkey' hex]
            ['close_type' so]
        ==
      ::
      ++  pending-channel
        %+  channel-data  'pending_open_channel'
        %-  ot
        :~  ['txid' base64]
            ['output_index' ni]
        ==
      ::
      ++  open-channel
        %+  channel-data  'open_channel'
        %-  ot
        :~  ['active' bo]
            ['remote_pubkey' hex]
            ['channel_point' so]
            ['chan_id' (su dim:ag)]
            ['capacity' (su dim:ag)]
            ['local_balance' (su dim:ag)]
            ['remote_balance' (su dim:ag)]
            ['commit_fee' (su dim:ag)]
            ['total_satoshis_sent' (su dim:ag)]
        ==
      --
    ::
    ++  htlc-intercept-request
      |=  =json
      |^  ^-  htlc-intercept-request:rpc:volt
      %.  json
      %-  ot
      :~  ['incoming_circuit_key' circuit-key]
          ['incoming_amount_msat' (su dim:ag)]
          ['incoming_expiry' ni]
          ['payment_hash' base64]
          ['outgoing_requested_chan_id' (su dim:ag)]
          ['outgoing_amount_msat' (su dim:ag)]
          ['outgoing_expiry' ni]
          ['onion_blob' base64]
      ==
      ++  circuit-key
        %-  ot
        :~  ['chan_id' (su dim:ag)]
            ['htlc_id' (su dim:ag)]
        ==
      ::
      ++  custom-record
        %-  ot
        :~  ['key' ni]
            ['value' base64]
        ==
      --
    ::
    ++  payment
      |=  =json
      |^  ^-  payment:rpc:volt
      %.  json
      %-  ot
      :~  ['payment_hash' hex]
          ['payment_preimage' hex]
          ['value_msat' (su dim:ag)]
          ['fee_msat' (su dim:ag)]
          ['payment_request' so]
          ['status' (cu payment-status:rpc:volt so)]
          ['failure_reason' (cu payment-failure-reason:rpc:volt so)]
          ['creation_time_ns' unix-ns]
      ==
      ++  unix-ns
        %+  cu
          |=  a=@
          %-  from-unix-ms:chrono:userlib
            (div a 1.000)
        (su dim:ag)
      --
    ::
    ++  wallet-balance-response
      %-  ot
      :~  ['total_balance' (su dim:ag)]
          ['confirmed_balance' (su dim:ag)]
          ['unconfirmed_balance' (su dim:ag)]
      ==
    ::
    ++  add-invoice-response
      %-  ot
      :~  ['r_hash' base64]
          ['payment_request' so]
          ['add_index' (su dim:ag)]
          ['payment_addr' base64]
      ==
    ::
    ++  invoice
      =,  chrono:userlib
      |^
      %-  ot
      :~  ['memo' so]
          ['r_preimage' base64]
          ['r_hash' base64]
          ['value_msat' (su dim:ag)]
          ['settled' bo]
          ['creation_date' unix-date]
          ['settle_date' unix-date]
          ['expiry' seconds]
          ['payment_request' so]
          ['add_index' (su dim:ag)]
          ['settle_index' (su dim:ag)]
          ['amt_paid_msat' (su dim:ag)]
          ['state' invoice-state]
      ==
      ++  invoice-state  (cu invoice-state:rpc:volt so)
      ++  unix-date      (cu from-unix (su dim:ag))
      ++  seconds        (cu |=(a=@ (mul a ~s1)) (su dim:ag))
      --
    ::
    ++  result
      |=  [act=action:rpc:volt jon=json]
      |^  ^-  result:rpc:volt
      ?-    -.act
          %get-info
        =/  info=[version=@t commit-hash=@t pubkey=hexb:bc]
          (node-info jon)
        :*  %get-info
          version.info
          commit-hash.info
          (decompress-point:secp256k1:secp:crypto dat.pubkey.info)
        ==
      ::
          %wallet-balance
        =/  [total=msats:volt confirmed=msats:volt unconfirmed=msats:volt]
        %-  wallet-balance-response  jon
        [%wallet-balance total confirmed unconfirmed]
      ::
          %open-channel
        [%open-channel (channel-point jon)]
      ::
          %close-channel
        [%close-channel ~]
      ::
          %settle-htlc
        [%settle-htlc circuit-key.act]
      ::
          %fail-htlc
        [%fail-htlc circuit-key.act]
      ::
          %send-payment
        [%send-payment ~]
      ::
          %add-invoice
        [%add-invoice (add-invoice-response jon)]
      ::
          %cancel-invoice
        [%cancel-invoice ~]
      ==
      ++  node-info
        %-  ot
        :~  [%version so]
            ['commit_hash' so]
            ['identity_pubkey' hex]
        ==
      ::
      ++  channel-point
        %-  ot
        :~  ['funding_txid_bytes' (su parse:base64:mimes:html)]
            ['output_index' ni]
        ==
      --
    ::
    ++  error
      |=  jon=json
      ^-  error:rpc:volt
      %.  jon
      %-  ot
      :~  [%code ni]
          [%message so]
      ==
    --
  ::
  ++  action-to-request
    |=  act=action:rpc:volt
    |^  ^-  request:http
    ?-    -.act
        %get-info
      %-  get-request
      %+  url  '/getinfo'  ''
    ::
        %open-channel
      %+  post-request
      %+  url  '/channel'  ''
      act
    ::
        %close-channel
      =/  txid=@t  (~(en base64:mimes:html & &) funding-txid.act)
      =/  oidx=@t  (scot %ud output-index.act)
      =/  parms    (cat 3 (cat 3 txid '/') oidx)
      %-  delete-request
      %+  url  '/channel/'  parms
    ::
        %settle-htlc
      %+  post-request
      %+  url  '/resolve_htlc'  ''
      act
    ::
        %fail-htlc
      %+  post-request
      %+  url  '/resolve_htlc'  ''
      act
    ::
        %wallet-balance
      %-  get-request
      %+  url  '/wallet_balance'  ''
    ::
        %send-payment
      %+  post-request
      %+  url  '/payment'  ''
      act
    ::
        %add-invoice
      %+  post-request
      %+  url  '/invoice'  ''
      act
    ::
        %cancel-invoice
      %-  delete-request
      %+  url  '/invoice/'
      %-  ~(en base64:mimes:html & &)
      %-  flip:byt:bcu  payment-hash.act
    ==
    ++  url
      |=  [route=@t params=@t]
      %^    cat
          3
        (cat 3 api-url.host-info route)
      params
    ::
    ++  get-request
      |=  url=@t
      ^-  request:http
      [%'GET' url ~ ~]
    ::
    ++  delete-request
      |=  url=@t
      ^-  request:http
      [%'DELETE' url ~ ~]
    ::
    ++  post-request
      |=  [url=@t act=action:rpc:volt]
      ^-  request:http
      :*  %'POST'
          url
          ['Content-Type' 'application/json']~
          =,  html
          %-  some
          %-  as-octt:mimes
          %-  en-json
          (action:enjs act)
      ==
    --
  ::
  ++  status-code
    |=  =client-response:iris
    =/  m  (strand ,@ud)
    ^-  form:m
    ?>  ?=(%finished -.client-response)
    (pure:m status-code.response-header.client-response)
  ::
  ++  send
    |=  act=action:rpc:volt
    =/  m              (strand ,response:rpc:volt)
    =/  =request:http  (action-to-request act)
    ^-  form:m
    ;<  ~                      bind:m  (send-request request)
    ;<  =client-response:iris  bind:m  take-client-response
    ;<  status=@ud             bind:m  (status-code client-response)
    ;<  body=@t                bind:m  (extract-body client-response)
    =/  jon=(unit json)  (de-json:html body)
    ?~  jon
      %-  (slog leaf+"{<body>}")
      (strand-fail:strand %json-parse-error ~)
    %-  pure:m
      ?:  =(status 200)
        [%& (result:dejs act u.jon)]
        [%| (error:dejs u.jon)]
  --
--
