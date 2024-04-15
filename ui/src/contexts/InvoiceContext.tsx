import React, { useState, useEffect, useContext, createContext, useRef } from 'react';
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
  const { displayJsSuccess, displayJsError, displayJsInfo } = useContext(FeedbackContext);
  const [latestInvoice, setLatestInvoice] = useState<Invoice | null>(null);

  // currently subscribed or attempting to subscribe
  const activeSubscription = useRef(false);
  // subscribed and have received an update
  const subscriptionSuccessful = useRef(false);

  useEffect(() => {
    const handleLatestInvoice = (invoiceRaw: any) => {
      if (!subscriptionSuccessful.current) {
        subscriptionSuccessful.current = true;
        displayJsSuccess("Subscription to /latest-invoice succeeded");
      }
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
        if (activeSubscription.current) return;
        api.subscribe({
          app: "volt",
          path: "/latest-invoice",
          event: (e) => {
            handleLatestInvoice(e);
          },
          err: () => {
            displayJsError("Subscription to /latest-invoice rejected");
            activeSubscription.current = false;
            subscriptionSuccessful.current = false;
          },
          quit: () => {
            displayJsError("Kicked from subscription to /latest-invoice");
            activeSubscription.current = false;
            subscriptionSuccessful.current = false;
          },
        });
        activeSubscription.current = true;
      } catch (e) {
        console.error(e)
        displayJsError("Error subscribing to /latest-invoice");
        activeSubscription.current = false;
        subscriptionSuccessful.current = false;
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
