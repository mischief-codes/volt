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

const TestInvoice = ({ api }: { api: Urbit }) => {
  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);

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

  const validateTestInvoiceParams = () => {
    let valid = true;
    if (!ship && ['~', ''].includes(shipInput)) {
      displayJsError('Ship required');
      valid = false;
    } else if (!ship) {
      displayJsError('Invalid ship');
      valid = false;
    } else if (ship === api.ship) {
      displayJsError('Cannot send invoice to self');
      valid = false;
    }
    if (!amountMsats) {
      displayJsError('Amount required');
      valid = false;
    }
    return valid;
  }

  const sendTestInvoice = (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateTestInvoiceParams()) return;
    try {
      api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          'test-invoice': {
            ship: ship,
            msats: amountMsats,
            network: network
          }
        },
        onSuccess: () => displayCommandSuccess(Command.TestInvoice),
        onError: (e) => displayCommandError(Command.TestInvoice, e),
      });
    } catch (e) {
      displayJsError('Error sending test invoice')
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
