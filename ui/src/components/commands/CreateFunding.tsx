import React, { useState, useContext, useMemo } from 'react';
import Urbit from '@urbit/http-api';
import Channel from '../../types/Channel';
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from './shared/Input';
import Dropdown from './shared/Dropdown';
import CommandForm from './shared/CommandForm';
import CopyButton from './shared/CopyButton';

const CreateFunding = (
  { api, preopeningChannels }: { api: Urbit, preopeningChannels: Array<Channel> }
) => {

  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);

  const ourPreopeningChannels = useMemo(() => {
    return preopeningChannels.filter(channel => channel.fundingAddress);
  }, [preopeningChannels]);
  const [channel, setChannel] = useState(ourPreopeningChannels[0] || null);
  const [psbt, setPsbt] = useState('');

  const psbtCommand: null | string = useMemo(() => {
    if (!channel?.fundingAddress) return (null);
    return `bitcoin-cli walletprocesspsbt $(bitcoin-cli walletcreatefundedpsbt "[]" `
      + `"[{\\"${channel.fundingAddress as string}\\":${channel.our.asBtc()}}]" `
      + `| grep -o '"psbt": "[^"]*' | cut -d'"' -f4) | grep -o '"psbt": "[^"]*' | cut -d'"' -f4`;
  }, [channel]);

  const onChangeSelectedChannel = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setChannel(ourPreopeningChannels.find(channel => channel.id === event.target.value) as Channel);
  };

  const onChangePsbt = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPsbt(event.target.value);
  };

  const createFunding = (e: React.FormEvent) => {
    e.preventDefault();
    if (!psbt) {
      displayJsError("PSBT required")
      return;
    }
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
      displayJsError('Error creating funding');
      console.error(e);
    }
  };

  const getChannelLabel = (channel: Channel) => {
    return `~${channel.who}, ${channel.our.displayAsSats()}, id=${channel.id.slice(0, 12)}...`
  }

  const options = ourPreopeningChannels.map((channel) => {
    return { value: channel.id, label: getChannelLabel(channel) }
  });

  return (
    <>
      {ourPreopeningChannels.length > 0 ? (
        <CommandForm>
        <Dropdown
          label={"Channel"}
          value={channel.id}
          options={options}
          onChange={onChangeSelectedChannel}
        />
        <CopyButton label={'Run this to get PSBT'} buttonText='Copy script' copyText={psbtCommand}/>
        <Input label={"PSBT"} value={psbt} onChange={onChangePsbt} />
        <Button onClick={createFunding} label='Create Funding'/>
        </CommandForm>
      ) : <div className='text-center'>No preopening channels</div>}
    </>
  );
};

export default CreateFunding;
