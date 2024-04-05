import React, { useState, useContext } from 'react';
import AddInvoice from './AddInvoice';
import CloseChannel from './CloseChannel';
import CreateFunding from './CreateFunding';
import OpenChannel from './OpenChannel';
import SendPayment from './SendPayment';
import InvoiceAndPay from './InvoiceAndPay';
import SetProvider from './SetProvider';
import { ChannelStatus } from '../../types/Channel';
import SetUrl from './SetUrl';
import { ChannelContext } from '../../contexts/ChannelContext';
import { ApiContext } from '../../contexts/ApiContext';


const Commands: React.FC = () => {
  const api = useContext(ApiContext)
  const { channelsByStatus } = useContext(ChannelContext);

  const [selectedCommand, setSelectedCommand] = useState('Set Provider');

    const openChannels = channelsByStatus[ChannelStatus.Open];
    const preopeningChannels = channelsByStatus[ChannelStatus.Preopening];

    const commands = [
      { name: 'Set Provider', component: <SetProvider api={api} /> },
      { name: 'Set URL', component: <SetUrl api={api} /> },

      { name: 'Open Channel', component: <OpenChannel api={api} /> },
      {
        name: 'Create Funding',
        component: <CreateFunding api={api} preopeningChannels={preopeningChannels}  />
      },
      {
        name: 'Send Payment',
        component: <SendPayment api={api} /> },
      {
        name: 'Close Channel',
        component: <CloseChannel api={api} openChannels={openChannels}  />
      },
      { name: 'Add Invoice', component: <AddInvoice api={api} /> },
      { name: 'Invoice and Pay', component: <InvoiceAndPay api={api} /> },

    ];

    const handleCommandChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
      setSelectedCommand(event.target.value);
    };

    return (
      <div className='flex flex-col items-center'>
        <h1 className='text-xl mb-2'>Command</h1>
        <select
          value={selectedCommand}
          onChange={handleCommandChange}
          className="p-2 mb-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-orange-600 w-4/12"
        >
          {commands.map((command) => (
            <option key={command.name} value={command.name}>
              {command.name}
            </option>
          ))}
        </select>
        {selectedCommand && (
          <div className='w-full'>
            {commands.find((command) => command.name === selectedCommand)?.component}
          </div>
        )}
      </div>
    );
  };

  export default Commands;
