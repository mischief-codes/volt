import React, { FormEvent } from 'react';

interface ButtonProps {
  label: string;
  onClick: (e: FormEvent) => void;
  className?: string;
}

const Button = ({ label, onClick, className = '' }: ButtonProps) => {
  return (
    <button
      onClick={onClick}
      className={`bg-gray-600 w-8/12 mx-auto text-white py-3 mt-6 rounded-md text-base cursor-pointer col-span-2 col-start-2 ${className}`}
    >
      {label}
    </button>
  );
};

export default Button;
