import React, { useContext, useMemo } from 'react';
import { ChannelContext } from '../../contexts/ChannelContext';
import Channel, { ChannelStatus } from '../../types/Channel';

const ChannelDisplay: React.FC = () => {
  const { channelsByStatus, channels } = useContext(ChannelContext);

  const getStatusSortPriority = (status: ChannelStatus) => {
    switch (status) {
      case ChannelStatus.Open:
        return 9;
      case ChannelStatus.ForceClosing:
        return 8;
      case ChannelStatus.Closing:
        return 7;
      case ChannelStatus.Shutdown:
        return 6;
      case ChannelStatus.Funded:
        return 5;
      case ChannelStatus.Opening:
        return 4;
      case ChannelStatus.Preopening:
        return 3;
      case ChannelStatus.Closed:
        return 2;
      case ChannelStatus.Redeemed:
        return 1;
    }
  }

  const compareChannels = (a: Channel, b: Channel) => {
    // Group by status
    if (a.status !== b.status) {
      return getStatusSortPriority(a.status) - getStatusSortPriority(b.status);
    }
    // Order within status by liquidity
    const aLiquidity = a.our.add(a.his);
    const bLiquidity = b.our.add(b.his);
    if (aLiquidity.gt(bLiquidity)) {
      return -1;
    } else if (bLiquidity.gt(aLiquidity)) {
      return 1;
    // Order by channel partner ship as fallback
    } else if (a.who !== b.who) {
      return a.who.localeCompare(b.who);
    // Order by channel id as fallback
    } else {{
      return a.id.localeCompare(b.id);
    }}
  }

  const notOpenChannels = useMemo(() => {
   return channels
    .filter((channel) => channel.status !== ChannelStatus.Open)
    .sort(compareChannels)
  }, [channels]);

  const openChannels = useMemo(() => {
    return channelsByStatus.open.sort(compareChannels)
  }, [channelsByStatus]);

  const headerClassnames = 'text-center font-normal w-1/4';
  const rowClassnames = 'text-center text-gray-500 font-normal w-1/4';
  const closedRowClassnames = 'text-center font-normal text-gray-400 w-1/4';

  return (
    <>
    <h1 className='text-lg pb-8 text-center'>Channels</h1>
    <div className='w-full h-4/5 overflow-y-scroll px-2'>
      {channels.length === 0 ?
        <h2 className='text-center self-center text-gray-400'>No channels found</h2>
        : (
      <div className='block'>
        <table className='w-full'>
          <thead className='sticky top-0 bg-zinc-300'>
            <tr>
              <th className={headerClassnames}>Partner</th>
              <th className={headerClassnames}>Ours</th>
              <th className={headerClassnames}>Theirs</th>
              <th className={headerClassnames}>Status</th>
            </tr>
          </thead>
          <tbody className='h-24 overflow-y-scroll'>
            {openChannels.map((channel) => (
              <tr key={channel.id}>
                <td className={rowClassnames}>~{channel.who}</td>
                <td className={rowClassnames}>{channel.our.displayAsSats()}</td>
                <td className={rowClassnames}>{channel.his.displayAsSats()}</td>
                <td className={rowClassnames}>{channel.status.toUpperCase()}</td>

              </tr>
            ))}
            {notOpenChannels.map((channel) => (
              <tr key={channel.id}>
                <td className={closedRowClassnames}>~{channel.who}</td>
                <td className={closedRowClassnames}>{channel.our.displayAsSats()}</td>
                <td className={closedRowClassnames}>{channel.his.displayAsSats()}</td>
                <td className={closedRowClassnames}>{channel.status.toUpperCase()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      )}
    </div>
    </>
  );
};

  export default ChannelDisplay;
