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
  const fundingAmount = channel.our.add(channel.his);
  let totalAmount = hotWalletFee ? fundingAmount.add(hotWalletFee as BitcoinAmount) : fundingAmount;

  const useDefaultFee = channel.network === Network.Regtest && !hotWalletFee;
  if (useDefaultFee) {
    const DEFAULT_REGTEST_FEE = BitcoinAmount.fromBtc(0.0001);
    totalAmount = fundingAmount.add(DEFAULT_REGTEST_FEE);
  }

  return (
    <>
    {(hotWalletFee || useDefaultFee) ? (
      <Text className='text-lg text-center mt-4' text={`Send: ${totalAmount.asBtc()} BTC`} />
    ):(
    <>
      <Text className='text-lg text-center mt-4' text={`Send: ${totalAmount.asBtc()} BTC + fee`} />
      <Text className='text-md text-center !mt-0 mb-2' text={'(Fee estimate unavailable)'} />
    </>
    )}
    <Text className='text-lg text-center text-balance break-all' text={`To: ${tauAddress}`} />
    <QRCode className='col-span-2 mt-4 mb-2 col-start-2 mx-auto' size={150} value={tauAddress} />
    <CopyButton className='w-8/12' label={null} buttonText={'Copy Address'} copyText={tauAddress} />
    {close ? <Button className='!mt-4' onClick={close} label={'Done'}/> : null}
    </>
  );
}

export default HotWalletFunding;
