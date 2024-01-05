import React, { useState, useContext, useEffect, useMemo } from 'react';
import Urbit from '@urbit/http-api';
import Channel from '../../types/Channel';
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from './shared/Input';
import Dropdown from './shared/Dropdown';
import CommandForm from './shared/CommandForm';

const CreateFunding = (
  { api, preopeningChannels }: { api: Urbit, preopeningChannels: Array<Channel> }
) => {
  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);
  const [channel, setChannel] = useState(preopeningChannels[0] || null);
  const [fundingAddress, setFundingAddress] = useState('bcrt1qnp2m0aycurk9gty58d48pv3gpcmap0gwz8h6nvafl9syqut6t7dssy3tep');
  const [psbt, setPsbt] = useState('');

  const psbtCommand: null | string = useMemo(() => {
    if (!fundingAddress || !channel) return (null);
    return `bitcoin-cli walletprocesspsbt $(bitcoin-cli walletcreatefundedpsbt "[]" `
      + `"[{\\"${fundingAddress}\\":${channel.our.asBtc()}}]" `
      + `| grep -o '"psbt": "[^"]*' | cut -d'"' -f4) | grep -o '"psbt": "[^"]*' | cut -d'"' -f4`;
  }, [fundingAddress, channel]);

  const onChangeSelectedChannel = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setChannel(preopeningChannels.find(channel => channel.id === event.target.value) as Channel);
  };

  const onChangePsbt = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPsbt(event.target.value);
  };

  const createFunding = (e: React.FormEvent) => {
    e.preventDefault();
    if (!channel || !psbt) return;
    console.log('createFunding', channel.id, psbt)
    try {
      api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          'create-funding': {
            'temporary-channel-id': channel.id,
            'psbt': psbt,
          }
        },
        onSuccess: () => displayCommandSuccess(Command.CreateFunding),
        onError: (e) => displayCommandError(Command.CreateFunding, e),
      });
    } catch (e) {
      displayJsError('Error creating funding')
    }
  };

  const getChannelLabel = (channel: Channel) => {
    return `${channel.who}, ${channel.our} sats, id=${channel.id.slice(0, 6)}...`
  }

  const options = preopeningChannels.map((channel) => {
    return { value: channel.id, label: getChannelLabel(channel) }
  });

  return (
    <>
      {preopeningChannels.length > 0 ? (
        <CommandForm>
        <Dropdown
          label={"Channel"}
          value={channel.id}
          options={options}
          onChange={onChangeSelectedChannel}
        />
        <Input label={"PSBT"} value={psbt} onChange={onChangePsbt} />
        <Button onClick={createFunding} label='Create Funding'/>
        </CommandForm>
      ) : <div className='text-center'>No preopening channels</div>}
    </>
  );
};

export default CreateFunding;
