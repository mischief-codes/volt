import React from 'react';

interface CommandFormProps {
  children: React.ReactNode[];
}

const CommandForm: React.FC<CommandFormProps> = ({ children }) => {
  return (
    <form>
      <div className="margin-x-auto grid grid-cols-4 w-full">
      {children}
      </div>
    </form>

  );
};

export default CommandForm;
