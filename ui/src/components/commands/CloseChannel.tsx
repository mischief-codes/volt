import React, { useState, useEffect, useContext } from 'react';
import Urbit from '@urbit/http-api';
import Channel from '../../types/Channel';
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Dropdown from './shared/Dropdown';
import CommandForm from './shared/CommandForm';

const CloseChannel = ({ api, openChannels }: { api: Urbit, openChannels: Array<Channel> }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);
  const [channelId, setChannelId] = useState(openChannels[0]?.id || null);

  useEffect(() => {
    if (channelId === null && openChannels.length > 0) {
      setChannelId(openChannels[0].id)
    }
  }, [openChannels]);


  const onChangeChannelId = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setChannelId(event.target.value);
  }

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

  const getChannelLabel = (channel: Channel) => {
    return `${channel.who}, ${channel.our} sats, id=${channel.id.slice(0, 6)}...`
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
