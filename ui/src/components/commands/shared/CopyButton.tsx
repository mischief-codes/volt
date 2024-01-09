import React from 'react';
import Input from './Input';

interface CopyButtonProps {
  label: string;
  buttonText: string;
  copyText: string | null;
  onClick?: (event: React.ChangeEvent<HTMLInputElement>) => void;
  className?: string;
}

const CopyButton: React.FC<CopyButtonProps> = ({ label, buttonText, copyText, className}) => {
  const onClick = (e: React.FormEvent) => {
    e.preventDefault();
    if (!copyText) return;
    navigator.clipboard.writeText(copyText);
  }

  return (
    <div className={`flex mt-2 flex-col mx-auto w-10/12 col-start-2 col-span-2 ${className}`}>
      <span><label>{label}</label></span>
      <button
        onClick={onClick}
        className={
          'border border-orange-600 bg-white w-full mx-auto text-orange-600 py-2 rounded-md ' +
          `text-base cursor-pointer col-span-2 col-start-2 ${className}`
        }
      >
        {buttonText}
      </button>
    </div>
  )
};

export default CopyButton;
