import { ChannelStatus } from "./Channel";
import Network from "./Network";

export enum UpdateType {
  NeedFunding = "need-funding",
  ChannelState = "channel-state",
  TempChanUpgraded = "temp-chan-upgraded",
  NewInvoice = "new-invoice",
  PaymentResult = "payment-result",
  NewChannel = "new-channel",
  InitialState = "initial-state",
  PaymentUpdate = "payment-update",
}

export type Update = {
  type: UpdateType;
  [key: string]: any;
};

export type NeedFundingUpdate = {
  type: UpdateType.ChannelState;
  'funding-info': Array<FundingInfo>
};

export type ChannelStateUpdate = {
  type: UpdateType.ChannelState;
  id: string;
  status: ChannelStatus;
};

export type TempChanUpgradedUpdate = {
  type: UpdateType.TempChanUpgraded;
  id: string;
};

export type NewInvoiceUpdate = {
  type: UpdateType.NewInvoice;
  'payment-request': {
    'amount-msats': number;
    payreq: string;
  };
};

export type NewChannelUpdate = {
  type: UpdateType.NewChannel;
  'chan-info': ChanInfo;
};

export type InitialStateUpdate = {
  type: UpdateType.InitialState;
  chans: Array<ChanInfo>;
  txs: Array<any>;
  invoices: Array<any>;
};

export type PaymentUpdate = {
  type: UpdateType.PaymentUpdate;
};

export type FundingInfo = {
  'temporary-channel-id': string;
  'tau-address': string;
  'funding-address': string;
  'amount-msats': number;
}

export type ChanInfo = {
  id: string;
  who: string;
  our: number;
  his: number;
  status: ChannelStatus;
  network: Network;
};
