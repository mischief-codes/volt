import React, { useContext, useMemo } from 'react';
import { ChannelContext } from '../../contexts/ChannelContext';
import Channel, { ChannelStatus } from '../../types/Channel';

interface ChannelDisplayProps {
  // Define the props for the component here
}

const ChannelDisplay: React.FC<ChannelDisplayProps> = (props) => {
  const { channelsByStatus, channels } = useContext(ChannelContext);

  console.log('channelsByStatus', channelsByStatus, channels);

  const sortChannels = (a: Channel, b: Channel) => {
    const channelLiquidityDiff = (b.our + b.his) - (a.our + a.his);
    if (channelLiquidityDiff !== 0) {
      return channelLiquidityDiff;
    } else {
      return a.who.localeCompare(b.who);
    }
  }

  const notOpenChannels = useMemo(() => {
   return channels
    .filter((channel) => channel.status !== ChannelStatus.Open)
    .sort(sortChannels);
  }, [channels]);

  const openChannels = useMemo(() => {
    return channelsByStatus.open.sort(sortChannels)
  }
  , [channelsByStatus]);


  const headerClassnames = 'text-center font-normal w-1/4';
  const rowClassnames = 'text-center text-gray-500 font-normal w-1/4';
  const closedRowClassnames = 'text-center font-normal text-gray-400 w-1/4';

  return (
    <div className='w-full px-2'>
      <h1 className='text-lg pb-6 text-center'>Channels</h1>
      {channels.length === 0 ?
        <h2 className='text-center mt-2'>No channels found</h2>
        : (
      <table className='w-full'>
        <thead>
          <tr>
            <th className={headerClassnames}>Partner</th>
            <th className={headerClassnames}>Ours</th>
            <th className={headerClassnames}>Theirs</th>
            <th className={headerClassnames}>Status</th>
          </tr>
        </thead>
        <tbody>
          {openChannels.map((channel) => (
            <tr key={channel.id}>
              <td className={rowClassnames}>~{channel.who}</td>
              <td className={rowClassnames}>{channel.our} sat.</td>
              <td className={rowClassnames}>{channel.his} sat.</td>
              <td className={rowClassnames}>{channel.status.toUpperCase()}</td>

            </tr>
          ))}
          {notOpenChannels.map((channel) => (
            <tr key={channel.id}>
              <td className={closedRowClassnames}>~{channel.who}</td>
              <td className={closedRowClassnames}>{channel.our} sat.</td>
              <td className={closedRowClassnames}>{channel.his} sat.</td>
              <td className={closedRowClassnames}>{channel.status.toUpperCase()}</td>
            </tr>
          ))}
        </tbody>
      </table>
      )}
    </div>
  );
};

  export default ChannelDisplay;
