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
      className={`bg-gray-600 text-white px-4 py-2 rounded-md text-base cursor-pointer ${className}`}
    >
      {label}
    </button>
  );
};

export default Button;
