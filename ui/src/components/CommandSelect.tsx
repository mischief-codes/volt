import React, { useState } from 'react';
import AddInvoice from './commands/AddInvoice';
import CloseChannel from './commands/CloseChannel';
import CreateFunding from './commands/CreateFunding';
import OpenChannel from './commands/OpenChannel';
import SendPayment from './commands/SendPayment';
import SetProvider from './commands/SetProvider';
import TestInvoice from './commands/TestInvoice';
import Urbit from '@urbit/http-api';

const CommandSelect = ({ api }: { api: Urbit }) => {
    const [selectedCommand, setSelectedCommand] = useState('Set Provider');

    const commands = [
      { name: 'Set Provider', component: <SetProvider api={api} /> },
      { name: 'Open Channel', component: <OpenChannel api={api} /> },
      { name: 'Create Funding', component: <CreateFunding api={api} /> },
      { name: 'Send Payment', component: <SendPayment api={api} /> },
      { name: 'Close Channel', component: <CloseChannel api={api} /> },
      { name: 'Add Invoice', component: <AddInvoice api={api} /> },
      { name: 'Test Invoice', component: <TestInvoice api={api} /> },
    ];

    const handleCommandChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
      setSelectedCommand(event.target.value);
    };

    return (
      <div className="flex flex-col items-center">
        <select
          value={selectedCommand}
          onChange={handleCommandChange}
          className="p-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">Select a command</option>
          {commands.map((command) => (
            <option key={command.name} value={command.name}>
              {command.name}
            </option>
          ))}
        </select>
        {selectedCommand && (
          <div className="mt-4">
            {commands.find((command) => command.name === selectedCommand)?.component}
          </div>
        )}
      </div>
    );
  };

  export default CommandSelect;
