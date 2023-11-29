import React, { useState } from 'react';
import Urbit from '@urbit/http-api';

const OpenChannel = ({ api }: { api: Urbit }) => {
  const [input1, setInput1] = useState('');
  const [input2, setInput2] = useState('');
  const [selectedOption, setSelectedOption] = useState('');

  const handleInputChange1 = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInput1(e.target.value);
  };

  const handleInputChange2 = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInput2(e.target.value);
  };

  const handleOptionChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedOption(e.target.value);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Perform some action with the inputs and selected option
    console.log('Input 1:', input1);
    console.log('Input 2:', input2);
    console.log('Selected Option:', selectedOption);
  };

  return (
    <form onSubmit={handleSubmit} className="max-w-sm mx-auto">
      <label className="block mb-2">
        Input 1:
        <input
          type="text"
          value={input1}
          onChange={handleInputChange1}
          className="border border-gray-300 rounded-md px-2 py-1 w-full"
        />
      </label>
      <br />
      <label className="block mb-2">
        Input 2:
        <input
          type="text"
          value={input2}
          onChange={handleInputChange2}
          className="border border-gray-300 rounded-md px-2 py-1 w-full"
        />
      </label>
      <br />
      <label className="block mb-2">
        Select an option:
        <select
          value={selectedOption}
          onChange={handleOptionChange}
          className="border border-gray-300 rounded-md px-2 py-1 w-full"
        >
          <option value="">-- Select --</option>
          <option value="option1">Option 1</option>
          <option value="option2">Option 2</option>
          <option value="option3">Option 3</option>
        </select>
      </label>
      <br />
      <button
        type="submit"
        className="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded"
      >
        Submit
      </button>
    </form>
  );
};

export default OpenChannel;
