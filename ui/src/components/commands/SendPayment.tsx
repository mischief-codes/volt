import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from '../shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';

const SendPayment = ({ api }: { api: Urbit }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);

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
        onSuccess: () => displaySuccess(Command.SendPayment),
        onError: (e) => displayError(Command.SendPayment, e),
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
      <Button onClick={sendPayment} label={'Send Payment'}/>
    </div>
  );
};

export default SendPayment;
