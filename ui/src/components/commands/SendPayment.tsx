import React, { useState } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'

const SendPayment = ({ api }: { api: Urbit }) => {
  const [payreq, setPayreq] = useState('');
  const [shipInput, setShipInput] = useState('~');
  const [ship, setShip] = useState<string | null>(null);

  const handlePayreqChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPayreq(e.target.value);
  };

  const handleChangeShipInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    setShipInput(e.target.value);
    if (isValidPatp(preSig(e.target.value))) {
      setShip(preSig(e.target.value));
    } else {
      setShip(null);
    }
  };

  const sendPayment =  async (e: React.FormEvent) => {
    e.preventDefault();
    if (!payreq) return;
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          "send-payment": {
            payreq: payreq,
            who: ship
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
    <div className="flex flex-col items-center">
      <input
        type="text"
        value={payreq}
        onChange={handlePayreqChange}
        placeholder="Enter payreq"
        className="border border-gray-300 rounded-md px-4 py-2 mb-4"
      />
      <input
        type="text"
        value={shipInput}
        onChange={handleChangeShipInput}
        placeholder="Enter ship"
        className="border border-gray-300 rounded-md px-4 py-2 mb-4"
      />
      <button
        onClick={sendPayment}
        className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
      >
        Send Payment
      </button>
    </div>
  );
};

export default SendPayment;
