import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from './shared/Input';
import Dropdown from './shared/Dropdown';
import Network from '../../types/Network';
import CommandForm from './shared/CommandForm';
import BitcoinAmount, { MIN_FUNDING_AMOUNT } from '../../types/BitcoinAmount';

const OpenChannel = ({ api }: { api: Urbit }) => {
  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);

  const [channelPartnerInput, setChannelPartnerInput] = useState('~');
  const [channelPartner, setChannelPartner] = useState<string | null>(null);
  const [fundingSatsInput, setFundingSatsInput] = useState<string>('');
  const [fundingSats, setFundingSats] = useState<number | null>(null);
  const [pushMsatsInput, setPushMsatsInput] = useState('0');
  const [pushAmount, setPushAmount] = useState(new BitcoinAmount(0));
  const [selectedOption, setSelectedOption] = useState(Network.Regtest);

  const onChangeChannelPartnerInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    setChannelPartnerInput(e.target.value);
    if (isValidPatp(preSig(e.target.value))) {
      setChannelPartner(preSig(e.target.value));
    } else {
      setChannelPartner(null);
    }
  };

  const onChangeFundingSatsInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const input = e.target.value;
    // Only allow only positive integers
    const isEmptyString = input === '';
    const isPositiveInteger = /^\d*$/.test(input) && parseInt(input) > 0;
    if (isEmptyString) {
      setFundingSatsInput(input);
      setFundingSats(null);
    } else if (isPositiveInteger) {
      setFundingSatsInput(input);
      setFundingSats(parseInt(input));
    }
  };

  const onChangePushMsatsInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const input = e.target.value;
    // Only allow only positive integers
    const isEmptyString = input === '';
    const isPositiveInteger = /^\d*$/.test(input) && parseInt(input) >= 0;
    if (isEmptyString) {
      setPushMsatsInput('');
      setPushAmount(new BitcoinAmount(0));
    } else if (isPositiveInteger) {
      setPushMsatsInput(input);
      setPushAmount(new BitcoinAmount(parseInt(input)));
    }
  };

  const onChangeNetwork = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedOption(e.target.value as Network);
  };

  const validateOpenChannelParams = () => {
    let valid = true;

    if (channelPartner === null && ['', '~'].includes(channelPartnerInput)) {
      displayJsError("Channel partner required")
      valid = false;
    } else if (channelPartner === null) {
      displayJsError("Invalid channel partner")
      valid = false;
    } else if (channelPartner === api.ship || channelPartner === `~${api.ship}`) {
      displayJsError("Cannot open channel with self")
      valid = false;
    }

    if (fundingSats === null) {
      displayJsError("Funding sats required")
      valid = false;
    } else if (MIN_FUNDING_AMOUNT.gt(BitcoinAmount.fromSatoshis(fundingSats))) {
      displayJsError(`Funding sats must be at least ${MIN_FUNDING_AMOUNT.displayAsSats()}`)
      valid = false;
    }

    if (fundingSats && pushAmount.gt(BitcoinAmount.fromSatoshis(fundingSats))) {
      displayJsError(`Push msats must be less than or equal to funding`)
      valid = false;
    }
    return valid;
  }

  const openChannel = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateOpenChannelParams()) return;
    try {
      api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          "open-channel": {
            who: channelPartner,
            'funding-sats': fundingSats,
            'push-msats': pushAmount.millisatoshis,
            network: selectedOption
          }
        },
        onSuccess: () => displayCommandSuccess(Command.OpenChannel),
        onError: (e) => displayCommandError(Command.OpenChannel, e),
      });
    } catch (e) {
      displayJsError('Error opening channel');
      console.error(e);
    }
  };

  const options = [
    { value: Network.Regtest, label: 'Regtest' },
    { value: Network.Testnet, label: 'Testnet' },
    { value: Network.Mainnet, label: 'Mainnet' }
  ];

  return (
    <CommandForm>
      <Input
        label={"Channel Partner"}
        value={channelPartnerInput}
        onChange={onChangeChannelPartnerInput}
      />
      <Input
        label={"Funding Sats"}
        value={fundingSatsInput}
        onChange={onChangeFundingSatsInput}
      />
      <Input
        label={"Push msats"}
        value={pushMsatsInput}
        onChange={onChangePushMsatsInput}
      />
      <Dropdown
        label={"Network"}
        options={options}
        value={selectedOption}
        onChange={onChangeNetwork}
      />
      <Button onClick={openChannel} label={'Open Channel'}/>
    </CommandForm>
  );
};

export default OpenChannel;
