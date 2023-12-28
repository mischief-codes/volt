import React from 'react';
import CommandSelect from './components/commands/Commands';
import './index.css';
import CommandFeedback from './components/feedback/FeedbackConsole';
import { FeedbackContextProvider } from './contexts/FeedbackContext';
import { ChannelContextProvider } from './contexts/ChannelContext';
import { InvoiceContextProvider } from './contexts/InvoiceContext';
import Commands from './components/commands/Commands';
import LiquidityDisplay from './components/status/LiquidityDisplay';
import ChannelDisplay from './components/status/ChannelDisplay';
// bg-gradient-to-r from-slate-100


export function App() {
  return (
    <FeedbackContextProvider>
      <ChannelContextProvider>
        <InvoiceContextProvider>
        <main className="bg-slate-200 h-screen">
          <div className="flex h-screen">
              <div className="bg-zinc-100 w-1/2 pt-20">
                <Commands />
              </div>
            <div className='flex flex-col h-full w-1/2'>
              <div className='h-1/3 bg-zinc-800 overflow-scroll rounded-b-sm'>
              <CommandFeedback />
              </div>
              <div className='h-2/3 bg-zinc-300 text-gray-500 pt-10 rounded-sm'>
                <LiquidityDisplay/>
                <hr className="h-px mx-5 mt-6 mb-10 bg-slate-400 border-0"></hr>
                <ChannelDisplay />
              </div>
            </div>
          </div>
        </main>
        </InvoiceContextProvider>
      </ChannelContextProvider>
    </FeedbackContextProvider>
  );
}
