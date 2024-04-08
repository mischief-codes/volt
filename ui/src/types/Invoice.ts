import BitcoinAmount from "./BitcoinAmount";

type Invoice = {
  amount: BitcoinAmount;
  payreq: string;
}

export default Invoice;
