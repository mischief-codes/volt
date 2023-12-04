import React, { useState } from 'react';
import Urbit from '@urbit/http-api';
import Channel, { ChannelId } from '../../types/Channel';

const CloseChannel = ({ api, openChannels }: { api: Urbit, openChannels: Array<Channel> }) => {
  const [channelId, setChannelId] = useState('');

  const closeChannel  = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!channelId) return;
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {"close-channel": channelId },
        onSuccess: () => console.log('success'),
        onError: () => console.log('failure'),
      });
      console.log(res);
    } catch (e) {
      console.error(e);
    }
  }

  const onChangeChannelId = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setChannelId(event.target.value);
  }

  const getChannelLabel = (channel: Channel) => {
    return `${channel.who}, ${channel.our} sats, id=${channel.id.slice(0, 6)}...`
  }


  return (
    <div className="close-channel">
      {openChannels.length > 0 ? (
      <form onSubmit={closeChannel} className="flex flex-col items-center">
      <label className="block mb-2">
        Channel:
        <select
          value={channelId}
          onChange={onChangeChannelId}
          className="border border-gray-300 rounded-md px-2 py-1 w-full"
        >
          {openChannels.map((channel) => (
            <option key={channel.id} value={channel.id}>
              {getChannelLabel(channel)}
            </option>
          ))}
        </select>
      </label>
      <button type="submit" className="close-button bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
        Close Channel
      </button>
      </form>
    ) : <div>No open channels</div>}
    </div>
  );
};

export default CloseChannel;
