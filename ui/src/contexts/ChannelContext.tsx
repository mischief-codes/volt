import React, { createContext, useState, useEffect, useContext} from 'react';
import Channel from '../types/Channel';
import { FeedbackContext } from './FeedbackContext';
import { ApiContext } from './ApiContext';

// Define the shape of the context value
interface ChannelContextValue {
  subscriptionConnected: boolean;
  channels: Array<Channel>;
  channelsByStatus: {
    preopening: Channel[];
    opening: Channel[];
    funded: Channel[];
    open: Channel[];
    shutdown: Channel[];
    closing: Channel[];
    "force-closing": Channel[];
    closed: Channel[];
    redeemed: Channel[];
  };
}

// Create the context
export const ChannelContext = createContext<ChannelContextValue>({
  subscriptionConnected: false,
  channels: [],
  channelsByStatus: {
    preopening: [],
    opening: [],
    funded: [],
    open: [],
    shutdown: [],
    closing: [],
    "force-closing": [],
    closed: [],
    redeemed: [],
  },
});

// Create a provider component
export const ChannelContextProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const api = useContext(ApiContext);
  const { displaySuccess, displayError, displayInfo } = useContext(FeedbackContext);

  const [subscriptionConnected, setSubscriptionConnected] = useState<boolean>(false);
  const [channels, setChannels] = useState<Array<Channel>>([]);
  const [channelsByStatus, setChannelsByStatus] = useState<{
    preopening: Channel[];
    opening: Channel[];
    funded: Channel[];
    open: Channel[];
    shutdown: Channel[];
    closing: Channel[];
    "force-closing": Channel[];
    closed: Channel[];
    redeemed: Channel[];
  }>({
    preopening: [],
    opening: [],
    funded: [],
    open: [],
    shutdown: [],
    closing: [],
    "force-closing": [],
    closed: [],
    redeemed: [],
  });



  useEffect(() => {
    const handleChannelUpdate = ({
      chans,
      txs,
      invoices
    }: {
      chans: Array<Channel>;
      txs: Array<Object>;
      invoices: Array<Object>;
    }) => {
      if (!subscriptionConnected) {
        console.log("Subscription to /all succeeded");
        displaySuccess("Subscription to /all succeeded");
        setSubscriptionConnected(true);
      } else {
        displayInfo("Got update from /all");
      }
      setChannels(chans);
      const defaultChannelsByStatus = {
        preopening: [] as Channel[], opening: [] as Channel[],
        funded: [] as Channel[], open: [] as Channel[],
        shutdown: [] as Channel[], closing: [] as Channel[],
        "force-closing": [] as Channel[], closed: [] as Channel[],
        redeemed: [] as Channel[],
      };
      const channelsByStatus = chans.reduce(
        (acc, channel) => {
          const status = channel.status;
          if (acc[status]) acc[status].push(channel);
          else acc[status] = [channel];
          return acc;
        },
        { ...defaultChannelsByStatus }
      );
      console.log('channelsByStatus', channelsByStatus)
      setChannelsByStatus(channelsByStatus);
    };

    const subscribe = () => {
      try {
        api.subscribe({
          app: "volt",
          path: "/all",
          event: (e) => {
            console.log('e', e);
            handleChannelUpdate(e);
          },
          err: () => displayError("Subscription to /all rejected"),
          quit: () => displayError("Kicked from subscription to /all"),
        });
      } catch (e) {
        displayError("Error subscribing to /all"),
        console.error(e)
      }
    };
    subscribe()
  }, [])


  const value = {
    subscriptionConnected,
    channels,
    channelsByStatus,
  };

  return (
    <ChannelContext.Provider value={value}>
      {children}
    </ChannelContext.Provider>
  );
};
