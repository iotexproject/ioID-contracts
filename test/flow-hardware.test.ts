import { expect } from 'chai';
import { ethers } from 'hardhat';
import { IoID, IoIDStore, IoIDRegistry, VerifyingProxy, DummyDeviceGauge } from '../typechain-types';
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';
import { Signer, getBytes, keccak256, solidityPacked } from 'ethers';
import { TokenboundClient } from '@tokenbound/sdk';
import { DeviceNFT } from '../typechain-types/contracts/DeviceNFT.sol';

describe('ioID pebble tests', function () {
  let deployer, owner: HardhatEthersSigner;
  let chainId: number;
  let verifier: Signer;
  let proxy: VerifyingProxy;
  let ioIDStore: IoIDStore;
  let ioID: IoID;
  let ioIDRegistry: IoIDRegistry;
  let deviceNFT: DeviceNFT;
  let deviceGauge: DummyDeviceGauge;

  before(async () => {
    [deployer, owner] = await ethers.getSigners();

    verifier = ethers.Wallet.createRandom();

    const network = await ethers.provider.getNetwork();

    chainId = Number(network.chainId.toString());

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
      '0x41C8f39463A868d3A88af00cd0fe7102F30E44eC', // wallet implementation
      'ioID',
      'ioID',
    );

    ioIDRegistry = await ethers.deployContract('ioIDRegistry');
    await ioIDRegistry.initialize(ioIDStore.target, ioID.target);

    await ioIDStore.setIoIDRegistry(ioIDRegistry.target);
    await ioID.setMinter(ioIDRegistry.target);

    const deviceNFTImplementation = await ethers.deployContract('DeviceNFT');
    const proxyImplementation = await ethers.deployContract('VerifyingProxy', [
      ioIDStore.target,
      projectRegistry.target,
      deviceNFTImplementation.target,
    ]);

    const verifyingProxyFactory = await ethers.getContractFactory('VerifyingProxy');
    const factory = await ethers.deployContract('UniversalFactory', [proxyImplementation.target]);
    const tx = await factory.create(0, verifier.getAddress(), 'Pebble', 'Pebble Device NFT', 'PNFT', 10, {
      value: ethers.parseEther('1.0') * BigInt(10),
    });
    const receipt = await tx.wait();
    for (let i = 0; i < receipt!.logs.length; i++) {
      const log = receipt!.logs[i];
      if (log.topics[0] == '0x944661ed150e69c33316bf899f80879602cc18929538a726d96c30bd7c9a7fc8') {
        proxy = verifyingProxyFactory.attach(log.args[0]) as VerifyingProxy;
      }
    }

    const deviceNFTAddr = await proxy.deviceNFT();
    const deviceNFTFactory = await ethers.getContractFactory('DeviceNFT');
    deviceNFT = deviceNFTFactory.attach(deviceNFTAddr) as DeviceNFT;
    deviceGauge = await ethers.deployContract('DummyDeviceGauge', [deviceNFT]);

    await proxy.setDeviceGauge(deviceGauge.target);
  });

  it('regsiter', async () => {
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
    const signature = await device.signTypedData(domain, types, { owner: proxy.target, nonce: nonce });
    const r = signature.substring(0, 66);
    const s = '0x' + signature.substring(66, 130);
    const v = '0x' + signature.substring(130);

    const projectId = await proxy.projectId();

    // request verify service with: chainid, owner, device
    const verifyMessage = solidityPacked(['uint256', 'address', 'address'], [chainId, owner.address, device.address]);
    const verifySignature = await verifier.signMessage(getBytes(verifyMessage));

    expect(await ioID.projectDeviceCount(projectId)).to.equal(0);
    await proxy.register(
      verifySignature,
      keccak256('0x'), // did hash
      'http://resolver.did', // did document uri
      owner.address, // owner
      device.address, // device
      v,
      r,
      s,
    );

    expect(await deviceNFT.ownerOf(1)).to.equal(deviceGauge.target);

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
        id: chainId,
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
