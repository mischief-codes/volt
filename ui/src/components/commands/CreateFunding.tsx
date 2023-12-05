import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import Channel from '../../types/Channel';
import Button from '../shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';

const CreateFunding = (
  { api, preopeningChannels }: { api: Urbit, preopeningChannels: Array<Channel> }
) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);
  const [channelId, setChannelId] = useState('aaa')// useState(preopeningChannels[0]?.id || null);
  const [psbt, setPsbt] = useState('');

  const handleChangeSelectedChannel = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setChannelId(event.target.value);
  };

  const handleChangePsbt = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPsbt(event.target.value);
  };

  const createFunding = async (e: React.FormEvent) => {
    e.preventDefault();
    console.log('create funding')
    if (!channelId || !psbt) return;
    try {
      console.log(1)
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          'create-funding': {
            'temporary-channel-id': channelId,
            'psbt': psbt,
          }
        },
        onSuccess: () => displaySuccess(Command.CreateFunding),
        onError: (e) => displayError(Command.CreateFunding, e),
      });
      console.log(2);
      console.log(res);
    } catch (e) {
      console.error('error creating funding', e);
    }
  };

  const getChannelLabel = (channel: Channel) => {
    return `${channel.who}, ${channel.our} sats, id=${channel.id.slice(0, 6)}...`
  }

  return (
    <div>
      {preopeningChannels.length > 1 ? (
      <form onSubmit={createFunding} className="flex flex-col space-y-4">
        <label className="flex flex-col">
          <span>Temporary channel</span>
          <select
            value={channelId}
            onChange={handleChangeSelectedChannel}
            className="mt-1 p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-orange-300"
          >
            {preopeningChannels.map((channel) => (
              <option key={channel.id} value={channel.id}>
                {getChannelLabel(channel)}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col">
          <span>PSBT</span>
          <input
            type="text"
            value={psbt}
            onChange={handleChangePsbt}
            className="mt-1 p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-orange-300"
          />
        </label>
        <Button onClick={createFunding} label='Create Funding' className="mx-auto w-min whitespace-nowrap" />
      </form>
      ) : <div>No preopening channels</div>}
    </div>
  );
};

export default CreateFunding;
