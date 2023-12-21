import React from 'react';
import CommandSelect from './components/commands/Commands';
import './index.css';
import CommandFeedback from './components/feedback/FeedbackConsole';
import { FeedbackContextProvider } from './contexts/FeedbackContext';
import { ChannelContextProvider } from './contexts/ChannelContext';
import { InvoiceContextProvider } from './contexts/InvoiceContext';
import Commands from './components/commands/Commands';



export function App() {
  return (
    <FeedbackContextProvider>
      <ChannelContextProvider>
        <InvoiceContextProvider>
        <main className="bg-gray-200 h-screen">
          <div className="flex flex-col items-center justify-start h-full mx-auto w-1/2">
            <div className="bg-gradient-to-r from-slate-100 to-white h-2/3 w-full">
              <Commands />
            </div>
            <div className='bg-slate-800 h-1/3 w-full overflow-scroll '>
              <CommandFeedback />
            </div>
          </div>
        </main>
        </InvoiceContextProvider>
      </ChannelContextProvider>
    </FeedbackContextProvider>
  );
}
