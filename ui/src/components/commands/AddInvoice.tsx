import React, { useState } from 'react';
import Urbit from '@urbit/http-api';

const AddInvoice = ({ api }: { api: Urbit }) => {
  const [amountMsatsInput, setAmountMsatsInput] = useState<string>('');
  const [amountMsats, setAmountMsats] = useState<number | null>(null);
  const [memo, setMemo] = useState('');
  const [network, setNetwork] = useState('regtest');

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

  const handleChangeMemo = (e: React.ChangeEvent<HTMLInputElement>) => {
    setMemo(e.target.value);
  }

  const handleChangeNetwork = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setNetwork(e.target.value);
  };

  const addInvoice = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          'add-invoice': {
            'amount': amountMsats,
            memo: memo,
            network: network
          }
        },
        onSuccess: () => console.log('success'),
        onError: () => console.log('failure'),
      });
      console.log(res);
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <form onSubmit={addInvoice} className="p-4 bg-gray-100">
      <label className="block mb-2">
        Amount (msats)
        <input
          type="text"
          value={amountMsatsInput}
          onChange={handleChangeAmountMsatsInput}
          className="border border-gray-300 rounded-md px-2 py-1"
        />
      </label>
      <br />
      <label className="block mb-2">
        Memo (optional)
        <input
          type="text"
          value={memo}
          onChange={handleChangeMemo}
          className="border border-gray-300 rounded-md px-2 py-1"
        />
      </label>
      <br />
      <label className="block mb-2">
        Network
        <select
          value={network}
          onChange={handleChangeNetwork}
          className="border border-gray-300 rounded-md px-2 py-1"
        >
          <option value="regtest">Regtest</option>
          <option value="testnet">Testnet</option>
          <option value="main">Mainnet</option>
        </select>
      </label>
      <br />
      <button type="submit" className="bg-blue-500 text-white px-4 py-2 rounded-md">
        Submit
      </button>
    </form>
  );
};

export default AddInvoice;
