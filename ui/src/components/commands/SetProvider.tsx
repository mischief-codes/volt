import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from '../basic/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from '../basic/Input';
import CommandForm from './CommandForm';

const SetProvider = ({ api }: { api: Urbit }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);

  const [providerShipInput, setProviderShipInput] = useState('~');
  const [providerShip, setProviderShip] = useState<string | null>(null);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setProviderShipInput(e.target.value);
    if (isValidPatp(preSig(e.target.value))) {
      setProviderShip(preSig(e.target.value));
    } else {
      setProviderShip(null);
    }
  };

  const setProvider = async () => {
    if (!providerShip) return;
    try {
      api.poke({
        app: "volt",
        mark: "volt-command",
        json: {"set-provider": providerShip},
        onSuccess: () => displaySuccess(Command.SetProvider),
        onError: (e) => displayError(e),
      });
    } catch (e) {
      displayError("Error setting provider")
    }
  }

  return (
    <CommandForm>
      <Input
        className='col-start-2'
        label={"Provider Ship"}
        value={providerShipInput}
        onChange={handleInputChange}
      />
      <Button onClick={setProvider} label={'Set Provider'}/>
    </CommandForm>
  );
};

export default SetProvider;
