import { ethers } from 'hardhat';

async function main() {
  if (!process.env.IOID_STORE) {
    console.log(`Please provide ioIDStore address`);
    return;
  }
  if (!process.env.PROJECT_REGISTRY) {
    console.log(`Please provide project registry address`);
    return;
  }
  const [deployer] = await ethers.getSigners();

  const factory = await ethers.deployContract('UniversalFactory', [
    process.env.IOID_STORE,
    process.env.PROJECT_REGISTRY,
  ]);
  await factory.waitForDeployment();
  console.log(`UniversalFactory deployed to ${factory.target}`);
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
