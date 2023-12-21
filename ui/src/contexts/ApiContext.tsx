import React, { createContext } from 'react';
import Urbit from '@urbit/http-api';

type ApiContextValue = Urbit;

const api = new Urbit('', '', window.desk);
api.ship = 'zod';  // window.ship;

export const ApiContext = createContext<ApiContextValue>(api);

export const ApiProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <ApiContext.Provider value={api}>
      {children}
    </ApiContext.Provider>
  );
};
