import React, { createContext, useContext, useEffect, useRef } from 'react';
import { ApiContext } from './ApiContext';
import { FeedbackContext } from './FeedbackContext';
import { Update, UpdateType } from '../types/Update';
import { ChannelContext } from './ChannelContext';


export const PaymentUpdateContext = createContext<null>(null);

export const PaymentUpdateContextProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const api = useContext(ApiContext);
  const { refreshChannelState } = useContext(ChannelContext);
  const { displayJsError, displayJsSuccess, displayJsInfo } = useContext(FeedbackContext);

  const activeSubscription = useRef(false);
  const subscriptionSuccessful = useRef(false);

  useEffect(() => {
    const handlePaymentUpdate = (update: Update) => {
      if (!subscriptionSuccessful.current) {
        subscriptionSuccessful.current = true;
        displayJsSuccess('Subscription to /payment-updates succeeded');
      }
      if (update.type === UpdateType.PaymentUpdate) {
        displayJsInfo('Got update from /payment-updates');
        refreshChannelState();
      }
    }

    const subscribe = () => {
      try {
        api.subscribe({
          app: "volt",
          path: "/payment-updates",
          event: (e) => {
            handlePaymentUpdate(e);
          },
          err: () => {
            displayJsError("Subscription to /payment-updates rejected")
            activeSubscription.current = false;
            subscriptionSuccessful.current = false;
          },
          quit: () => {
            displayJsError("Kicked from subscription to /payment-updates")
            activeSubscription.current = false;
            subscriptionSuccessful.current = false;
          },
        });
        activeSubscription.current = true;
      } catch (e) {
        console.error(e)
        displayJsError("Error subscribing to /payment-updates");
        activeSubscription.current = false;
        subscriptionSuccessful.current = false;
      }
    }
    subscribe()
  }, [])

  return (
    <PaymentUpdateContext.Provider value={null}>
      {children}
    </PaymentUpdateContext.Provider>
  );
};
