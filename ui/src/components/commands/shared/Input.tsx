import React from 'react';

interface InputProps {
  label: string;
  value: string;
  onChange: (event: React.ChangeEvent<HTMLInputElement>) => void;
  className?: string;
}

const Input: React.FC<InputProps> = ({ label, value, onChange, className}) => {
  return (
    <div className={`flex mt-2 flex-col mx-auto w-10/12 col-start-2 col-span-2 ${className}`}>
      <span><label>{label}</label></span>
      <input
        type="text"
        value={value}
        onChange={onChange}
        className="`mt-1 p-2 border border-gray-300 rounded-md
        focus:outline-none focus:ring-2 focus:ring-orange-300 w-full"
      />
    </div>
  )
};

export default Input;
