import { UpdateType } from "./Update";

export enum ScryResponseType {
  HotWalletFee = "hot-wallet-fee",
  PayreqAmount = "payreq-amount",
}

export type ScryResponse = {
  type: UpdateType;
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
