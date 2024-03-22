import Urbit from '@urbit/http-api';
import React, { createContext, useContext, useEffect, useState } from 'react';
import BitcoinAmount from '../types/BitcoinAmount';
import { ApiContext } from './ApiContext';
import { FeedbackContext } from './FeedbackContext';
import { NeedFundingUpdate, UpdateType } from '../types/Update';
import { ChannelId, FundingAddress, TauAddress } from '../types/Channel';

interface HotWalletContextValue {
  openingTxFee: BitcoinAmount | null;
  tauAddressByTempChanId: Record<ChannelId, TauAddress>;
  fundingAddressByTempChanId: Record<ChannelId, FundingAddress>;
};

export const HotWalletContext = createContext<HotWalletContextValue>({
  openingTxFee: null,
  tauAddressByTempChanId: {},
  fundingAddressByTempChanId: {},
});

export const HotWalletContextProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const api = useContext(ApiContext);
  const { displayJsError } = useContext(FeedbackContext);

  const [openingTxFee, setOpeningTxFee] = useState<BitcoinAmount | null>(null);
  const [tauAddressByTempChanId, setTauAddressByTempChanId] = useState({});
  const [fundingAddressByTempChanId, setFundingAddressByTempChanId] = useState({});

  // useEffect(() => {
  //   const getOpeningTxFee = async () => {
  //     console.log('getting opening tx fee!!')
  //     try {
  //       const response = await api.scry({
  //         app: "volt",
  //         path: "/fees/opening-tx",
  //       });
  //       console.log('response', response)
  //       setOpeningTxFee(BitcoinAmount.fromSatoshis(response));
  //     } catch (e) {
  //       console.error(e);
  //       displayJsError("Subscription to /all rejected")
  //       return null;
  //       }
  //   }
  //   getOpeningTxFee()
  // }, []);

  useEffect(() => {
    const handleNeedFunding = (update: NeedFundingUpdate) => {
      console.log('handling need funding!!', update);
      const fundingInfo = update['funding-info'];
      let newTauAddressByTempChanId: Record<ChannelId, TauAddress> = {...tauAddressByTempChanId,};
      let newFundingAddressByTempChanId: Record<ChannelId, FundingAddress> = {...fundingAddressByTempChanId};
      fundingInfo.forEach((info) => {
        newTauAddressByTempChanId[info['temporary-channel-id']] = info['tau-address'];
        newFundingAddressByTempChanId[info['temporary-channel-id']] = info['funding-address'];
      });
      setTauAddressByTempChanId(newTauAddressByTempChanId);
      setFundingAddressByTempChanId(newFundingAddressByTempChanId);
    }

    const subscribe = () => {
      try {
        api.subscribe({
          app: "volt",
          path: "/all",
          event: (update) => {
            console.log('update!!', update)
            if (update.type === UpdateType.NeedFunding) handleNeedFunding(update);
          },
          err: () => displayJsError("Subscription to /all rejected"),
          quit: () => displayJsError("Kicked from subscription to /all"),
        });
      } catch (e) {
        displayJsError("Error subscribing to /all"),
        console.error(e)
      }
    };
    subscribe();
  }, []);

  const value: HotWalletContextValue  = {
    openingTxFee,
    tauAddressByTempChanId,
    fundingAddressByTempChanId,
  }

  return (
    <HotWalletContext.Provider value={value}>
      {children}
    </HotWalletContext.Provider>
  );
};
