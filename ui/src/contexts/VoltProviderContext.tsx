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
  const isSubscribed = useRef(false);
  const [providerIsConnected, setProviderIsConnected] = useState<boolean | null>(null);

  useEffect(() => {
    if (providerIsConnected === true) {
      displayJsSuccess("Connected to provider");
    } else if (providerIsConnected === false) {
      displayJsError("Provider disconnected");
    }
  }, [providerIsConnected]);

  useEffect(() => {
    const handleProviderStatusUpdate = (e: any) => {
      if (e?.connected === true && !providerIsConnected) {
        setProviderIsConnected(true);
      } else if (e?.connected === false) {
        setProviderIsConnected(false);
      }
    }

    const subscribeProvider = () => {
      try {
        if (isSubscribed.current) return;
        api.subscribe({
          app: "volt-provider",
          path: "/status",
          event: handleProviderStatusUpdate,
          err: () => {
            displayJsError("Subscription to /status rejected");
            isSubscribed.current = false;
          },
          quit: () => {
            displayJsError("Kicked from subscription to /status");
            isSubscribed.current = false;
          }
        });
        displayJsSuccess("Subscription to /status succeeded");
        isSubscribed.current = true;
      } catch (e) {
        displayJsError("Error subscribing to /status"),
        console.error(e)
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
