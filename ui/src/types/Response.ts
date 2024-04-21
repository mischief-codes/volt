import { ChanInfo } from "./Update";

export enum ScryResponseType {
  HotWalletFee = "hot-wallet-fee",
  PayreqAmount = "payreq-amount",
  ChanState = "chan-state",
}

export type ScryResponse = {
  type: ScryResponseType;
  [key: string]: any;
};

export type HotWalletFeeScryResponse = {
  type: ScryResponseType.HotWalletFee;
  sats: number | null;
};

export type PayreqAmountScryResponse = {
  type: ScryResponseType.PayreqAmount;
  'is-valid': boolean;
  msats: number | null;
};

export type ChanStateScryResponse = {
  type: ScryResponseType.ChanState;
  chans: Array<ChanInfo>;
};
