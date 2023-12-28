import React, { useState, useContext } from 'react';
import Urbit from '@urbit/http-api';
import Button from './shared/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from './shared/Input';
import CommandForm from './shared/CommandForm';

const SetUrl = ({ api }: { api: Urbit }) => {
  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);

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

  const setProviderUrl = (e: React.FormEvent) => {
    e.preventDefault();
    if (!url) return;
    try {
      api.poke({
        app: "volt-provider",
        mark: "volt-provider-command",
        json: {"set-url": url},
        onSuccess: () => displayCommandSuccess(Command.SetUrl),
        onError: (e) => displayCommandError(Command.SetUrl, e),
      });
    } catch (e) {
      displayJsError("Error setting provider url")
    }
  }

  return (
    <CommandForm>
      <Input
        className='col-start-2'
        label={"Provider URL"}
        value={urlInput}
        onChange={handleInputChange}
      />
      <Button onClick={setProviderUrl} label={'Set URL'}/>
    </CommandForm>
  );
};

export default SetUrl;
