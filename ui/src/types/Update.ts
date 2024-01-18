import { ChannelStatus } from "./Channel";

export enum UpdateType {
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

export type ChanInfo = {
  id: string;
  who: string;
  our: number;
  his: number;
  'funding-address': string | null;
  status: ChannelStatus;
};
