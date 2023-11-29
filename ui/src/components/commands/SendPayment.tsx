import React, { useState } from 'react';
import Urbit from '@urbit/http-api';

const SendPayment = ({ api }: { api: Urbit }) => {
  const [payreq, setPayreq] = useState('');
  const [ship, setShip] = useState('');

  const handlePayreqChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPayreq(e.target.value);
  };

  const handleShipChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setShip(e.target.value);
  };

  const handleButtonClick = () => {
    // Handle button click logic here
    console.log('Payreq:', payreq);
    console.log('Ship:', ship);
  };

  return (
    <div className="flex flex-col items-center">
      <input
        type="text"
        value={payreq}
        onChange={handlePayreqChange}
        placeholder="Enter payreq"
        className="border border-gray-300 rounded-md px-4 py-2 mb-4"
      />
      <input
        type="text"
        value={ship}
        onChange={handleShipChange}
        placeholder="Enter ship"
        className="border border-gray-300 rounded-md px-4 py-2 mb-4"
      />
      <button
        onClick={handleButtonClick}
        className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
      >
        Send Payment
      </button>
    </div>
  );
};

export default SendPayment;
