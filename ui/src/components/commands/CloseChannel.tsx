import React, { useState, useEffect, useContext } from 'react';
import Urbit from '@urbit/http-api';
import Channel from '../../types/Channel';
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Dropdown from './shared/Dropdown';
import CommandForm from './shared/CommandForm';

const CloseChannel = ({ api, openChannels }: { api: Urbit, openChannels: Array<Channel> }) => {
  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);
  const [channelId, setChannelId] = useState(openChannels[0]?.id || null);

  useEffect(() => {
    if (channelId === null && openChannels.length > 0) {
      setChannelId(openChannels[0].id)
    }
  }, [openChannels]);


  const onChangeChannelId = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setChannelId(event.target.value);
  }

  const closeChannel  = (e: React.FormEvent) => {
    e.preventDefault();
    if (!channelId) return;
    try {
      api.poke({
        app: "volt",
        mark: "volt-command",
        json: {"close-channel": channelId },
        onSuccess: () => displayCommandSuccess(Command.CloseChannel),
        onError: (e) => displayCommandError(Command.CloseChannel, e),
      });
    } catch (e) {
      displayJsError('Error closing channel')
    }
  }

  const getChannelLabel = (channel: Channel) => {
    return `${channel.who}, ${channel.our.displayAsSats()}, id=${channel.id.slice(0, 12)}...`
  }

  const options = openChannels.map((channel) => {
    return { value: channel.id, label: getChannelLabel(channel) }
  })

  return (
    <>
      {openChannels.length > 0 ? (
      <CommandForm>
          <Dropdown
            label={"Channel"}
            value={channelId}
            options={options}
            onChange={onChangeChannelId}
          />
        <Button onClick={closeChannel} label={'Close Channel'}/>
      </CommandForm>
    ) : <div className='text-center'>No open channels</div>}
    </>
  );
};

export default CloseChannel;
