import React, { useEffect, useRef, useContext } from 'react';
import { FeedbackContext } from '../../contexts/FeedbackContext';

const FeedbackConsole: React.FC = () => {
  const { lines } = useContext(FeedbackContext);

  const bottomScrollDiv = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (lines?.length) {
      bottomScrollDiv.current?.scrollIntoView({
        behavior: "smooth",
        block: "end",
      });
    }
  }, [lines]);

  return (
    <div className='px-2 py-1 '>
      {lines}
      <div ref={bottomScrollDiv}></div>
    </div>
  );
};

export default FeedbackConsole;
