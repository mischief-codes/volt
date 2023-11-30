import React, { useState } from 'react';
import Urbit from '@urbit/http-api';

const CreateFunding = ({ api }: { api: Urbit }) => {
  const [tempChannelId, setTempChannelId] = useState('');
  const [psbt, setPsbt] = useState('');

  const handleChangeTempChannelId = (event: React.ChangeEvent<HTMLInputElement>) => {
    setTempChannelId(event.target.value);
  };

  const handleChangePsbt = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPsbt(event.target.value);
  };

  console.log(tempChannelId, psbt)

  const createFunding = async (e: React.FormEvent) => {
    e.preventDefault();
    console.log(tempChannelId, psbt)
    if (!tempChannelId || !psbt) return;
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          'create-funding': {
            'temporary-channel-id': tempChannelId,
            'psbt': psbt,
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
    <form onSubmit={createFunding} className="flex flex-col space-y-4">
      <label className="flex flex-col">
        <span className="text-lg font-medium">Temporary channel id:</span>
        <input
          type="text"
          value={tempChannelId}
          onChange={handleChangeTempChannelId}
          className="mt-1 p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </label>
      <label className="flex flex-col">
        <span className="text-lg font-medium">PSBT:</span>
        <input
          type="text"
          value={psbt}
          onChange={handleChangePsbt}
          className="mt-1 p-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </label>
      <button
        type="submit"
        className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        Submit
      </button>
    </form>
  );
};

export default CreateFunding;
