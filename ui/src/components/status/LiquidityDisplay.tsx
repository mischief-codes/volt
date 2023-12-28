import React, { useContext } from 'react';
import { ChannelContext } from '../../contexts/ChannelContext';


const LiquidityDisplay: React.FC = () => {
  const { inboundCapacitySats, outboundCapacitySats } = useContext(ChannelContext)

  return (
    <div className='px-10'>
      <h1 className='pb-6 text-lg text-center'>Liquidity</h1>
      <div className='flex justify-between'>
        <span>{`Inbound: ${inboundCapacitySats} sat.`}</span>
        <span>{`Outbound: ${outboundCapacitySats} sat.`}</span>
      </div>
    </div>
  );
};

export default LiquidityDisplay;
