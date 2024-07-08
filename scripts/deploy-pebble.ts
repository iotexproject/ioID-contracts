import { ethers } from 'hardhat';

async function main() {
  if (!process.env.PEBBLE_REGISTRATION) {
    console.log(`Please provide pebble registration address`);
    return;
  }
  if (!process.env.IOID_STORE) {
    console.log(`Please provide ioIDStore address`);
    return;
  }
  if (!process.env.PROJECT_REGISTRY) {
    console.log(`Please provide project registrar address`);
    return;
  }
  const [deployer] = await ethers.getSigners();

  const pebbleProxy = await ethers.deployContract('PebbleProxy', [
    process.env.PEBBLE_REGISTRATION,
    process.env.IOID_STORE,
    process.env.PROJECT_REGISTRY,
  ]);
  await pebbleProxy.waitForDeployment();
  console.log(`Pebble proxy deployed to ${pebbleProxy.target}`);

  const ioIDStore = await ethers.getContractAt('ioIDStore', process.env.IOID_STORE);
  const price = await ioIDStore.price();
  const tx = await pebbleProxy.initialize('Pebble', 'Pebble Device NFT', 'PNFT', 10, {
    value: price * BigInt(10),
  });
  await tx.wait();
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
