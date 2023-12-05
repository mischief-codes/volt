import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'
import Button from '../shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';

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
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {"set-provider": providerShip},
        onSuccess: () => displaySuccess(Command.SetProvider),
        onError: (e) => displayError(Command.SetProvider, e),
      });
      console.log(res);
    } catch (e) {
      console.error(e);
    }
  }

  return (
    <div className="flex items-center">
      <input
        type="text"
        value={providerShipInput}
        onChange={handleInputChange}
        className="border border-gray-300 rounded-md px-4 py-2 mr-2 focus:outline-none focus:ring-2 focus:ring-orange-300"
      />
      <Button onClick={setProvider} label={'Set Provider'}/>
    </div>
  );
};

export default SetProvider;
