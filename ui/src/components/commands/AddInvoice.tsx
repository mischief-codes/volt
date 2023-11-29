import React, { useState } from 'react';
import Urbit from '@urbit/http-api';

const AddInvoice = ({ api }: { api: Urbit }) => {
  const [input1, setInput1] = useState('');
  const [input2, setInput2] = useState('');
  const [selectedOption, setSelectedOption] = useState('');

  const handleInputChange1 = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInput1(e.target.value);
  };

  const handleInputChange2 = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInput2(e.target.value);
  };

  const handleDropdownChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setSelectedOption(e.target.value);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Perform any necessary actions with the input values
    console.log('Input 1:', input1);
    console.log('Input 2:', input2);
    console.log('Selected Option:', selectedOption);
  };

  return (
    <form onSubmit={handleSubmit} className="p-4 bg-gray-100">
      <label className="block mb-2">
        Input 1:
        <input
          type="text"
          value={input1}
          onChange={handleInputChange1}
          className="border border-gray-300 rounded-md px-2 py-1"
        />
      </label>
      <br />
      <label className="block mb-2">
        Input 2:
        <input
          type="text"
          value={input2}
          onChange={handleInputChange2}
          className="border border-gray-300 rounded-md px-2 py-1"
        />
      </label>
      <br />
      <label className="block mb-2">
        Dropdown:
        <select
          value={selectedOption}
          onChange={handleDropdownChange}
          className="border border-gray-300 rounded-md px-2 py-1"
        >
          <option value="">Select an option</option>
          <option value="option1">Option 1</option>
          <option value="option2">Option 2</option>
          <option value="option3">Option 3</option>
        </select>
      </label>
      <br />
      <button type="submit" className="bg-blue-500 text-white px-4 py-2 rounded-md">
        Submit
      </button>
    </form>
  );
};

export default AddInvoice;
