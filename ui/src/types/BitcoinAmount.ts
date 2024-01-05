export default class BitcoinAmount {
  static zero(): any {
    throw new Error('Method not implemented.');
  }
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

  add(other: BitcoinAmount): BitcoinAmount {
    const sum = this.millisatoshis + other.millisatoshis;
    return new BitcoinAmount(sum);
  }

  sub(other: BitcoinAmount): BitcoinAmount {
    const difference = this.millisatoshis - other.millisatoshis;
    return new BitcoinAmount(difference);
  }

  eq(other: BitcoinAmount): boolean {
    return this.millisatoshis === other.millisatoshis;
  }

  asBtc(): number {
    return this.millisatoshis / 100000000;
  }

  asSats(): number {
    return this.millisatoshis / 1000;
  }

  displayAsMsats(): string {
    return `${this.millisatoshis} msats`;
  }

  displayAsSats(): string {
    const satoshis = this.millisatoshis / 1000;
    return `${satoshis} satoshis`;
  }

  displayAsBtc(): string {
    const btc = this.millisatoshis / 100000000;
    return `${btc} BTC`;
  }
}
