import React, { useState } from 'react';
import Urbit from '@urbit/http-api';

const TestInvoice = ({ api }: { api: Urbit }) => {
  const [input1, setInput1] = useState('');
  const [input2, setInput2] = useState('');
  const [selectedOption, setSelectedOption] = useState('');

  const handleInputChange1 = (event: React.ChangeEvent<HTMLInputElement>) => {
    setInput1(event.target.value);
  };

  const handleInputChange2 = (event: React.ChangeEvent<HTMLInputElement>) => {
    setInput2(event.target.value);
  };

  const handleOptionChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedOption(event.target.value);
  };

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault();
    // Perform some action with the inputs and selected option
    console.log('Input 1:', input1);
    console.log('Input 2:', input2);
    console.log('Selected Option:', selectedOption);
  };

  return (
    <form onSubmit={handleSubmit} className="max-w-sm mx-auto">
      <div className="mb-4">
        <label htmlFor="input1" className="block mb-2">Input 1:</label>
        <input type="text" id="input1" value={input1} onChange={handleInputChange1} className="border border-gray-300 px-4 py-2 rounded-md w-full" />
      </div>
      <div className="mb-4">
        <label htmlFor="input2" className="block mb-2">Input 2:</label>
        <input type="text" id="input2" value={input2} onChange={handleInputChange2} className="border border-gray-300 px-4 py-2 rounded-md w-full" />
      </div>
      <div className="mb-4">
        <label htmlFor="dropdown" className="block mb-2">Dropdown:</label>
        <select id="dropdown" value={selectedOption} onChange={handleOptionChange} className="border border-gray-300 px-4 py-2 rounded-md w-full">
          <option value="">Select an option</option>
          <option value="option1">Option 1</option>
          <option value="option2">Option 2</option>
          <option value="option3">Option 3</option>
        </select>
      </div>
      <button type="submit" className="bg-blue-500 text-white px-4 py-2 rounded-md">Submit</button>
    </form>
  );
};

export default TestInvoice;
