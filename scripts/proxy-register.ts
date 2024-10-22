import { ethers } from 'hardhat';

import { IoIDRegistry, VerifyingProxy } from '../typechain-types';
import { getBytes, keccak256, solidityPacked } from 'ethers';

async function main() {
  const [verifier] = await ethers.getSigners();
  const owner = ethers.Wallet.createRandom();

  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId.toString());
  const ioIDRegistryFactory = await ethers.getContractFactory('ioIDRegistry');
  const ioIDRegistry = ioIDRegistryFactory.attach('0x04e4655Cf258EC802D17c23ec6112Ef7d97Fa2aF') as IoIDRegistry;
  const verifyingProxyFactory = await ethers.getContractFactory('VerifyingProxy');
  const verifyingProxy = verifyingProxyFactory.attach('0xa5c293471ef44625d9ef079296ff4f223405714d') as VerifyingProxy;

  const device = ethers.Wallet.createRandom();
  const domain = {
    name: 'ioIDRegistry',
    version: '1',
    chainId: chainId,
    verifyingContract: ioIDRegistry.target,
  };
  const types = {
    Permit: [
      { name: 'owner', type: 'address' },
      { name: 'nonce', type: 'uint256' },
    ],
  };

  const nonce = await ioIDRegistry.nonces(device.address);

  // @ts-ignore
  const signature = await device.signTypedData(domain, types, { owner: verifyingProxy.target, nonce: nonce });
  const r = signature.substring(0, 66);
  const s = '0x' + signature.substring(66, 130);
  const v = '0x' + signature.substring(130);

  const projectId = await verifyingProxy.projectId();
  const deviceNFT = await verifyingProxy.deviceNFT();

  const verifyMessage = solidityPacked(['uint256', 'address', 'address'], [chainId, owner.address, device.address]);
  const verifySignature = await verifier.signMessage(getBytes(verifyMessage));

  const tx = await verifyingProxy.register(
    verifySignature,
    keccak256('0x'), // did hash
    'http://resolver.did', // did document uri
    owner.address, // owner
    device.address, // device
    v,
    r,
    s,
  );

  console.log(`divice nft: ${projectId}`);
  console.log(`divice nft: ${deviceNFT}`);
  console.log(`divice address: ${device.address}`);
  console.log(`owner private key: ${owner.privateKey}`);
  console.log(`register device txHash: ${tx.hash}`);
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
