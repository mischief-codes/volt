export type ChannelId = string;
export type Satoshis = number;
export type Ship = string;

export enum ChannelStatus {
  Preopening = 'preopening',
  Opening = 'opening',
  Funded = 'funded',
  Open = 'open',
  Shutdown = 'shutdown',
  Closing = 'closing',
  ForceClosing = 'force-closing',
  Closed = 'closed',
  Redeemed = 'redeemed',
}

type Channel = {
  id: ChannelId;
  status: ChannelStatus;
  who: Ship;
  our: Satoshis;
  his: Satoshis;
};

export default Channel;
