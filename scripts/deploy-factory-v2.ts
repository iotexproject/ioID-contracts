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

  const deviceNFTImplementation = await ethers.deployContract('DeviceNFT');
  await deviceNFTImplementation.waitForDeployment();
  const proxyImplementation = await ethers.deployContract('VerifyingProxyV2', [
    process.env.IOID_STORE,
    process.env.PROJECT_REGISTRY,
    deviceNFTImplementation.target,
  ]);
  await proxyImplementation.waitForDeployment();

  const factory = await ethers.deployContract('UniversalFactoryV2', [proxyImplementation.target]);
  await factory.waitForDeployment();
  console.log(`UniversalFactoryV2 deployed to ${factory.target}`);
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
