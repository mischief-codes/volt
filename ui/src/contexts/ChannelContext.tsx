import React, { createContext, useState, useEffect, useContext, useMemo} from 'react';
import Channel, { ChannelJson, ChannelStatus } from '../types/Channel';
import { FeedbackContext } from './FeedbackContext';
import { ApiContext } from './ApiContext';
import BitcoinAmount from '../types/BitcoinAmount';
import { ChannelDeletedUpdate, ChannelStateUpdate, InitialStateUpdate, NewChannelUpdate, Update, UpdateType } from '../types/Update';

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

export const ChannelContextProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const api = useContext(ApiContext);
  const { displayJsInfo, displayJsSuccess, displayJsError } = useContext(FeedbackContext);

  const [subscriptionConnected, setSubscriptionConnected] = useState<boolean>(false);
  const [channels, setChannels] = useState<Array<Channel>>([]);

  const channelsByStatus = useMemo(() => {
    return channels.reduce(
      (acc: { [key in ChannelStatus]: Channel[] }, channel) => {
        const status = channel.status;
        acc[status].push(channel);
        return acc;
      },
      {
        preopening: [],
        opening: [],
        funded: [],
        open: [],
        shutdown: [],
        closing: [],
        "force-closing": [],
        closed: [],
        redeemed: [],
      } as { [key in ChannelStatus]: Channel[] }
    );
  }, [channels]);

  useEffect(() => {
    if (subscriptionConnected) {
      displayJsSuccess("Subscription to /all succeeded");
    }
  }, [subscriptionConnected]);

  useEffect(() => {
    const handleAllUpdate = (update: Update) => {
      console.log('Got update from /all', update);
      if (!subscriptionConnected) {
        setSubscriptionConnected(true);
      } else {
        displayJsInfo("Got update from /all");
      }
      if (update.type === UpdateType.NeedFunding) {
        console.log('Got need funding update from /all', update);
      // handled in HotWalletContext
      } if (update.type === UpdateType.InitialState) {
        console.log('Got initial state update from /all', update);
        handleInitialState(update as InitialStateUpdate);
      } else if (update.type === UpdateType.ChannelState) {
        console.log('Got channel state update from /all', update);
        handleChannelUpdate(update as ChannelStateUpdate);
      } else if (update.type === UpdateType.NewChannel) {
        console.log('Got new channel update from /all', update);
        handleNewChannel(update as NewChannelUpdate);
      } else if (update.type === UpdateType.ChannelDeleted) {
        console.log('Got channel deleted update from /all', update);
        handleChannelDeleted(update as ChannelDeletedUpdate);
      } else {
        console.log('Unimplemented update type', update);
      }
    }

    const handleChannelUpdate = (update: ChannelStateUpdate) => {
      const { id, status }: { id: string, status: ChannelStatus } = update;
      if (!id || !status) return;
      return setChannels((channels) => {
        const channel = channels.find((channel) => channel.id === id);
        if (!channel) {
          console.error('Channel not found in update from /all', update);
          return channels;
        }
        channel.status = status;
        return [...channels];
      })
    }

    const handleNewChannel = (update: NewChannelUpdate) => {
      const { 'chan-info': jsonChan }: { 'chan-info': ChannelJson } = update;
      setChannels((channels) => {
        if (channels.find((channel) => channel.id === jsonChan.id)) return channels;
        const channel = {
          ...jsonChan,
          his: new BitcoinAmount(jsonChan.his),
          our: new BitcoinAmount(jsonChan.our),
        };
        return [...channels, channel];
      });
    }

    const handleChannelDeleted = (update: ChannelDeletedUpdate) => {
      const { id }: { id: string } = update;
      setChannels((channels) => {
        const channel = channels.find((channel) => channel.id === id);
        if (!channel) return channels;
        return channels.filter((channel) => channel.id !== id);
      })
    }

    const handleInitialState = (update: InitialStateUpdate) => {
      const { chans: jsonChans }: { 'chans': Array<ChannelJson> } = update;
      const channels: Array<Channel> = jsonChans.map((chan) => {
        return {
          ...chan,
          his: new BitcoinAmount(chan.his),
          our: new BitcoinAmount(chan.our),
        }
      });
      setChannels(channels);
    };

    const subscribe = () => {
      try {
        api.subscribe({
          app: "volt",
          path: "/all",
          event: (e) => {
            handleAllUpdate(e);
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
    return channelsByStatus.open?.reduce(
      (total, channel) => total.add(channel.his), new BitcoinAmount(0)
    );
  }, [channelsByStatus]);

  const outboundCapacity = useMemo(() => {
    return channelsByStatus.open?.reduce(
      (total, channel) => total.add(channel.our), new BitcoinAmount(0)
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
