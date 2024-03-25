import BitcoinAmount from "./BitcoinAmount";

export type BitcoinAddress = string;
export type FundingAddress = BitcoinAddress;
export type TauAddress = BitcoinAddress;
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
  who: Ship;
  our: number;
  his: number;
  status: ChannelStatus;
}

type Channel = {
  id: ChannelId;
  who: Ship;
  our: BitcoinAmount;
  his: BitcoinAmount;
  status: ChannelStatus;
};

export default Channel;