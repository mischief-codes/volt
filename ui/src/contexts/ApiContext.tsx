import React, { createContext, useEffect } from 'react';
import Urbit from '@urbit/http-api';

type ApiContextValue = Urbit;

const api = new Urbit('', '', window.desk);
api.ship = process.env.VITE_SHIP_NAME || window.ship;

export const ApiContext = createContext<ApiContextValue>(api);

export const ApiProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {

  useEffect(() => {
    const redirectToAuthIfNotLoggedIn = async () => {
      try {
        await api.scry({
          app: "volt",
          path: "/hot-wallet-fee",
        });
      } catch (e: any) {
        if (e?.status === 403) {
          document.location = `${document.location.protocol}//${document.location.host}`;
        }
      }
    }
    // Redirect to the auth page happens automatically if this is running from a glob
    // So this is only useful for local development
    if (process.env.VITE_SHIP_NAME) {
      redirectToAuthIfNotLoggedIn();
    }
  }, []);

  return (
    <ApiContext.Provider value={api}>
      {children}
    </ApiContext.Provider>
  );
};
