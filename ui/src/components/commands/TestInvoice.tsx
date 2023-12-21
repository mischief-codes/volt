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

const TestInvoice = ({ api }: { api: Urbit }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);

  const [amountMsatsInput, setAmountMsatsInput] = useState<string>('');
  const [amountMsats, setAmountMsats] = useState<number | null>(null);
  const [shipInput, setShipInput] = useState('~');
  const [ship, setShip] = useState<string | null>(null);
  const [network, setNetwork] = useState(Network.Regtest);

  const onChangeShipInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    setShipInput(e.target.value);
    if (isValidPatp(preSig(e.target.value))) {
      setShip(preSig(e.target.value));
    } else {
      setShip(null);
    }
  };

  const onChangePushMsatsInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const input = e.target.value;
    // Use a regular expression to allow only positive integers
    const isEmptyString = input === '';
    const isPositiveInteger = /^\d*$/.test(input) && parseInt(input) > 0;
    if (isEmptyString) {
      setAmountMsatsInput(input);
      setAmountMsats(null);
    } else if (isPositiveInteger) {
      setAmountMsatsInput(input);
      setAmountMsats(parseInt(input));
    }
  };

  const handleChangeNetwork = (e: React.ChangeEvent<HTMLElement>) => {
    const target = e.target as HTMLInputElement;
    setNetwork(target.value as Network);
  };


  const sendTestInvoice = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!ship || !amountMsats) return;
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          'test-invoice': {
            ship: ship,
            msats: amountMsats,
            network: network
          }
        },
        onSuccess: () => displaySuccess(Command.TestInvoice),
        onError: (e) => displayError(Command.TestInvoice, e),
      });
      console.log(res);
    } catch (e) {
      console.error(e);
    }
  };

  const networkOptions = [
    { value: Network.Regtest, label: 'Regtest' },
    { value: Network.Testnet, label: 'Testnet' },
    { value: Network.Mainnet, label: 'Mainnet' }
  ];

  return (
    <CommandForm>
      <Input
        className='col-start-2'
        label={'Amount (msats)'}
        value={amountMsatsInput}
        onChange={onChangePushMsatsInput}
      />
      <Input
          className='col-start-2'
          label={'Ship'}
          value={shipInput}
          onChange={onChangeShipInput}
      />
      <Dropdown
        className='col-start-2'
        label={'Network'}
        options={networkOptions}
        value={network}
        onChange={handleChangeNetwork}
      />
      <Button onClick={sendTestInvoice} label={'Send Test Invoice'}/>
    </CommandForm>
  );
};

export default TestInvoice;
