import { expect } from 'chai';
import { ethers } from 'hardhat';
import { IoID, IoIDStore, IoIDRegistry, PebbleProxy } from '../typechain-types';
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';
import { Signer, getBytes, keccak256, solidityPacked } from 'ethers';
import { TokenboundClient } from '@tokenbound/sdk';

describe('ioID pebble tests', function () {
  let deployer, owner: HardhatEthersSigner;
  let verifier: Signer;
  let pebbleProxy: PebbleProxy;
  let ioIDStore: IoIDStore;
  let ioID: IoID;
  let ioIDRegistry: IoIDRegistry;

  before(async () => {
    [deployer, owner] = await ethers.getSigners();
    verifier = ethers.Wallet.createRandom();

    const project = await ethers.deployContract('Project');
    await project.initialize('ioID Project', 'IPN');
    const projectRegistry = await ethers.deployContract('ProjectRegistry');
    await projectRegistry.initialize(project.target);
    await project.setMinter(projectRegistry.target);

    ioIDStore = await ethers.deployContract('ioIDStore');
    await ioIDStore.initialize(project.target, ethers.parseEther('1.0'));

    ioID = await ethers.deployContract('ioID');
    await ioID.initialize(
      deployer.address, // minter
      '0x000000006551c19487814612e58FE06813775758', // wallet registry
      '0x1d1C779932271e9Dc683d5373E84Fa4239F2b3fb', // wallet implementation
      'ioID',
      'ioID',
    );

    ioIDRegistry = await ethers.deployContract('ioIDRegistry');
    await ioIDRegistry.initialize(ioIDStore.target, ioID.target);

    await ioIDStore.setIoIDRegistry(ioIDRegistry.target);
    await ioID.setMinter(ioIDRegistry.target);

    pebbleProxy = await ethers.deployContract('PebbleProxy', [ioIDStore.target, projectRegistry.target]);
    await pebbleProxy.initialize(verifier.getAddress(), 'Pebble', 'Pebble Device NFT', 'PNFT', 10, {
      value: ethers.parseEther('1.0') * BigInt(10),
    });
  });

  it('regsiter', async () => {
    const device = ethers.Wallet.createRandom();
    const domain = {
      name: 'ioIDRegistry',
      version: '1',
      chainId: 4690,
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
    const signature = await device.signTypedData(domain, types, { owner: pebbleProxy.target, nonce: nonce });
    const r = signature.substring(0, 66);
    const s = '0x' + signature.substring(66, 130);
    const v = '0x' + signature.substring(130);

    const projectId = await pebbleProxy.projectId();
    const imei = 'test imei';

    // TODO: request verify service with: chainid, imei, sn, owner, device
    const verifyMessage = solidityPacked(
      ['uint256', 'string', 'address', 'address'],
      [4690, imei, owner.address, device.address],
    );
    const verifySignature = await verifier.signMessage(getBytes(verifyMessage));

    expect(await ioID.projectDeviceCount(projectId)).to.equal(0);
    await pebbleProxy.register(
      imei,
      verifySignature,
      keccak256('0x'), // did hash
      'http://resolver.did', // did document uri
      owner.address, // owner
      device.address, // device
      v,
      r,
      s,
    );

    const did = await ioIDRegistry.documentID(device.address);

    expect(await ioID.deviceProject(device.address)).to.equal(projectId);
    expect(await ioID.projectDeviceCount(projectId)).to.equal(1);

    const ids = await ioID.projectIDs(projectId, '0x0000000000000000000000000000000000000001', 10);
    expect(ids.array.length).to.equal(1);
    expect(ids.array[0]).to.equal(device.address);
    expect(ids.next).to.equal('0x0000000000000000000000000000000000000000');

    const wallet = await ioID['wallet(string)'](did);
    expect((await ethers.provider.getCode(wallet)).length).to.gt(0);

    expect(await ethers.provider.getBalance(wallet)).to.equal(0);
    // @ts-ignore
    await deployer.sendTransaction({
      to: wallet,
      value: ethers.parseEther('1.0'),
    });
    expect(await ethers.provider.getBalance(wallet)).to.equal(ethers.parseEther('1.0'));

    // @ts-ignore
    const tokenboundClient = new TokenboundClient({
      chain: {
        id: 4690,
        name: 'IoTeX Testnet',
        network: 'testnet',
        rpcUrls: {
          default: {
            http: ['http://127.0.0.1:8545'],
          },
          public: {
            http: ['http://127.0.0.1:8545'],
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
    const executedCall = await tokenboundClient.transferETH({
      account: wallet,
      recipientAddress: deployer.address,
      amount: 0.8,
    });
    console.log(`${wallet} transfer tx: ${executedCall}`);
    expect(await ethers.provider.getBalance(wallet)).to.equal(ethers.parseEther('0.2'));
  });
});
