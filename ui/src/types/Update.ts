import { ChannelStatus } from "./Channel";

export enum UpdateType {
  NeedFunding = "need-funding",
  ChannelState = "channel-state",
  ReceivedPayment = "received-payment",
  NewInvoice = "new-invoice",
  InvoicePaid = "invoice-paid",
  PaymentResult = "payment-result",
  ChannelDeleted = "channel-deleted",
  NewChannel = "new-channel",
  InitialState = "initial-state",
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

export type ChannelDeletedUpdate = {
  type: UpdateType.ChannelDeleted;
  id: string;
};

export type InitialStateUpdate = {
  type: UpdateType.InitialState;
  chans: Array<ChanInfo>;
  txs: Array<any>;
  invoices: Array<any>;
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
};
