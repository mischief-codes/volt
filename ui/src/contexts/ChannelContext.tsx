import React, { createContext, useState, useEffect, useContext, useMemo} from 'react';
import Channel, { ChannelJson } from '../types/Channel';
import { FeedbackContext } from './FeedbackContext';
import { ApiContext } from './ApiContext';
import BitcoinAmount from '../types/BitcoinAmount';

// Define the shape of the context value
interface ChannelContextValue {
  subscriptionConnected: boolean;
  inboundCapacity: BitcoinAmount;
  outboundCapacity: BitcoinAmount;
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
  inboundCapacity: new BitcoinAmount(0),
  outboundCapacity: new BitcoinAmount(0),
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
  const { displayJsInfo, displayJsSuccess, displayJsError } = useContext(FeedbackContext);

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
    if (subscriptionConnected) {
      displayJsSuccess("Subscription to /all succeeded");
    }
  }, [subscriptionConnected]);

  useEffect(() => {
    const handleChannelUpdate = ({
      chans: jsonChans,
      txs,
      invoices
    }: {
      chans: Array<ChannelJson>;
      txs: Array<Object>;
      invoices: Array<Object>;
    }) => {
      if (!jsonChans) return;
      if (!subscriptionConnected) {
        setSubscriptionConnected(true);
      } else {
        displayJsInfo("Got update from /all");
      }

      const channels: Array<Channel> = jsonChans.map((chan) => {
        return { ...chan, his: new BitcoinAmount(chan.his), our: new BitcoinAmount(chan.our) }
      });

      setChannels(channels);
      const defaultChannelsByStatus = {
        preopening: [] as Channel[],
        opening: [] as Channel[],
        funded: [] as Channel[],
        open: [] as Channel[],
        shutdown: [] as Channel[],
        closing: [] as Channel[],
        "force-closing": [] as Channel[],
        closed: [] as Channel[],
        redeemed: [] as Channel[],
      };
      const channelsByStatus = channels.reduce(
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
          err: () => displayJsError("Subscription to /all rejected"),
          quit: () => displayJsError("Kicked from subscription to /all"),
        });
      } catch (e) {
        displayJsError("Error subscribing to /all"),
        console.error(e)
      }
    };
    subscribe()
  }, [])

  const inboundCapacity = useMemo(() => {
    return channelsByStatus.opening.reduce(
      (total, channel) => total.add(channel.his), new BitcoinAmount(0)
    );
  }, [channelsByStatus]);

  const outboundCapacity = useMemo(() => {
    return channelsByStatus.opening.reduce(
      (total, channel) => total.add(channel.his), new BitcoinAmount(0)
    );
  }, [channelsByStatus]);

  const value = {
    subscriptionConnected,
    channels,
    channelsByStatus,
    inboundCapacity,
    outboundCapacity
  };

  return (
    <ChannelContext.Provider value={value}>
      {children}
    </ChannelContext.Provider>
  );
};
