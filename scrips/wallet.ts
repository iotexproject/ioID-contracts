import { ethers } from 'hardhat';
import { TokenboundClient } from '@tokenbound/sdk';

async function main() {
  const [owner] = await ethers.getSigners();

  const deviceNFT = await ethers.getContractAt('DeviceNFT', '0x412489D8C28d722A547dA4E6855455274baAfEB1');

  const wallet = await deviceNFT['wallet(uint256)'](1);

  console.log(`Device walelt is ${wallet.wallet_}, did is ${wallet.did_}`);

  const tx = await owner.sendTransaction({
    to: wallet.wallet_,
    value: ethers.parseEther('1.0'),
  });
  await tx.wait();

  // @ts-ignore
  const tokenboundClient = new TokenboundClient({
    chain: {
      id: 4690,
      name: 'IoTeX Testnet',
      network: 'testnet',
      rpcUrls: {
        default: {
          http: ['https://babel-api.testnet.iotex.io'],
        },
        public: {
          http: ['https://babel-api.testnet.iotex.io'],
        },
      },
      nativeCurrency: {
        name: 'IoTeX',
        symbol: 'IOTX',
        decimals: 18,
      },
    },
    signer: owner,
  });
  const executedCall = await tokenboundClient.transferETH({
    account: wallet.wallet_,
    recipientAddress: owner.address,
    amount: 0.8,
  });
  console.log(`${wallet} transfer tx: ${executedCall}`);
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
