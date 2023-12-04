import React from 'react';

interface CommandFeedbackProps {
  feedback: string;
}

const FeedbackDisplay: React.FC<CommandFeedbackProps> = ({ feedback }) => {
  return (
    <div>
      <h1>Feedback Display</h1>
      <p>{feedback}</p>
    </div>
  );
};

export default FeedbackDisplay;
