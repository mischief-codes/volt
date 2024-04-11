import React, { createContext, useState, useEffect, useContext, useRef } from 'react';
import { FeedbackContext } from './FeedbackContext';
import { ApiContext } from './ApiContext';


interface VoltProviderContextValue {
  providerIsConnected: boolean | null;
}

export const VoltProviderContext = createContext<VoltProviderContextValue | undefined>(undefined);

export const VoltProviderContextProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const api = useContext(ApiContext);
  const { displayJsSuccess, displayJsError } = useContext(FeedbackContext);
  const [providerIsConnected, setProviderIsConnected] = useState<boolean | null>(null);

  // currently subscribed or attempting to subscribe
  const activeSubscription = useRef(false);
  // subscribed and have received an update
  const subscriptionSuccessful = useRef(false);

  useEffect(() => {
    if (providerIsConnected === true) {
      displayJsSuccess("Connected to provider");
    } else if (providerIsConnected === false) {
      displayJsError("Provider disconnected");
    }
  }, [providerIsConnected]);

  useEffect(() => {
    const handleProviderStatusUpdate = (e: any) => {
      if (!subscriptionSuccessful.current) {
        subscriptionSuccessful.current = true;
        displayJsSuccess('Subscription to /all succeeded');
      }
      if (e?.connected === true && !providerIsConnected) {
        setProviderIsConnected(true);
      } else if (e?.connected === false) {
        setProviderIsConnected(false);
      }
    }

    const subscribeProvider = () => {
      try {
        if (activeSubscription.current) return;
        api.subscribe({
          app: "volt-provider",
          path: "/status",
          event: handleProviderStatusUpdate,
          err: () => {
            displayJsError("Subscription to /status rejected");
            activeSubscription.current = false;
            subscriptionSuccessful.current = false;

          },
          quit: () => {
            displayJsError("Kicked from subscription to /status");
            activeSubscription.current = false;
            subscriptionSuccessful.current = false;
          }
        });
        activeSubscription.current = true;
      } catch (e) {
        console.error(e)
        displayJsError("Error subscribing to /status"),
        activeSubscription.current = false;
        subscriptionSuccessful.current = false;
      }
    }
    subscribeProvider()
  }, [])

  const value = {
    providerIsConnected
  };

  return (
    <VoltProviderContext.Provider value={value}>
      {children}
    </VoltProviderContext.Provider>
  );
};
