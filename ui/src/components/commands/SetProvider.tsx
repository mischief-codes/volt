import React, { useState } from 'react';
import Urbit from '@urbit/http-api';
import { isValidPatp, preSig } from '@urbit/aura'

const SetProvider = ({ api }: { api: Urbit }) => {
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
        onSuccess: () => console.log('success'),
        onError: () => console.log('failure'),
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
        className="border border-gray-300 rounded-md px-4 py-2 mr-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      <button
        onClick={setProvider}
        className="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-4 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        Set Provider
      </button>
    </div>
  );
};

export default SetProvider;
