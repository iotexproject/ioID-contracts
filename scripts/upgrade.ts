import { ethers, upgrades } from 'hardhat';

async function main() {
  if (process.env.IOID_STORE) {
    const ioIDStore = await ethers.getContractFactory('ioIDStore');
    await upgrades.upgradeProxy(process.env.IOID_STORE, ioIDStore, {});
    console.log(`Upgrade ioIDStore ${process.env.IOID_STORE} successfull!`);
  }

  if (process.env.IOID) {
    const ioID = await ethers.getContractFactory('ioID');
    await upgrades.upgradeProxy(process.env.IOID, ioID, {});
    console.log(`Upgrade ioID ${process.env.IOID} successfull!`);
  }

  if (process.env.IOID_REGISTRY) {
    const ioIDRegistry = await ethers.getContractFactory('ioIDRegistry');
    await upgrades.upgradeProxy(process.env.IOID_REGISTRY, ioIDRegistry, {});
    console.log(`Upgrade ioIDRegistry ${process.env.IOID_REGISTRY} successfull!`);
  }
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
