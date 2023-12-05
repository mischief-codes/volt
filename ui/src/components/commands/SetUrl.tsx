import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import Button from '../shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';

const SetUrl = ({ api }: { api: Urbit }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);

  const [urlInput, setUrlInput] = useState('');
  const [url, setUrl] = useState<string | null>(null);

  const isValidUrl = (maybeUrl: string) => {
    try {
      new URL(maybeUrl);
      return true;
    } catch (e) {
      return false;
    }
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setUrlInput(e.target.value);
    if (isValidUrl(e.target.value)) {
      setUrl(e.target.value);
    } else {
      setUrl(null);
    }
  };

  const setProviderUrl = async () => {
    if (!url) return;
    try {
      const res = await api.poke({
        app: "volt-provider",
        mark: "volt-provider-command",
        json: {"set-url": url},
        onSuccess: () => displaySuccess(Command.SetUrl),
        onError: (e) => displayError(Command.SetUrl, e),
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
        value={urlInput}
        onChange={handleInputChange}
        className="border border-gray-300 rounded-md px-4 py-2 mr-2 focus:outline-none focus:ring-2 focus:ring-orange-300"
      />
      <Button onClick={setProviderUrl} label={'Set URL'}/>
    </div>
  );
};

export default SetUrl;
