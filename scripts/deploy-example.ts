import { ethers } from 'hardhat';

async function main() {
  if (!process.env.PROJECT_REGISTRAR) {
    console.log(`Please provide project registrar address`);
    return;
  }
  if (!process.env.IOID_FACTORY) {
    console.log(`Please provide ioIDFactory address`);
    return;
  }
  const [deployer] = await ethers.getSigners();

  const projectRegistrar = await ethers.getContractAt('IProjectRegistrar', process.env.PROJECT_REGISTRAR);
  const fee = await projectRegistrar.registrationFee();
  let tx = await projectRegistrar.register({ value: fee });
  const receipt = await tx.wait();
  let projectId;
  for (let i = 0; i < receipt!.logs.length; i++) {
    const log = receipt!.logs[i];
    if (
      log.topics[0] == '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
    ) {
      projectId = BigInt(log.topics[3]);
    }
  }

  const presaleNFT = await ethers.deployContract('PresaleNFT');
  await presaleNFT.waitForDeployment();
  tx = await presaleNFT.configureMinter(deployer, 100);
  await tx.wait();
  console.log(`PresaleNFT deployed to ${presaleNFT.target}`);

  const ioIDFactory = await ethers.getContractAt('ioIDFactory', process.env.IOID_FACTORY);
  await ioIDFactory
      .applyIoID(projectId, presaleNFT.target, 100, { value: 100n * ethers.parseEther('1.0') });
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
