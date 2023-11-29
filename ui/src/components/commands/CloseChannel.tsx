import React, { useState } from 'react';
import Urbit from '@urbit/http-api';

const CloseChannel = ({ api }: { api: Urbit }) => {
  const [selectedOption, setSelectedOption] = useState('');

  const handleOptionChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedOption(event.target.value);
  };

  const setProvider = async () => {
      try {
        const res = await api.poke({
          app: "volt",
          mark: "volt-command",
          json: {"set-provider": "~zod"},
          onSuccess: () => console.log('success'),
          onError: () => console.log('failure'),
        });
        console.log(res);
      } catch (e) {
        console.error(e);
      }
    }

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    // Perform the desired action with the selected option
    console.log('Selected option:', selectedOption);
  };

  return (
    <div className="close-channel">
      <form onSubmit={handleSubmit} className="flex flex-col items-center">
        <select id="channel" value={selectedOption} onChange={handleOptionChange} className="channel-select p-2 border border-gray-300 rounded-md mb-2">
          <option value="channel1">Channel 1</option>
          <option value="channel2">Channel 2</option>
          <option value="channel3">Channel 3</option>
        </select>
        <button type="submit" className="close-button bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
          Close Channel
        </button>
      </form>
    </div>
  );
};

export default CloseChannel;
