import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from '../basic/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from '../basic/Input';
import Dropdown from '../basic/Dropdown';
import Network from '../../types/Network';
import CommandForm from './CommandForm';

const OpenChannel = ({ api }: { api: Urbit }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);

  const [channelPartnerInput, setChannelPartnerInput] = useState('~');
  const [channelPartner, setChannelPartner] = useState<string | null>(null);
  const [fundingSatsInput, setFundingSatsInput] = useState<string>('');
  const [fundingSats, setFundingSats] = useState<number | null>(null);
  const [pushMsatsInput, setPushMsatsInput] = useState('0');
  const [pushMsats, setPushMsats] = useState<number>(0);
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
    // Use a regular expression to allow only positive integers
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
    // Use a regular expression to allow only positive integers
    const isEmptyString = input === '';
    const isPositiveInteger = /^\d*$/.test(input) && parseInt(input) >= 0;
    if (isEmptyString) {
      setPushMsatsInput('');
      setPushMsats(0);
    } else if (isPositiveInteger) {
      setPushMsatsInput(input);
      setPushMsats(parseInt(input));
    }
  };

  const onChangeNetwork = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedOption(e.target.value as Network);
  };


  const openChannel = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!channelPartner || !fundingSats) return;
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          "open-channel": {
            who: channelPartner,
            'funding-sats': fundingSats,
            'push-msats': pushMsats,
            network: selectedOption
          }
        },
        onSuccess: () => displaySuccess(Command.OpenChannel),
        onError: (e) => displayError(Command.OpenChannel, e),
      });
      console.log(res);
    } catch (e) {
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
