import BitcoinAmount from "./BitcoinAmount";

export type ChannelId = string;
export type Satoshis = number;
export type Millisatoshis = number;
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

export interface ChannelJson {
  id: ChannelId;
  status: ChannelStatus;
  who: Ship;
  our: number;
  his: number;
}

type Channel = {
  id: ChannelId;
  status: ChannelStatus;
  who: Ship;
  our: BitcoinAmount;
  his: BitcoinAmount;
};

export default Channel;
