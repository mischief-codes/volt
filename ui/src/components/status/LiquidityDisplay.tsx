import React, { useContext } from 'react';
import { ChannelContext } from '../../contexts/ChannelContext';


const LiquidityDisplay: React.FC = () => {
  const { inboundCapacity, outboundCapacity } = useContext(ChannelContext)

  return (
    <div className='p-10 space-y-8'>
      <h1 className='text-lg text-center'>Liquidity</h1>
      <div className='flex justify-between'>
        <span>{`Inbound: ${inboundCapacity.displayAsSats()}`}</span>
        <span>{`Outbound: ${outboundCapacity.displayAsSats()}`}</span>
      </div>
    </div>
  );
};

export default LiquidityDisplay;
