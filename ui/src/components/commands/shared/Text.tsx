import React from 'react';
import Button from './Button';

interface TextProps {
  text: string;
  className?: string;
}


const Text = ({ text, className = '' }: TextProps) => {
  return (
    <div
      className={`mx-auto w-10/12 col-span-2 col-start-2 text-center ${className}`}
    >
      {text}
    </div>
  );
};

export default Text;
