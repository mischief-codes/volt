import React, { createContext, useState } from 'react';
import FeedbackConsoleLine from '../components/FeedbackConsoleLine';

interface FeedbackContextValue {
  displayError: (feedback: string, text: string) => void;
  displaySuccess: (command: string) => void;
  displayInfo: (text: string) => void;
  lines: Array<React.JSX.Element>;
}

// Create the context
export const FeedbackContext = createContext<FeedbackContextValue>({
  displayError: () => {},
  displaySuccess: () => {},
  displayInfo: () => {},
  lines: [],
});

export const FeedbackContextProvider: React.FC<{ children: React.JSX.Element }> = ({ children })  => {
  const [lines, setLines] = useState<Array<React.JSX.Element>>([]);

  const displayError = (command: string, text: string): void => {
    const newLines = text.split('\n').filter(line => line.length).map(line => {
      return <FeedbackConsoleLine isError={false} isSuccess={false} text={line} />
    })
    newLines.push(
    <FeedbackConsoleLine isError={true} isSuccess={false} text={`%${command} failed`} />
    )
    setLines([...lines, ...newLines]);
  }

  const displaySuccess = (command: string): void => {
    const newLine = (
      <FeedbackConsoleLine isError={false} isSuccess={true} text={`%${command} succeeded`} />
    );
    setLines([...lines, newLine]);
  }

  const displayInfo = (text: string): void => {
    const newLines = text.split('\n').filter(line => line.length).map(line => {
      return <FeedbackConsoleLine isError={false} isSuccess={false} text={line} />
    })
    setLines([...lines, ...newLines]);
  }

  return (
    <FeedbackContext.Provider value={{ displayError, displaySuccess, displayInfo, lines }}>
      {children}
    </FeedbackContext.Provider>
  );
};

