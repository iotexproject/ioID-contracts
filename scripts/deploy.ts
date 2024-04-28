import { ethers, upgrades } from 'hardhat';

async function main() {
  if (!process.env.PROJECT) {
    console.log(`Please provide project address`);
    return;
  }
  if (!process.env.WALLET_REGISTRY) {
    console.log(`Please provide wallet registry address`);
    return;
  }
  if (!process.env.WALLET_IMPLEMENTATION) {
    console.log(`Please provide wallet implementation`);
    return;
  }

  const [deployer] = await ethers.getSigners();

  const ioIDFactory = await upgrades.deployProxy(
    await ethers.getContractFactory('ioIDFactory'),
    [process.env.PROJECT],
    {
      initializer: 'initialize',
    },
  );
  await ioIDFactory.waitForDeployment();
  console.log(`ioIDFactory deployed to ${ioIDFactory.target}`);

  const ioID = await upgrades.deployProxy(
    await ethers.getContractFactory('ioID'),
    [deployer.address, process.env.WALLET_REGISTRY, process.env.WALLET_IMPLEMENTATION, 'ioID device NFT', 'IDN'],
    {
      initializer: 'initialize',
    },
  );
  await ioID.waitForDeployment();
  console.log(`ioID deployed to ${ioID.target}`);

  const ioIDRegistry = await upgrades.deployProxy(
    await ethers.getContractFactory('ioIDRegistry'),
    [ioIDFactory.target, ioID.target],
    {
      initializer: 'initialize',
    },
  );
  console.log(`ioIDRegistry deployed to ${ioIDRegistry.target}`);

  console.log(`Set ioIDFactory ioIDRegistry to ${ioIDRegistry.target}`);
  let tx = await ioIDFactory.setIoIDRegistry(ioIDRegistry.target);
  await tx.wait();

  console.log(`Set ioID minter to ${ioIDRegistry.target}`);
  tx = await ioID.setMinter(ioIDRegistry.target);
  await tx.wait();
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
