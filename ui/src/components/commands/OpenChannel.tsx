import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from '../shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';

const OpenChannel = ({ api }: { api: Urbit }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);

  const [channelPartnerInput, setChannelPartnerInput] = useState('~');
  const [channelPartner, setChannelPartner] = useState<string | null>(null);
  const [fundingSatsInput, setFundingSatsInput] = useState<string>('');
  const [fundingSats, setFundingSats] = useState<number | null>(null);
  const [pushMsatsInput, setPushMsatsInput] = useState('0');
  const [pushMsats, setPushMsats] = useState<number>(0);
  const [selectedOption, setSelectedOption] = useState('regtest');

  const handleChangeChannelPartnerInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    setChannelPartnerInput(e.target.value);
    if (isValidPatp(preSig(e.target.value))) {
      setChannelPartner(preSig(e.target.value));
    } else {
      setChannelPartner(null);
    }
  };

  const handleChangeFundingSatsInput = (e: React.ChangeEvent<HTMLInputElement>) => {
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

  const handleChangePushMsatsInput = (e: React.ChangeEvent<HTMLInputElement>) => {
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

  const handleChangeOption = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedOption(e.target.value);
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

  return (
    <form onSubmit={openChannel} className="max-w-sm mx-auto">
      <label className="block mb-2">
        Channel Partner
        <input
          type="text"
          value={channelPartnerInput}
          onChange={handleChangeChannelPartnerInput}
          className="border border-gray-300 rounded-md px-2 py-1 w-full"
        />
      </label>
      <br />
      <label className="block mb-2">
        Funding Sats
        <input
          type="text"
          value={fundingSatsInput}
          onChange={handleChangeFundingSatsInput}
          className="border border-gray-300 rounded-md px-2 py-1 w-full"
        />
      </label>
      <br />
      <br />
      <label className="block mb-2">
        Push mSats
        <input
          type="text"
          value={pushMsatsInput}
          onChange={handleChangePushMsatsInput}
          className="border border-gray-300 rounded-md px-2 py-1 w-full"
        />
      </label>
      <br />
      <label className="block mb-2">
        Network
        <select
          value={selectedOption}
          onChange={handleChangeOption}
          className="border border-gray-300 rounded-md px-2 py-1 w-full"
        >
          <option value="regtest">Regtest</option>
          <option value="testnet">Testnet</option>
          <option value="main">Mainnet</option>
        </select>
      </label>
      <br />
      <Button onClick={openChannel} label={'Open Channel'}/>
    </form>
  );
};

export default OpenChannel;
