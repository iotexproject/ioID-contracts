import { ethers, upgrades } from 'hardhat';

async function main() {
  if (process.env.PROJECT) {
    console.log(`upgrade project`);
    const Project = await ethers.getContractFactory('Project');
    await upgrades.forceImport(process.env.PROJECT, Project);
    await upgrades.upgradeProxy(process.env.PROJECT, Project, {
      redeployImplementation: 'always',
    });
    console.log(`Upgrade Project ${process.env.PROJECT} successfull!`);
  }

  if (process.env.PROJECT_REGISTRY) {
    console.log(`upgrade project registry`);
    const ProjectRegistry = await ethers.getContractFactory('ProjectRegistry');
    await upgrades.forceImport(process.env.PROJECT_REGISTRY, ProjectRegistry);
    await upgrades.upgradeProxy(process.env.PROJECT_REGISTRY, ProjectRegistry, {
      redeployImplementation: 'always',
    });
    console.log(`Upgrade ProjectRegistry ${process.env.PROJECT_REGISTRY} successfull!`);
  }

  if (process.env.IOID_STORE) {
    console.log(`upgrade ioID store`);
    const ioIDStore = await ethers.getContractFactory('ioIDStore');
    await upgrades.forceImport(process.env.IOID_STORE, ioIDStore);
    await upgrades.upgradeProxy(process.env.IOID_STORE, ioIDStore, {
      redeployImplementation: 'always',
    });
    console.log(`Upgrade ioIDStore ${process.env.IOID_STORE} successfull!`);
  }

  if (process.env.IOID) {
    console.log(`upgrade ioID`);
    const ioID = await ethers.getContractFactory('ioID');
    await upgrades.upgradeProxy(process.env.IOID, ioID, {});
    console.log(`Upgrade ioID ${process.env.IOID} successfull!`);
  }

  if (process.env.IOID_REGISTRY) {
    console.log(`upgrade ioID Registry`);
    const ioIDRegistry = await ethers.getContractFactory('ioIDRegistry');
    await upgrades.forceImport(process.env.IOID_REGISTRY, ioIDRegistry);
    await upgrades.upgradeProxy(process.env.IOID_REGISTRY, ioIDRegistry, {
      redeployImplementation: 'always',
    });
    console.log(`Upgrade ioIDRegistry ${process.env.IOID_REGISTRY} successfull!`);
  }
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
