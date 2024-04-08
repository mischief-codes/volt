import React from 'react';

interface FeedbackConsoleLine {
  text: string;
  isError?: boolean;
  isSuccess?: boolean;
}

const FeedbackConsoleLine = ({ text, isError = false, isSuccess = false }: { text: string, isError: boolean, isSuccess: boolean }) => {
  const prompt = <span className='text-slate-400 select-none pr-1'>{'>'}</span>
  if (isError) {
    return (
      <span className='inline'><p className='text-red-500'>{prompt}{text}</p></span>
    )
  } else if (isSuccess) {
    return (
      <span className='inline'><p className='text-green-500'>{prompt}{text}</p></span>
    )
  } else {
    return <span className='inline'><p className='text-slate-400'>{prompt}{text}</p></span>
  }
}

export default FeedbackConsoleLine;
