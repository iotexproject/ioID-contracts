import { keccak256 } from 'ethers';
import { ethers } from 'hardhat';

async function main() {
  const [owner] = await ethers.getSigners();
  const chainId = (await ethers.provider.getNetwork()).chainId;

  const deviceRegistry = await ethers.getContractAt('DeviceRegistry', '0x8ddb0DDcB2a98D0C4A0502AdD8514Cd734d1AacB');

  const device = ethers.Wallet.createRandom();
  const domain = {
    name: 'DeviceRegistry',
    version: '1',
    chainId: chainId,
    verifyingContract: deviceRegistry.target,
  };
  const types = {
    Permit: [
      { name: 'owner', type: 'address' },
      { name: 'nonce', type: 'uint256' },
    ],
  };

  const nonce = await deviceRegistry.nonces(device.address);
  // @ts-ignore
  const signature = await device.signTypedData(domain, types, { owner: owner.address, nonce: nonce });
  const r = signature.substring(0, 66);
  const s = '0x' + signature.substring(66, 130);
  const v = '0x' + signature.substring(130);

  await deviceRegistry
    .connect(owner)
    .register(device.address, keccak256(`${device.address}`), `http://resolver.did/${device.address}`, v, r, s);
  const did = await deviceRegistry.documentID(device.address);

  console.log(`Registered did is ${did}`);
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
