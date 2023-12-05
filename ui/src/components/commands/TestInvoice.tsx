import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from '../shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';

const TestInvoice = ({ api }: { api: Urbit }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);

  const [amountMsatsInput, setAmountMsatsInput] = useState<string>('');
  const [amountMsats, setAmountMsats] = useState<number | null>(null);
  const [shipInput, setShipInput] = useState('~');
  const [ship, setShip] = useState<string | null>(null);
  const [network, setNetwork] = useState('regtest');

  const handleShipInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setShipInput(e.target.value);
    if (isValidPatp(preSig(e.target.value))) {
      setShip(preSig(e.target.value));
    } else {
      setShip(null);
    }
  };

  const handleChangeAmountMsatsInput = (e: React.ChangeEvent<HTMLInputElement>) => {
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

  const handleChangeNetwork = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setNetwork(e.target.value);
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

  return (
    <form onSubmit={sendTestInvoice} className="max-w-sm mx-auto">
      <div className="mb-4">
        <label htmlFor="input1" className="block mb-2">Amount (msats)</label>
        <input
          type="text"
          id="input1"
          value={amountMsatsInput}
          onChange={handleChangeAmountMsatsInput}
          className="border border-gray-300 px-4 py-2 rounded-md w-full"
        />
      </div>
      <div className="mb-4">
        <label htmlFor="input2" className="block mb-2">Ship</label>
        <input
          type="text"
          id="input2"
          value={shipInput}
          onChange={handleShipInputChange}
          className="border border-gray-300 px-4 py-2 rounded-md w-full"
        />
      </div>
      <div className="mb-4">
        <label htmlFor="dropdown" className="block mb-2">Network:</label>
        <select
          id="dropdown"
          value={network}
          onChange={handleChangeNetwork}
          className="border border-gray-300 px-4 py-2 rounded-md w-full"
        >
          <option value="regtest">Regtest</option>
          <option value="testnet">Testnet</option>
          <option value="main">Mainnet</option>
        </select>
      </div>
      <Button className='border-red' onClick={sendTestInvoice} label={'Send Test Invoice'}/>
      </form>
  );
};

export default TestInvoice;
