import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import Channel from '../../types/Channel';
import Button from '../basic/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from '../basic/Input';
import Dropdown from '../basic/Dropdown';
import CommandForm from './CommandForm';

const CreateFunding = (
  { api, preopeningChannels }: { api: Urbit, preopeningChannels: Array<Channel> }
) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);
  const [channelId, setChannelId] = useState(preopeningChannels[0]?.id || null);
  const [psbt, setPsbt] = useState('');

  const onChangeSelectedChannel = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setChannelId(event.target.value);
  };

  const onChangePsbt = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPsbt(event.target.value);
  };

  const createFunding = (e: React.FormEvent) => {
    e.preventDefault();
    if (!channelId || !psbt) return;
    try {
      api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          'create-funding': {
            'temporary-channel-id': channelId,
            'psbt': psbt,
          }
        },
        onSuccess: () => displaySuccess(Command.CreateFunding),
        onError: (e) => displayError(e),
      });
    } catch (e) {
      console.error('error creating funding', e);
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
      {preopeningChannels.length > 1 ? (
        <CommandForm>
        <Dropdown
          label={"Channel"}
          value={channelId}
          options={options}
          onChange={onChangeSelectedChannel}
        />
        <Input label={"PSBT"} value={psbt} onChange={onChangePsbt} />
        <Button onClick={createFunding} label='Create Funding'/>
        </CommandForm>
      ) : <div>No preopening channels</div>}
    </>
  );
};

export default CreateFunding;
