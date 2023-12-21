import React, { createContext, useState } from 'react';
import FeedbackConsoleLine from '../components/feedback/FeedbackConsoleLine';

interface FeedbackContextValue {
  displayError: (text: string) => void;
  displaySuccess: (text: string) => void;
  displayCommandError: (command: string, text: string) => void;
  displayCommandSuccess: (command: string) => void;
  displayInfo: (text: string) => void;
  lines: Array<React.JSX.Element>;
}

// Create the context
export const FeedbackContext = createContext<FeedbackContextValue>({
  displayError: () => {},
  displaySuccess: () => {},
  displayCommandError: () => {},
  displayCommandSuccess: () => {},
  displayInfo: () => {},
  lines: [],
});

export const FeedbackContextProvider: React.FC<{ children: React.ReactNode }> = ({ children })  => {
  const defaultLine = <FeedbackConsoleLine isError={false} isSuccess={false} text={'Volt 1.0 UI ⚡'} />
  const [lines, setLines] = useState<Array<React.JSX.Element>>([defaultLine]);

  const displayError = (text: string): void => {
    const line = <FeedbackConsoleLine isError={true} isSuccess={false} text={text} />
    setLines([...lines, line]);
  }

  const displaySuccess = (text: string): void => {
    console.log('displaySuccess', text);
    const line = <FeedbackConsoleLine isError={false} isSuccess={true} text={text} />
    setLines([...lines, line]);
  }

  const displayCommandError = (command: string, text: string): void => {
    const newLines = text.split('\n').filter(line => line.length).map(line => {
      return <FeedbackConsoleLine isError={false} isSuccess={false} text={line} />
    })
    newLines.push(
      <FeedbackConsoleLine isError={true} isSuccess={false} text={`%${command} failed`} />
    )
    setLines([...lines, ...newLines]);
  }

  const displayCommandSuccess = (command: string): void => {
    const newLine = (
      <FeedbackConsoleLine isError={false} isSuccess={true} text={`%${command} succeeded`} />
    );
    setLines([...lines, newLine]);
  }

  const displayInfo = (text: string): void => {
    const newLine = <FeedbackConsoleLine isError={false} isSuccess={false} text={text} />
    setLines([...lines, newLine]);
  }

  const value = {
    displayError,
    displaySuccess,
    displayCommandError,
    displayCommandSuccess,
    displayInfo,
    lines,
  };

  return (
    <FeedbackContext.Provider value={value}>
      {children}
    </FeedbackContext.Provider>
  );
};
