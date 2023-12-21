import React, { useState, useEffect, useRef, useContext } from 'react';
import Urbit from '@urbit/http-api';
import Button from '../basic/Button';
import { FeedbackContext } from '../../contexts/FeedbackContext';
import Command from '../../types/Command';
import Input from '../basic/Input';
import Dropdown from '../basic/Dropdown';
import Network from '../../types/Network';
import QRCode from 'react-qr-code'
import { InvoiceContext } from '../../contexts/InvoiceContext';
import CommandForm from './CommandForm';

const InvoiceDisplay = ({invoice, amountMsats, memo, network }
  : {invoice: string, amountMsats: number, memo: string, network: Network}) => {
    return (
      <div className="flex flex-col items-center justify-center h-full w-full">
        <div className="flex flex-col items-center justify-center h-1/3 w-full">
          <div className="text-2xl font-bold text-slate-800">Invoice created!</div>
          <div className="text-xl text-slate-800">Amount: {amountMsats} msats</div>
          <div className="text-xl text-slate-800">Memo: {memo}</div>
          <div className="text-xl text-slate-800">Network: {network}</div>
        </div>
        <div className="flex flex-col items-center justify-center h-1/3 w-full">
          <div className="text-xl font-bold text-slate-800">Invoice:</div>
          <div className="text-xl text-slate-800">{invoice}</div>
        </div>
        {
          invoice ? <QRCode value={invoice} /> : null
        }
      </div>
    );
}

const AddInvoice = ({ api }: { api: Urbit }) => {
  const { displaySuccess, displayError } = useContext(FeedbackContext);
  const { latestInvoice } = useContext(InvoiceContext);

  const [amountMsatsInput, setAmountMsatsInput] = useState<string>('');
  const [amountMsats, setAmountMsats] = useState<number | null>(null);
  const [memo, setMemo] = useState('');
  const [network, setNetwork] = useState(Network.Regtest);
  // User presseed submit button
  const [invoiceSubmitted, setInvoiceSubmitted] = useState<boolean>(false);
  // New invoice received from ship
  const [invoiceAdded, setInvoiceAdded] = useState<boolean>(false);


  useEffect(() => {
    if (invoiceSubmitted && latestInvoice) {
      setInvoiceAdded(true)
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
          setInvoiceSubmitted(true)
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
        className='col-span-4 w-11/12'
        label={'Memo (optional)'}
        value={memo}
        onChange={handleChangeMemo}
      />
      <Button onClick={addInvoice} label={'Add Invoice'}/>
      {/* {
        invoiceAdded ?
        <InvoiceDisplay
          invoice={latestInvoice as string}
          amountMsats={amountMsats as number}
          memo={memo}
          network={network}
        />
        : null
      } */}
    </CommandForm>
  );
};

export default AddInvoice;
