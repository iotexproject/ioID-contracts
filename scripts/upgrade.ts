import { ethers, upgrades } from 'hardhat';

async function main() {
  if (!process.env.IOID_FACTORY) {
    console.log(`Please provide ioIDFactory address`);
    return;
  }

  const ioIDFactory = await ethers.getContractFactory('ioIDFactory');
  await upgrades.upgradeProxy(process.env.IOID_FACTORY, ioIDFactory, {});
  console.log(`Upgrade ioIDFactory ${process.env.IOID_FACTORY} successfull!`);
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
