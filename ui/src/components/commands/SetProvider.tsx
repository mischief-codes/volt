import React, { useState } from 'react';
import Urbit from '@urbit/http-api';

const SetProvider = ({ api }: { api: Urbit }) => {
  const [provider, setProvider] = useState('');

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setProvider(event.target.value);
  };

  const handleButtonClick = () => {
    // Do something with the provider value
    console.log(provider);
  };

  return (
    <div className="flex items-center">
      <input
        type="text"
        value={provider}
        onChange={handleInputChange}
        className="border border-gray-300 rounded-md px-4 py-2 mr-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      <button
        onClick={handleButtonClick}
        className="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-4 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        Set Provider
      </button>
    </div>
  );
};

export default SetProvider;
