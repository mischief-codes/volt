import React, { useEffect, useRef, useContext } from 'react';
import { FeedbackContext } from '../contexts/FeedbackContext';
import FeedbackConsoleLine from './FeedbackConsoleLine';


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

  const defaultLines = [
  <FeedbackConsoleLine isError={false} isSuccess={false} text={'Volt 1.0 UI ⚡'} key={'-1'} />,
  ]
  // lines.forEach((line, index) => {
  //   line.key = String(index);
  // })

  return (
    <div className='px-2 py-1 '>
      {lines.length ? lines : defaultLines}
      <div ref={bottomScrollDiv}></div>
    </div>
  );
};

export default FeedbackConsole;
