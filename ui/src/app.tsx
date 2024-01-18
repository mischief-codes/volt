import React from 'react';
import './index.css';
import CommandFeedback from './components/feedback/FeedbackConsole';
import { FeedbackContextProvider } from './contexts/FeedbackContext';
import { ChannelContextProvider } from './contexts/ChannelContext';
import { InvoiceContextProvider } from './contexts/InvoiceContext';
import Commands from './components/commands/Commands';
import LiquidityDisplay from './components/status/LiquidityDisplay';
import ChannelDisplay from './components/status/ChannelDisplay';
import { VoltProviderContextProvider } from './contexts/VoltProviderContext';

export function App() {
  return (
    <FeedbackContextProvider>
      <ChannelContextProvider>
        <VoltProviderContextProvider>
          <InvoiceContextProvider>
            <main className="bg-slate-200 h-screen">
            <div className="flex h-full overflow-y-hidden">
            <div className="bg-zinc-100 w-1/2 pt-20">
                <Commands />
            </div>
              <div className='flex flex-col h-full w-1/2'>
                <div className='h-1/3 bg-zinc-800 overflow-scroll rounded-b-sm'>
                <CommandFeedback />
                </div>
                <div className='h-2/3 bg-zinc-300 text-gray-500 rounded-sm'>
                  <LiquidityDisplay/>
                  <ChannelDisplay />
                </div>
              </div>
            </div>
            </main>
          </InvoiceContextProvider>
        </VoltProviderContextProvider>
      </ChannelContextProvider>
    </FeedbackContextProvider>
  );
}
