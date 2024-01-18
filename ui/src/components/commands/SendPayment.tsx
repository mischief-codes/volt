import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from './shared/Input';
import CommandForm from './shared/CommandForm';

const SendPayment = ({ api }: { api: Urbit }) => {
  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);

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

  const sendPayment =  (e: React.FormEvent) => {
    e.preventDefault();
    if (!payreq) {
      displayJsError("Payreq required");
      return;
    }
    try {
      api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          "send-payment": {
            payreq: payreq,
            who: ship
          }
        },
        onSuccess: () => displayCommandSuccess(Command.SendPayment),
        onError: (e) => displayCommandError(Command.SendPayment, e),
      });
    } catch (e) {
      displayJsError('Error sending payment');
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
        label={"Ship (optional)"}
        value={shipInput}
        onChange={onChangeShipInput}
      />
      <Button onClick={sendPayment} label={'Send Payment'}/>
    </CommandForm>
  );
};

export default SendPayment;
