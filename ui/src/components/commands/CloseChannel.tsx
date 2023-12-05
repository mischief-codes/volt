import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import Channel from '../../types/Channel';
import Button from '../shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';

const CloseChannel = ({ api, openChannels }: { api: Urbit, openChannels: Array<Channel> }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);
  const [channelId, setChannelId] = useState(openChannels[0]?.id || null);

  const closeChannel  = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!channelId) return;
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {"close-channel": channelId },
        onSuccess: () => displaySuccess(Command.CloseChannel),
        onError: (e) => displayError(Command.CloseChannel, e),
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
      <Button onClick={closeChannel} label={'Close Channel'}/>
      </form>
    ) : <div>No open channels</div>}
    </div>
  );
};

export default CloseChannel;
