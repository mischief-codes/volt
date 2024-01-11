import React, { useState, useEffect, useContext, createContext } from 'react';
import { ApiContext } from './ApiContext';
import { FeedbackContext } from './FeedbackContext';
import Invoice from '../types/Invoice';
import BitcoinAmount from '../types/BitcoinAmount';

interface InvoiceContextValue {
  latestInvoice: Invoice | null;
}

export const InvoiceContext = createContext<InvoiceContextValue>({
  latestInvoice: null,
});

export const InvoiceContextProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const api = useContext(ApiContext);
  const { displayJsError, displayJsInfo } = useContext(FeedbackContext);

  const [latestInvoice, setLatestInvoice] = useState<Invoice | null>(null);

  useEffect(() => {
    const handleLatestInvoice = (invoiceRaw: any) => {
      displayJsInfo("Got update from /latest-invoice");
      const payreq = invoiceRaw['payment-request'].payreq;
      setLatestInvoice(
        { payreq,
          amount: new BitcoinAmount(invoiceRaw['payment-request']['amount-msats'])
        }
      )
    }

    const subscribe = () => {
      try {
        api.subscribe({
          app: "volt",
          path: "/latest-invoice",
          event: (e) => {
            handleLatestInvoice(e);
          },
          err: () => displayJsError("Subscription to /latest-invoice rejected"),
          quit: () => displayJsError("Kicked from subscription to /latest-invoice"),
        });
      } catch (e) {
        displayJsError("Error subscribing to /latest-invoice"),
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
