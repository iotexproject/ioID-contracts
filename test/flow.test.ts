import { expect } from 'chai';
import { ethers } from 'hardhat';
import { IoID, IoIDStore, IoIDRegistry, IDONFT } from '../typechain-types';
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';
import { keccak256 } from 'ethers';
import { TokenboundClient } from '@tokenbound/sdk';

describe('ioID tests', function () {
  let deployer, projectOwner, owner: HardhatEthersSigner;
  let ioIDStore: IoIDStore;
  let ioID: IoID;
  let ioIDRegistry: IoIDRegistry;
  let projectId: bigint;
  let idoNFT: IDONFT;
  let idoNFTId: bigint;

  before(async () => {
    [deployer, projectOwner, owner] = await ethers.getSigners();

    const project = await ethers.deployContract('Project');
    await project.initialize('ioID Project', 'IPN');
    const projectRegistry = await ethers.deployContract('ProjectRegistry');
    await projectRegistry.initialize(project.target);
    await project.setMinter(projectRegistry.target);

    const tx = await projectRegistry.connect(projectOwner).register();
    const receipt = await tx.wait();
    for (let i = 0; i < receipt!.logs.length; i++) {
      const log = receipt!.logs[i];
      if (
        log.topics[0] == '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
      ) {
        projectId = BigInt(log.topics[3]);
      }
    }

    idoNFT = await ethers.deployContract('IDONFT');
    await idoNFT.configureMinter(deployer, 100);
    idoNFT.mint(owner.address);
    idoNFTId = 1n;

    ioIDStore = await ethers.deployContract('ioIDStore');
    await ioIDStore.initialize(project.target);
    await ioIDStore.changePrice(ethers.parseEther('1.0'));
    await ioIDStore
      .connect(projectOwner)
      .applyIoIDs(projectId, idoNFT.target, 100, { value: 100n * ethers.parseEther('1.0') });

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
    const signature = await device.signTypedData(domain, types, { owner: owner.address, nonce: nonce });
    const r = signature.substring(0, 66);
    const s = '0x' + signature.substring(66, 130);
    const v = '0x' + signature.substring(130);

    await ioIDRegistry
      .connect(owner)
      .register(idoNFT.target, idoNFTId, device.address, keccak256('0x'), 'http://resolver.did', v, r, s);
    const did = await ioIDRegistry.documentID(device.address);

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
