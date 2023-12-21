import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from '../basic/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from '../basic/Input';
import CommandForm from './CommandForm';

const SendPayment = ({ api }: { api: Urbit }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);

  const [payreq, setPayreq] = useState('');
  const [shipInput, setShipInput] = useState('~');
  const [ship, setShip] = useState<string | null>(null);

  const onChangePayreq = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPayreq(e.target.value);
  };

  const onChangeShipInput = (e: React.ChangeEvent<HTMLInputElement>) => {
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
    <CommandForm>
      <Input
        label={"Payreq"}
        value={payreq}
        onChange={onChangePayreq}
      />
      <Input
        label={"Ship"}
        value={shipInput}
        onChange={onChangeShipInput}
      />
      <Button onClick={sendPayment} label={'Send Payment'}/>
    </CommandForm>
  );
};

export default SendPayment;
