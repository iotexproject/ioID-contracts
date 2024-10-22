import { artifacts, ethers } from 'hardhat';
import { TokenboundClient } from '@tokenbound/sdk';
import { IoID, IoIDRegistry } from '../typechain-types';

const SortedTroves = artifacts.require('SortedTroves');

async function main() {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId.toString());
  const owner = new ethers.Wallet(process.env.PRIVATE_KEY!, ethers.provider);
  console.log(`owner: ${owner.address}`);

  const deviceNFTFactory = await ethers.getContractFactory('DeviceNFT');
  const deviceGaugeFactory = await ethers.getContractFactory('DummyDeviceGauge');
  const deviceGauge = deviceGaugeFactory.attach('0x6af1F299aa518423F469D5e89b4FBb2B81d89a5B');
  const ioIDRegistryFactory = await ethers.getContractFactory('ioIDRegistry');
  const ioIDRegistry = ioIDRegistryFactory.attach('0x04e4655Cf258EC802D17c23ec6112Ef7d97Fa2aF') as IoIDRegistry;
  const ioIDFactory = await ethers.getContractFactory('ioID');
  const ioID = ioIDFactory.attach('0x1FCB980eD0287777ab05ADc93012332e11300e54') as IoID;

  // @ts-ignore
  const tokenboundClient = new TokenboundClient({
    chain: {
      id: chainId,
      name: 'IoTeX Testnet',
      network: 'mainnet',
      rpcUrls: {
        default: {
          http: ['https://babel-api.mainnet.iotex.io'],
        },
        public: {
          http: ['https://babel-api.mainnet.iotex.io'],
        },
      },
      nativeCurrency: {
        name: 'IoTeX',
        symbol: 'IOTX',
        decimals: 18,
      },
    },
    // registryAddress: '0x000000006551c19487814612e58FE06813775758',
    // implementationAddress: '0x1d1C779932271e9Dc683d5373E84Fa4239F2b3fb',
    signer: owner,
  });

  const did = await ioIDRegistry.documentID('0xdCD0a79a5A2bdC1392B31573dA3B960985E98dcb');
  const wallet = await ioID['wallet(string)'](did);
  const approveCall = await tokenboundClient.execute({
    account: wallet,
    to: '0xB31d7d8950C490F316A0A553b141994249Be4012',
    value: BigInt(0),
    data: deviceNFTFactory.interface.encodeFunctionData('approve', [deviceGauge.target, 1]),
  });
  console.log(`${wallet} approve txHash: ${approveCall}`);
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
