import fs from "node:fs";
import path from "node:path";

import { ethers, network } from "hardhat";

function parsePositiveUnits(name: string, defaultValue: string): string {
  const raw = (process.env[name] ?? defaultValue).trim();
  if (!raw) {
    throw new Error(`${name} must be a non-empty number string`);
  }
  const parsed = ethers.parseUnits(raw, 18);
  if (parsed <= 0n) {
    throw new Error(`${name} must be greater than 0`);
  }
  return raw;
}

async function main(): Promise<void> {
  if (network.name !== "fuji") {
    throw new Error(`This script is for fuji network only. Current: ${network.name}`);
  }

  if (!process.env.PRIVATE_KEY) {
    throw new Error(
      "PRIVATE_KEY is required for fuji deployment. Set it in ~/.config/dr-agent/secrets.env and run `npm run deploy:fuji` (or `make deploy-fuji`)."
    );
  }

  const [deployer] = await ethers.getSigners();
  const chain = await ethers.provider.getNetwork();
  const balance = await ethers.provider.getBalance(deployer.address);

  console.log("[fuji] deployer:", deployer.address);
  console.log("[fuji] chainId:", chain.chainId.toString());
  console.log("[fuji] balance (wei):", balance.toString());

  const eventFactory = await ethers.getContractFactory("EventManager");
  const eventManager = await eventFactory.deploy(deployer.address);
  await eventManager.waitForDeployment();

  const proofFactory = await ethers.getContractFactory("ProofRegistry");
  const proofRegistry = await proofFactory.deploy(await eventManager.getAddress());
  await proofRegistry.waitForDeployment();

  const initialSupplyUnits = parsePositiveUnits("DRT_INITIAL_SUPPLY", "1000000");
  const fundToSettlementUnits = (process.env.DRT_FUND_SETTLEMENT_UNITS ?? "500000").trim().toLowerCase();
  const initialSupply = ethers.parseUnits(initialSupplyUnits, 18);
  const drtFactory = await ethers.getContractFactory("DRToken");
  const drtToken = await drtFactory.deploy(deployer.address, initialSupply);
  await drtToken.waitForDeployment();

  const settlementFactory = await ethers.getContractFactory("Settlement");
  const settlement = await settlementFactory.deploy(
    await eventManager.getAddress(),
    await proofRegistry.getAddress(),
    deployer.address,
    await drtToken.getAddress()
  );
  await settlement.waitForDeployment();

  // Fund Settlement contract with DRT so it can pay out on claim
  const deployerDrtBalanceBefore = await drtToken.balanceOf(deployer.address);
  let fundAmount = 0n;
  if (fundToSettlementUnits === "max") {
    fundAmount = deployerDrtBalanceBefore;
  } else {
    fundAmount = ethers.parseUnits(fundToSettlementUnits, 18);
  }
  if (fundAmount <= 0n) {
    throw new Error("DRT_FUND_SETTLEMENT_UNITS must be > 0 or 'max'");
  }
  if (fundAmount > deployerDrtBalanceBefore) {
    throw new Error(
      `Insufficient deployer DRT for settlement funding. requested=${fundAmount.toString()} available=${deployerDrtBalanceBefore.toString()}`
    );
  }

  const fundTx = await drtToken.transfer(await settlement.getAddress(), fundAmount);
  await fundTx.wait();

  const setTx = await eventManager.setSettlementContract(await settlement.getAddress());
  const setReceipt = await setTx.wait();

  const report = {
    deployed_at_utc: new Date().toISOString(),
    network: network.name,
    chain_id: Number(chain.chainId),
    deployer: deployer.address,
    contracts: {
      drt_token: await drtToken.getAddress(),
      event_manager: await eventManager.getAddress(),
      proof_registry: await proofRegistry.getAddress(),
      settlement: await settlement.getAddress(),
    },
    tx_hashes: {
      fund_settlement_drt: fundTx.hash,
      set_settlement_contract: setReceipt?.hash ?? setTx.hash,
    },
    funding: {
      initial_supply_units: initialSupplyUnits,
      fund_settlement_units: fundToSettlementUnits === "max" ? "max" : fundToSettlementUnits,
      fund_settlement_wei: fundAmount.toString(),
    },
  };

  const outPath = process.env.DR_DEPLOY_OUT || "cache/fuji-deployment-latest.json";
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, `${JSON.stringify(report, null, 2)}\n`, "utf-8");

  console.log("[fuji] deployment report written:", outPath);
  console.log(JSON.stringify(report, null, 2));
}

main().catch((err) => {
  console.error("[fuji] deployment failed:", err.message);
  process.exit(1);
});
