import React, { useState, useContext, useMemo, useEffect } from 'react';
import Urbit from '@urbit/http-api';
import Channel, { ChannelStatus } from '../../types/Channel';
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from './shared/Input';
import Text from './shared/Text';
import Dropdown from './shared/Dropdown';
import CommandForm from './shared/CommandForm';
import CopyButton from './shared/CopyButton';
import { HotWalletContext } from '../../contexts/HotWalletContext';
import BitcoinAmount from '../../types/BitcoinAmount';
import Network from '../../types/Network';
import { ChannelContext } from '../../contexts/ChannelContext';

const FUNDING_SOURCE_HOT_WALLET = 'Hot wallet';
const FUNDING_SOURCE_PSBT = 'PSBT';

const CreateFunding = (
  { api }: { api: Urbit}
) => {
  const { preopeningChannels } = useContext(ChannelContext);
  const { tauAddressByTempChanId, fundingAddressByTempChanId } = useContext(HotWalletContext);

  const fundableChannels = useMemo(() => {
    return preopeningChannels.filter(channel => {
      return tauAddressByTempChanId[channel.id] && fundingAddressByTempChanId[channel.id]
  });
  }, [preopeningChannels]);

  const [selectedChannel, setSelectedChannel] = useState(fundableChannels[0] || null);
  const [fundingSource, setFundingSource] = useState(FUNDING_SOURCE_HOT_WALLET);

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
        { fundingSource === FUNDING_SOURCE_PSBT ? <CreateFundingPSBT api={api} selectedChannel={selectedChannel}/> : <CreateFundingHotWallet selectedChannel={selectedChannel} />}
        </CommandForm>
      ) : <div className='text-center'>No fundable channels</div>}
    </>
  );
};

const CreateFundingPSBT = (
  { api, selectedChannel }: { api: Urbit, selectedChannel: Channel }
) => {
  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);
  const { fundingAddressByTempChanId } = useContext(HotWalletContext);

  const [psbt, setPsbt] = useState('');

  const psbtCommand: null | string = useMemo(() => {
    const fundingAddress = fundingAddressByTempChanId[selectedChannel.id];
    if (!fundingAddress) return null;
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

const CreateFundingHotWallet = (
  { selectedChannel }: { selectedChannel: Channel }
) => {
  const { tauAddressByTempChanId } = useContext(HotWalletContext);
  const tauAddress = tauAddressByTempChanId[selectedChannel.id];
  const { hotWalletFee } = useContext(HotWalletContext);
  let totalAmount = hotWalletFee ? selectedChannel.our.add(hotWalletFee as BitcoinAmount) : null;
  if (selectedChannel.network === Network.Regtest && !hotWalletFee) {
    const DEFAULT_REGTEST_FEE = BitcoinAmount.fromBtc(0.0001);
    totalAmount = selectedChannel.our.add(DEFAULT_REGTEST_FEE);
  }
  return (
    <>
    {(totalAmount && tauAddress) ? (
    <>
      <Text className='text-lg text-start mt-4' text={`Send: ${totalAmount?.asBtc()} BTC`} />
      <Text className='text-lg text-start' text={`To: ${tauAddress.slice(0, 8)}...${tauAddress.slice(-8)}`} />
      <CopyButton label={null} buttonText={'Copy Address'} copyText={tauAddress} />
    </>
    ): <Text className='text-lg text-start mt-4' text={'Fee estimate unavailable'} />}
    </>
  )
}



export default CreateFunding;
