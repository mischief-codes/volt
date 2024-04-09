import { useContext } from "react";
import Channel, { TauAddress } from "../../../types/Channel";
import { HotWalletContext } from "../../../contexts/HotWalletContext";
import BitcoinAmount from "../../../types/BitcoinAmount";
import React from "react";
import QRCode from "react-qr-code";
import Network from "../../../types/Network";
import Button from "./Button";
import CopyButton from "./CopyButton";
import Text from "./Text";

const HotWalletFunding = ({channel, tauAddress, close}:
  {channel: Channel, tauAddress: TauAddress, close: null | (() => void)}
) => {
  const { hotWalletFee } = useContext(HotWalletContext);
  let totalAmount = hotWalletFee ? channel.our.add(hotWalletFee as BitcoinAmount) : null;
  if (channel.network === Network.Regtest && !hotWalletFee) {
    const DEFAULT_REGTEST_FEE = BitcoinAmount.fromBtc(0.0001);
    totalAmount = channel.our.add(DEFAULT_REGTEST_FEE);
  }
  return (
    <>
    {totalAmount ? (
      <Text className='text-lg text-start mt-4' text={`Send: ${totalAmount?.asBtc()} BTC`} />
    ):(
    <>
      <Text className='text-lg text-start mt-4' text={`Send: ${channel.our.asBtc()} BTC + fee`} />
      <Text className='text-lg text-start mt-4' text={'(Fee estimate unavailable)'} />
    </>
    )}
    <Text className='text-lg text-start text-balance break-all' text={`To: ${tauAddress}`} />
    <QRCode className='col-span-2 mt-4 mb-2 col-start-2 mx-auto' size={150} value={tauAddress} />
    <CopyButton className='w-8/12' label={null} buttonText={'Copy Address'} copyText={tauAddress} />
    {close ? <Button className='!mt-4' onClick={close} label={'Done'}/> : null}
    </>
  );
}

export default HotWalletFunding;
