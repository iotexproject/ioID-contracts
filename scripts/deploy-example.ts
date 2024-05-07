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

  const idoNFT = await ethers.deployContract('IDONFT');
  await idoNFT.waitForDeployment();
  tx = await idoNFT.configureMinter(deployer, 100);
  await tx.wait();
  console.log(`IDO NFT deployed to ${idoNFT.target}`);

  const ioIDStore = await ethers.getContractAt('ioIDStore', process.env.IOID_STORE);
  const price = await ioIDStore.price();
  await ioIDStore.applyIoIDs(projectId, idoNFT.target, 100, { value: 100n * price });
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
