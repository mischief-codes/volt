import React, { useState, useEffect, useRef, useContext } from 'react';
import Urbit from '@urbit/http-api';
import Button from './shared/Button';
import Text from './shared/Text';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from './shared/Input';
import Dropdown from './shared/Dropdown';
import Network from '../../types/Network';
import QRCode from 'react-qr-code'
import { InvoiceContext } from '../../contexts/InvoiceContext';
import CommandForm from './shared/CommandForm';
import Invoice from '../../types/Invoice';

const AddInvoice = ({ api }: { api: Urbit }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);
  const { latestInvoice } = useContext(InvoiceContext);

  const [amountMsatsInput, setAmountMsatsInput] = useState<string>('');
  const [amountMsats, setAmountMsats] = useState<number | null>(null);
  const [memo, setMemo] = useState('');
  const [network, setNetwork] = useState(Network.Regtest);
  // Recorded when user presses the submit button
  // Used to check if `latestInvoice` comming from our ship is probably the one we just submitted
  const [submittedInvoiceMsats, setSubmittedInvoiceMsats] = useState<number | null>(null);
  // New invoice received from ship
  const [confirmedInvoice, setConfirmedInvoice] = useState<Invoice | null>(null);


  console.log('latestInvoice', latestInvoice);
  console.log('confirmedInvoice', confirmedInvoice);
  console.log('submittedInvoiceMsats', submittedInvoiceMsats);

  useEffect(() => {
    if (
      // Check that we submitted an invoice through the UI and not the dojo
      submittedInvoiceMsats &&
      // Don't let `confirmedInvoice` get overwritten
      !confirmedInvoice &&
      // Check that `latestInvoice` comming from our ship looks like the one we just submitted
      latestInvoice && latestInvoice.amountMsats === submittedInvoiceMsats
    ) {
      setConfirmedInvoice(latestInvoice)
    }
  }, [latestInvoice])

  const handleChangeAmountMsatsInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const input = e.target.value;
    // Use a regular expression to allow only positive integers
    const isEmptyString = input === '';
    const isPositiveInteger = /^\d*$/.test(input) && parseInt(input) > 0;
    if (isEmptyString) {
      setAmountMsatsInput(input);
      setAmountMsats(null);
    } else if (isPositiveInteger) {
      setAmountMsatsInput(input);
      setAmountMsats(parseInt(input));
    }
  };

  const handleChangeMemo = (e: React.ChangeEvent<HTMLInputElement>) => {
    setMemo(e.target.value);
  }

  const handleChangeNetwork = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setNetwork(e.target.value as Network);
  };

  const addInvoice = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          'add-invoice': {
            'amount': amountMsats,
            memo: memo,
            network: network
          }
        },
        onSuccess: () => {
          displaySuccess(Command.AddInvoice)
          setSubmittedInvoiceMsats(amountMsats)
        },
        onError: (e) => displayError(e),
      });
      console.log(res);
    } catch (e) {
      console.error(e);
    }
  };

  const options = [
    { value: Network.Regtest, label: 'Regtest' },
    { value: Network.Testnet, label: 'Testnet' },
    { value: Network.Mainnet, label: 'Mainnet' }
  ];


  // Show QR display component even without a confirmed invoice to prevent user from submitting multiple invoices
  if (submittedInvoiceMsats) {
    return (
      <CommandForm>
        {latestInvoice?.payreq ? <QRCode className='col-span-2 mb-2 col-start-2 mx-auto' size={150} value={latestInvoice?.payreq} /> : null}
        <Text text={`Amount: ${submittedInvoiceMsats} msats`}/>
        <Text text={`Network: ${network}`}/>
        {memo ? <Text className='col-start-2 text-center' text={`Memo: ${memo}`} /> : null}
        <Button onClick={() => console.log('click')} label={'Done'}/>
     </CommandForm>
    );
  } else {
    return (
    <CommandForm>
      <Input
        label={'Amount (msats)'}
        value={amountMsatsInput}
        onChange={handleChangeAmountMsatsInput}
      />
      <Dropdown
        label={'Network'}
        options={options}
        value={network}
        onChange={handleChangeNetwork}
      />
      <Input
        label={'Memo (optional)'}
        value={memo}
        onChange={handleChangeMemo}
      />
      <Button onClick={addInvoice} label={'Add Invoice'}/>
    </CommandForm>
    );
  }
};

export default AddInvoice;
