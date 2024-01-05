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
import BitcoinAmount from '../../types/BitcoinAmount';

const AddInvoice = ({ api }: { api: Urbit }) => {
  const { displayCommandSuccess, displayCommandError, displayJsError } = useContext(FeedbackContext);
  const { latestInvoice } = useContext(InvoiceContext);

  const [amountMsatsInput, setAmountMsatsInput] = useState<string>('');
  const [amount, setAmount] = useState<BitcoinAmount | null>(null);
  const [memo, setMemo] = useState('');
  const [network, setNetwork] = useState(Network.Regtest);
  // Recorded when user presses the submit button
  // Used to check if `latestInvoice` comming from our ship is probably the one we just submitted
  const [submittedInvoiceAmount, setSubmittedInvoiceAmount] = useState<BitcoinAmount | null>(null);
  // New invoice received from ship
  const [confirmedInvoice, setConfirmedInvoice] = useState<Invoice | null>(null);

  useEffect(() => {
    if (
      // Check that we submitted an invoice through the UI and not the dojo
      submittedInvoiceAmount &&
      // Don't let `confirmedInvoice` get overwritten
      !confirmedInvoice &&
      // Check that `latestInvoice` comming from our ship looks like the one we just submitted
      latestInvoice && latestInvoice.amount.eq(submittedInvoiceAmount)
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
      setAmount(null);
    } else if (isPositiveInteger) {
      setAmountMsatsInput(input);
      setAmount(new BitcoinAmount(parseInt(input)));
    }
  };

  const handleChangeMemo = (e: React.ChangeEvent<HTMLInputElement>) => {
    setMemo(e.target.value);
  }

  const handleChangeNetwork = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setNetwork(e.target.value as Network);
  };

  const addInvoice = (e: React.FormEvent) => {
    e.preventDefault();
    if (!amount) return;
    try {
      api.poke({
        app: "volt",
        mark: "volt-command",
        json: {
          'add-invoice': {
            'amount': (amount as BitcoinAmount).millisatoshis,
            memo: memo,
            network: network
          }
        },
        onSuccess: () => {
          displayCommandSuccess(Command.AddInvoice)
          setSubmittedInvoiceAmount(amount)
        },
        onError: (e) => displayCommandError(Command.AddInvoice, e),
      });
    } catch (e) {
      displayJsError('Error adding invoice')
    }
  };

  const onClickDone = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmittedInvoiceAmount(null);
  }

  const options = [
    { value: Network.Regtest, label: 'Regtest' },
    { value: Network.Testnet, label: 'Testnet' },
    { value: Network.Mainnet, label: 'Mainnet' }
  ];


  // Show QR display component even without a confirmed invoice to prevent user from submitting multiple invoices
  if (submittedInvoiceAmount) {
    return (
      <CommandForm>
        {latestInvoice?.payreq ? <QRCode className='col-span-2 mb-2 col-start-2 mx-auto' size={150} value={latestInvoice?.payreq} /> : null}
        <Text text={`Amount: ${submittedInvoiceAmount.displayAsMsats()}`}/>
        <Text text={`Network: ${network}`}/>
        {memo ? <Text className='col-start-2 text-center' text={`Memo: ${memo}`} /> : null}
        <Button onClick={onClickDone} label={'Done'}/>
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
