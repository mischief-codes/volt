import React, { useState, useEffect, useContext, createContext } from 'react';
import { ApiContext } from './ApiContext';
import { FeedbackContext } from './FeedbackContext';
import Invoice from '../types/Invoice';

interface InvoiceContextValue {
  latestInvoice: Invoice | null;
}

export const InvoiceContext = createContext<InvoiceContextValue>({
  latestInvoice: null,
});

export const InvoiceContextProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const api = useContext(ApiContext);
  const { displayError, displayInfo } = useContext(FeedbackContext);

  const [latestInvoice, setLatestInvoice] = useState<Invoice | null>(null);

  useEffect(() => {
    const handleLatestInvoice = (invoiceRaw: any) => {
      displayInfo("Got update from /latest-invoice");
      console.log('invoiceRaw', invoiceRaw);
      setLatestInvoice({ payreq: invoiceRaw.payreq, amountMsats: invoiceRaw['amount-msats'] })
    }

    const subscribe = () => {
      try {
        api.subscribe({
          app: "volt",
          path: "/latest-invoice",
          event: (e) => {
            console.log('e', e);
            handleLatestInvoice(e);
          },
          err: () => displayError("Subscription to /latest-invoice rejected"),
          quit: () => displayError("Kicked from subscription to /latest-invoice"),
        });
      } catch (e) {
        displayError("Error subscribing to /latest-invoice"),
        console.error(e)
      }
    };
    subscribe()
  }, [])

  const value = {
    latestInvoice
  };

  return (
    <InvoiceContext.Provider value={value}>
      {children}
    </InvoiceContext.Provider>
  );
};
