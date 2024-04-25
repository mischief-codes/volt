import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Input from './shared/Input';
import CommandForm from './shared/CommandForm';
import BitcoinAmount from '../../types/BitcoinAmount';
import Dropdown from './shared/Dropdown';
import Network from '../../types/Network';

const InvoiceAndPay = ({ api }: { api: Urbit }) => {
  const { displayJsError, displayJsSuccess } = useContext(FeedbackContext);

  const [shipInput, setShipInput] = useState('~');
  const [ship, setShip] = useState<string | null>(null);
  const [amountSatsInput, setAmountSatsInput] = useState<string>('');
  const [amount, setAmount] = useState<BitcoinAmount | null>(null);
  const [network, setNetwork] = useState(Network.Regtest);

  const handleChangeAmountSatsInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const input = e.target.value;
    // Allow only positive integers
    const isEmptyString = input === '';
    const isPositiveInteger = /^\d*$/.test(input) && parseInt(input) > 0;
    if (isEmptyString) {
      setAmountSatsInput(input);
      setAmount(null);
    } else if (isPositiveInteger) {
      setAmountSatsInput(input);
      setAmount(BitcoinAmount.fromSatoshis(parseInt(input)));
    }
  };

  const onChangeShipInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    setShipInput(e.target.value);
    if (isValidPatp(preSig(e.target.value))) {
      setShip(preSig(e.target.value));
    } else {
      setShip(null);
    }
  };

  const validateInvoiceAndPayParams = () => {
    let valid = true;
    if (!ship && (!shipInput || shipInput === '~')) {
      displayJsError('Ship required');
      valid = false;
    } else if (!ship) {
      displayJsError('Invalid ship');
      valid = false;
    } else if (ship === api.ship || ship === `~${api.ship}`) {
      displayJsError("Cannot invoice and pay self")
      valid = false;
    }
    if (!amount) {
      displayJsError('Amount required');
      valid = false;
    }
    return valid;
  }

  const handleChangeNetwork = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setNetwork(e.target.value as Network);
  };

  const invoiceAndPay = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateInvoiceAndPayParams()) return;
    try {
      await api.thread({
        inputMark: 'volt-invoice-and-pay-params',
        outputMark: 'volt-update',
        threadName: 'api-invoice-and-pay',
        desk: 'volt',
        body:
          {
            amount: amount?.asSats(),
            net: network,
            who: ship
          }
        }
      )
      displayJsSuccess('Thread !api-invoice-and-pay succeeded');
    } catch (e) {
      displayJsError('Error running thread !api-invoice-and-pay');
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
        label={"Ship"}
        value={shipInput}
        onChange={onChangeShipInput}
      />
      <Dropdown
        label={'Network'}
        options={options}
        value={network}
        onChange={handleChangeNetwork}
      />
      <Input
        label={'Amount (satoshis)'}
        value={amountSatsInput}
        onChange={handleChangeAmountSatsInput}
      />
      <Button onClick={invoiceAndPay} label={'Invoice and Pay'}/>
    </CommandForm>
  );
};

export default InvoiceAndPay;
