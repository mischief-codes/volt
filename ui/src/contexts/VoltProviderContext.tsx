import React, { createContext, useState, useEffect, useContext } from 'react';
import { FeedbackContext } from './FeedbackContext';
import { ApiContext } from './ApiContext';


interface VoltProviderContextValue {
  providerIsConnected: boolean;
}

export const VoltProviderContext = createContext<VoltProviderContextValue | undefined>(undefined);

export const VoltProviderContextProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const api = useContext(ApiContext);
  const { displayJsSuccess, displayJsError } = useContext(FeedbackContext);

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
      console.log('handleProviderStatusUpdate', e);
      if (e?.connected === true && !providerIsConnected) {
        setProviderIsConnected(true);
      } else if (e?.connected === false) {
        setProviderIsConnected(false);
      }
    }

    const subscribeProvider = () => {
      try {
        api.subscribe({
          app: "volt-provider",
          path: "/status",
          event: handleProviderStatusUpdate,
          err: () => displayJsError("Subscription to /status rejected"),
          quit: () => displayJsError("Kicked from subscription to /status"),
        });
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
