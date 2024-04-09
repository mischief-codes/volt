const MSAT_PER_SAT = 1000;
const SAT_PER_BTC = 100000000;
const MSAT_PER_BTC = MSAT_PER_SAT * SAT_PER_BTC;

export default class BitcoinAmount {
  readonly millisatoshis: number;

  constructor(millisatoshis: number) {
    if (
      !Number.isInteger(millisatoshis) ||
      millisatoshis < 0 ||
      millisatoshis > Number.MAX_SAFE_INTEGER
    ) {
      throw new Error('Invalid value for millisatoshis');
    }
    this.millisatoshis = millisatoshis;
  }

  static fromSatoshis(satoshis: number): BitcoinAmount {
    const millisatoshis = satoshis * MSAT_PER_SAT;
    return new BitcoinAmount(millisatoshis);
  }

  static fromBtc(btc: number): BitcoinAmount {
    const millisatoshis = btc * MSAT_PER_BTC;
    return new BitcoinAmount(millisatoshis);
  }

  add(other: BitcoinAmount): BitcoinAmount {
    const sum = this.millisatoshis + other.millisatoshis;
    return new BitcoinAmount(sum);
  }

  sub(other: BitcoinAmount): BitcoinAmount {
    if (this.millisatoshis < other.millisatoshis) {
      throw new Error('Subtraction would result in negative value');
    }
    return new BitcoinAmount(this.millisatoshis - other.millisatoshis);
  }

  eq(other: BitcoinAmount): boolean {
    return this.millisatoshis === other.millisatoshis;
  }

  gt(other: BitcoinAmount): boolean {
    return this.millisatoshis > other.millisatoshis;
  }

  asBtc(): number {
    return this.millisatoshis / MSAT_PER_BTC;
  }

  asSats(): number {
    return this.millisatoshis / MSAT_PER_SAT;
  }

  displayAsMsats(): string {
    return `${this.millisatoshis} msat.`;
  }

  displayAsSats(): string {
    const satoshis = this.millisatoshis / MSAT_PER_SAT;
    return `${satoshis} sat.`;
  }

  displayAsBtc(): string {
    const btc = this.millisatoshis / MSAT_PER_BTC;
    return `${btc} BTC`;
  }
}

const MIN_FUNDING_SATS = 200000;
export const MIN_FUNDING_AMOUNT = new BitcoinAmount(MIN_FUNDING_SATS * MSAT_PER_SAT);
