import React from 'react';

interface Option {
  label: string;
  value: any;
}

interface DropdownProps {
  label: string;
  value: any;
  onChange: (event: React.ChangeEvent<HTMLSelectElement>) => void;
  options: Option[];
  className?: string;
}

const Dropdown: React.FC<DropdownProps> = (
  { label, options, value, onChange, className = '' }
) => {
  const classNames = `border border-gray-300 px-4 py-3 rounded-md w-full ${className}`

  return (
    <div className={`mx-auto mt-2 w-10/12 col-span-2 col-start-2 ${className}`}>
      <span><label>{label}</label></span>
      <select
        value={value}
        onChange={onChange}
        className={classNames}
      >
        {options.map((option, index) => (
          <option key={index} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </div>
  );
};


export default Dropdown;
