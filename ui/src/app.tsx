import React, { useEffect, useState } from 'react';
import Urbit from '@urbit/http-api';
import CommandSelect from './components/CommandSelect';
import Channel from './types/Channel';
import './index.css';
import CommandFeedback from './components/FeedbackConsole';
import { FeedbackContextProvider } from './contexts/FeedbackContext';

const api = new Urbit('', '', window.desk);
api.ship = 'zod'  // window.ship;
console.log('api.ship', api.ship);

export function App() {
  const [commandFeedback, setCommandFeedback] = useState("");
  const [txs, setTxs] = useState<Array<Object>>([]);
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

  const addFeedback = (feedback: string) => {
    setCommandFeedback(commandFeedback + feedback);
  }

  useEffect(() => {
    const handleChannelUpdate = ({
      chans,
      txs,
    }: {
      chans: Array<Channel>;
      txs: Array<Object>;
    }) => {
      setTxs(txs);
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
      setChannelsByStatus(channelsByStatus);
    };

    const subscribe = () => {
      try {
        const res = api.subscribe({
          app: "volt",
          path: "/all",
          event: (e) => handleChannelUpdate(e),
          err: () => console.log("Subscription rejected"),
          quit: () => console.log("Kicked from subscription"),
        });
        console.log('subscribed', res);
      } catch (e) {
        console.log("Subscription failed", e);
      }
    };
    subscribe()
  }, [])

  return (
    <FeedbackContextProvider>
      <main className="bg-gray-200 h-screen">
        <div className="flex flex-col items-center justify-start h-full mx-auto w-1/2">
          <div className="bg-gradient-to-r from-slate-100 to-white h-2/3 w-full">
            <CommandSelect
              api={api}
              channelsByStatus={channelsByStatus}
            />
          </div>
          <div className='bg-slate-800 h-1/3 w-full overflow-scroll '>
            <CommandFeedback />
          </div>
        </div>
      </main>
    </FeedbackContextProvider>
  );
}
