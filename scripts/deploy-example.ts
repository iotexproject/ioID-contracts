import { ethers } from 'hardhat';

async function main() {
  if (!process.env.PROJECT_REGISTRY) {
    console.log(`Please provide project registrar address`);
    return;
  }
  if (!process.env.IOID_STORE) {
    console.log(`Please provide ioIDStore address`);
    return;
  }
  const [deployer] = await ethers.getSigners();

  const projectRegistry = await ethers.getContractAt('ProjectRegistry', process.env.PROJECT_REGISTRY);
  let tx = await projectRegistry.register();
  const receipt = await tx.wait();
  let projectId;
  for (let i = 0; i < receipt!.logs.length; i++) {
    const log = receipt!.logs[i];
    if (log.topics[0] == '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef') {
      projectId = BigInt(log.topics[3]);
    }
  }

  const deviceNFT = await ethers.deployContract('DeviceNFT');
  await deviceNFT.waitForDeployment();
  tx = await deviceNFT.configureMinter(deployer, 100);
  await tx.wait();
  console.log(`Device NFT deployed to ${deviceNFT.target}`);

  const ioIDStore = await ethers.getContractAt('ioIDStore', process.env.IOID_STORE);
  const price = await ioIDStore.price();
  tx = await ioIDStore.applyIoIDs(projectId, 100, { value: 100n * price });
  await tx.wait();
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
