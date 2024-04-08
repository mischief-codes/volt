import React, { createContext, useContext, useEffect, useState } from 'react';
import BitcoinAmount from '../types/BitcoinAmount';
import { ApiContext } from './ApiContext';
import { FeedbackContext } from './FeedbackContext';
import { NeedFundingUpdate, UpdateType } from '../types/Update';
import { ChannelId, FundingAddress, TauAddress } from '../types/Channel';

interface HotWalletContextValue {
  hotWalletFee: BitcoinAmount | null;
  tauAddressByTempChanId: Record<ChannelId, TauAddress>;
  fundingAddressByTempChanId: Record<ChannelId, FundingAddress>;
};

export const HotWalletContext = createContext<HotWalletContextValue>({
  hotWalletFee: null,
  tauAddressByTempChanId: {},
  fundingAddressByTempChanId: {},
});

export const HotWalletContextProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const api = useContext(ApiContext);
  const { displayJsError } = useContext(FeedbackContext);

  const [hotWalletFee, setHotWalletFee] = useState<BitcoinAmount | null>(null);
  const [tauAddressByTempChanId, setTauAddressByTempChanId] = useState({});
  const [fundingAddressByTempChanId, setFundingAddressByTempChanId] = useState({});

  useEffect(() => {
    const getHotWalletFee = async () => {
      try {
        const response = await api.scry({
          app: "volt",
          path: "/hot-wallet-fee",
        });
        if (response.sats === null) {
          setHotWalletFee(null);
        } else {
          setHotWalletFee(BitcoinAmount.fromSatoshis(response.sats));
        }
      } catch (e) {
        console.error(e);
        displayJsError("Subscription to /hot-wallet-fee rejected")
        return null;
        }
    }
    getHotWalletFee()
  }, []);

  useEffect(() => {
    const handleNeedFunding = (update: NeedFundingUpdate) => {
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
    hotWalletFee,
    tauAddressByTempChanId,
    fundingAddressByTempChanId,
  }

  return (
    <HotWalletContext.Provider value={value}>
      {children}
    </HotWalletContext.Provider>
  );
};
