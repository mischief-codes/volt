import React, { useState } from 'react';
import Urbit from '@urbit/http-api';

const CloseChannel = ({ api }: { api: Urbit }) => {
  const [channelId, setChannelId] = useState('');
  // const [selectedOption, setSelectedOption] = useState('');

  // const handleOptionChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
  //   setSelectedOption(event.target.value);
  // };

  const onChangeChannelId = (event: React.ChangeEvent<HTMLInputElement>) => {
    setChannelId(event.target.value);
  }

  const closeChannel  = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!channelId) return;
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {"close-channel": channelId },
        onSuccess: () => console.log('success'),
        onError: () => console.log('failure'),
      });
      console.log(res);
    } catch (e) {
      console.error(e);
    }
  }

  return (
    <div className="close-channel">
      <form onSubmit={closeChannel} className="flex flex-col items-center">
      <label className="block mb-2">
        Channel Id:
        <input
          type="text"
          value={channelId}
          onChange={onChangeChannelId}
          className="border border-gray-300 rounded-md px-2 py-1 w-full"
        />
      </label>
        {/* <select id="channel" value={selectedOption} onChange={handleOptionChange} className="channel-select p-2 border border-gray-300 rounded-md mb-2">
          <option value="channel1">Channel 1</option>
          <option value="channel2">Channel 2</option>
          <option value="channel3">Channel 3</option>
        </select> */}
        <button type="submit" className="close-button bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
          Close Channel
        </button>
      </form>
    </div>
  );
};

export default CloseChannel;
