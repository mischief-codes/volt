import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from './shared/Input';
import CommandForm from './shared/CommandForm';

const SetProvider = ({ api }: { api: Urbit }) => {
  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);

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

  const setProvider = (e: React.FormEvent) => {
    e.preventDefault();
    if (!providerShip) {
      displayJsError("Invalid provider ship")
      return;
    };
    try {
      api.poke({
        app: "volt",
        mark: "volt-command",
        json: {"set-provider": providerShip},
        onSuccess: () => displayCommandSuccess(Command.SetProvider),
        onError: (e) => displayCommandError(Command.SetProvider, e),
      });
    } catch (e) {
      displayJsError("Error setting provider");
      console.error(e);
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
