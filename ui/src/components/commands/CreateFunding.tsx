import React, { useState, useContext, useMemo, useEffect } from 'react';
import Urbit from '@urbit/http-api';
import Channel, { ChannelStatus, FundingAddress } from '../../types/Channel';
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from './shared/Input';
import Dropdown from './shared/Dropdown';
import CommandForm from './shared/CommandForm';
import CopyButton from './shared/CopyButton';
import Network from '../../types/Network';
import { ChannelContext } from '../../contexts/ChannelContext';
import HotWalletFunding from './shared/HotWalletFunding';

const FUNDING_SOURCE_HOT_WALLET = 'Hot wallet';
const FUNDING_SOURCE_PSBT = 'PSBT';

const CreateFunding = (
  { api }: { api: Urbit}
) => {
  const { preopeningChannels } = useContext(ChannelContext);
  const { tauAddressByTempChanId, fundingAddressByTempChanId } = useContext(ChannelContext);


  const [selectedChannel, setSelectedChannel] = useState<Channel | null>(null);
  const [fundingSource, setFundingSource] = useState(FUNDING_SOURCE_HOT_WALLET);

  const fundableChannels = preopeningChannels.filter(channel => {
    return tauAddressByTempChanId[channel.id] && fundingAddressByTempChanId[channel.id]
});

  useEffect(() => {
    if (!selectedChannel && fundableChannels.length > 0) {
      setSelectedChannel(fundableChannels[0]);
    }
  }, [preopeningChannels])

  const onChangeSelectedChannel = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedChannel(fundableChannels.find(channel => channel.id === event.target.value) as Channel);
  };

  const onChangeFundingSource = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setFundingSource(event.target.value);
  }

  const getChannelLabel = (channel: Channel) => {
    return `~${channel.who}, ${channel.our.displayAsSats()}, id=${channel.id.slice(0, 12)}...`
  }

  const fundingSourceOptions = [
    { value: FUNDING_SOURCE_HOT_WALLET, label: 'Hot wallet' },
    { value: FUNDING_SOURCE_PSBT, label: 'PSBT' }
  ];

  const channelOptions = fundableChannels.map((channel) => {
    return { value: channel.id, label: getChannelLabel(channel) }
  });

  const tauAddress = tauAddressByTempChanId[selectedChannel?.id as ChannelStatus];
  const fundingAddress = fundingAddressByTempChanId[selectedChannel?.id as ChannelStatus];

  return (
    <>
      {selectedChannel ? (
        <CommandForm>
        <Dropdown
          label={"Funding Source"}
          value={fundingSource}
          options={fundingSourceOptions}
          onChange={onChangeFundingSource}
        />
        <Dropdown
          label={"Channel"}
          value={selectedChannel.id}
          options={channelOptions}
          onChange={onChangeSelectedChannel}
        />
        { fundingSource === FUNDING_SOURCE_PSBT
          ? <CreateFundingPSBT api={api} selectedChannel={selectedChannel} fundingAddress={fundingAddress}/>
          : <HotWalletFunding channel={selectedChannel} tauAddress={tauAddress} close={null}/>}
        </CommandForm>
      ) : <div className='text-center'>No fundable channels</div>}
    </>
  );
};

const CreateFundingPSBT = (
  { api, selectedChannel, fundingAddress }: { api: Urbit, selectedChannel: Channel, fundingAddress: FundingAddress}
) => {
  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);
  const { fundingAddressByTempChanId } = useContext(ChannelContext);

  const [psbt, setPsbt] = useState('');

  const psbtCommand: null | string = useMemo(() => {
    const networkFlag = selectedChannel.network === Network.Regtest ? '-regtest' : '';
    return `bitcoin-cli ${networkFlag} walletprocesspsbt `
      + `$(bitcoin-cli ${networkFlag} walletcreatefundedpsbt "[]" `
      + `"[{\\"${fundingAddress as string}\\":${selectedChannel.our.asBtc()}}]" `
      + `| grep -o '"psbt": "[^"]*' | cut -d'"' -f4) | grep -o '"psbt": "[^"]*' | cut -d'"' -f4`;
  }, [selectedChannel, fundingAddressByTempChanId]);

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
            'temporary-channel-id': selectedChannel.id,
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

  return (
    <>
      <CopyButton label={'Run this to get PSBT'} buttonText='Copy script' copyText={psbtCommand}/>
      <Input label={"PSBT"} value={psbt} onChange={onChangePsbt} />
      <Button onClick={createFunding} label='Create Funding'/>
    </>
  );
}

export default CreateFunding;
