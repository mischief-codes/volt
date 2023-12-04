import React, { useState } from 'react';
import Urbit from '@urbit/http-api';
import Channel from '../../types/Channel';

const CreateFunding = (
  { api, preopeningChannels }: { api: Urbit, preopeningChannels: Array<Channel> }
) => {
  const [selectedChannelId, setSelectedChannelId] = useState('');
  const [psbt, setPsbt] = useState('');

  const handleChangeSelectedChannel = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedChannelId(event.target.value);
  };

  const handleChangePsbt = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPsbt(event.target.value);
  };

  console.log(selectedChannelId, psbt)

  const createFunding = async (e: React.FormEvent) => {
    e.preventDefault();
    console.log(selectedChannelId, psbt)
    if (!selectedChannelId || !psbt) return;
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          'create-funding': {
            'temporary-channel-id': selectedChannelId,
            'psbt': psbt,
          }
        },
        onSuccess: () => console.log('success'),
        onError: () => console.log('failure'),
      });
      console.log(res);
    } catch (e) {
      console.error(e);
    }
  };

  const getChannelLabel = (channel: Channel) => {
    console.log('channel', channel, channel.id)
    return `${channel.who}, ${channel.our} sats, id=${channel.id.slice(0, 6)}...`
  }

  return (
    <form onSubmit={createFunding} className="flex flex-col space-y-4">
      <label className="flex flex-col">
        <span className="text-lg font-medium">Temporary channel:</span>
        <select
          value={selectedChannelId}
          onChange={handleChangeSelectedChannel}
          className="mt-1 p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          {preopeningChannels.map((channel) => (
            <option key={channel.id} value={channel.id}>
              {getChannelLabel(channel)}
            </option>
          ))}
        </select>
      </label>
      <label className="flex flex-col">
        <span className="text-lg font-medium">PSBT:</span>
        <input
          type="text"
          value={psbt}
          onChange={handleChangePsbt}
          className="mt-1 p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </label>
      <button
        type="submit"
        className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        Submit
      </button>
    </form>
  );
};

export default CreateFunding;
