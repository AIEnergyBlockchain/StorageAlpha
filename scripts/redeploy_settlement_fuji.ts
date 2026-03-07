import fs from "node:fs";
import path from "node:path";

import { ethers, network } from "hardhat";

const DEFAULT_DEPLOY_OUT = "cache/fuji-deployment-latest.json";
const DEFAULT_DRT_DEPLOY_OUT = "cache/fuji-drt-deployment-latest.json";

function mustAddress(value: unknown, field: string): string {
  const text = String(value || "").trim();
  if (!text || !ethers.isAddress(text)) {
    throw new Error(`Invalid or missing address: ${field}`);
  }
  return text;
}

function readDeploymentReport(reportPath: string): Record<string, unknown> {
  if (!fs.existsSync(reportPath)) {
    throw new Error(`Deployment report not found: ${reportPath}`);
  }
  return JSON.parse(fs.readFileSync(reportPath, "utf-8")) as Record<string, unknown>;
}

function resolveDrtAddress(baseContracts: Record<string, unknown>): string {
  const direct = String(baseContracts.drt_token || "").trim();
  if (direct && ethers.isAddress(direct)) {
    return direct;
  }

  const drtReportPath = path.resolve(process.env.DR_DRT_DEPLOY_OUT || DEFAULT_DRT_DEPLOY_OUT);
  const drtReport = readDeploymentReport(drtReportPath);
  const drtContracts = (drtReport.contracts || {}) as Record<string, unknown>;
  const fallback = String(drtContracts.drt_token || "").trim();
  if (fallback && ethers.isAddress(fallback)) {
    console.log("[settlement-redeploy] fallback drt_token from:", drtReportPath);
    return fallback;
  }
  throw new Error(
    "Invalid or missing address: contracts.drt_token (also not found in cache/fuji-drt-deployment-latest.json)"
  );
}

async function main(): Promise<void> {
  if (network.name !== "fuji") {
    throw new Error(`This script is for fuji network only. Current: ${network.name}`);
  }

  if (!process.env.PRIVATE_KEY) {
    throw new Error(
      "PRIVATE_KEY is required for Fuji settlement redeploy. Run `npm run deploy:fuji:settlement` with secrets configured."
    );
  }

  const deployOut = process.env.DR_DEPLOY_OUT || DEFAULT_DEPLOY_OUT;
  const reportPath = path.resolve(deployOut);
  const report = readDeploymentReport(reportPath);
  const contracts = (report.contracts || {}) as Record<string, unknown>;

  const eventManagerAddr = mustAddress(contracts.event_manager, "contracts.event_manager");
  const proofRegistryAddr = mustAddress(contracts.proof_registry, "contracts.proof_registry");
  const drtAddr = resolveDrtAddress(contracts);

  const [deployer] = await ethers.getSigners();
  const chain = await ethers.provider.getNetwork();
  const avaxBalance = await ethers.provider.getBalance(deployer.address);

  console.log("[settlement-redeploy] deployer:", deployer.address);
  console.log("[settlement-redeploy] chainId:", chain.chainId.toString());
  console.log("[settlement-redeploy] balance (wei):", avaxBalance.toString());
  console.log("[settlement-redeploy] using event_manager:", eventManagerAddr);
  console.log("[settlement-redeploy] using proof_registry:", proofRegistryAddr);
  console.log("[settlement-redeploy] using drt_token:", drtAddr);

  const settlementFactory = await ethers.getContractFactory("Settlement");
  const settlement = await settlementFactory.deploy(
    eventManagerAddr,
    proofRegistryAddr,
    deployer.address,
    drtAddr
  );
  const settlementDeployTx = settlement.deploymentTransaction();
  if (!settlementDeployTx) {
    throw new Error("Failed to capture deployment transaction for Settlement");
  }
  await settlement.waitForDeployment();
  const settlementAddr = await settlement.getAddress();
  const settlementDeployReceipt = await settlementDeployTx.wait();

  const eventManager = await ethers.getContractAt("EventManager", eventManagerAddr, deployer);
  const setTx = await eventManager.setSettlementContract(settlementAddr);
  const setReceipt = await setTx.wait();

  const drtToken = await ethers.getContractAt("DRToken", drtAddr, deployer);
  const decimals = Number(await drtToken.decimals());
  const deployerDrtBalanceBefore = await drtToken.balanceOf(deployer.address);

  const fundSpecRaw = (process.env.DRT_FUND_SETTLEMENT_UNITS || "max").trim().toLowerCase();
  let fundAmount: bigint;
  if (fundSpecRaw === "max") {
    fundAmount = deployerDrtBalanceBefore;
  } else {
    fundAmount = ethers.parseUnits(fundSpecRaw, decimals);
  }

  if (fundAmount <= 0n) {
    throw new Error("Funding amount must be > 0. Set DRT_FUND_SETTLEMENT_UNITS or ensure deployer has DRT.");
  }
  if (fundAmount > deployerDrtBalanceBefore) {
    throw new Error(
      `Insufficient deployer DRT balance. requested=${fundAmount.toString()} available=${deployerDrtBalanceBefore.toString()}`
    );
  }

  const fundTx = await drtToken.transfer(settlementAddr, fundAmount);
  const fundReceipt = await fundTx.wait();
  const settlementDrtBalanceAfter = await drtToken.balanceOf(settlementAddr);
  const deployerDrtBalanceAfter = await drtToken.balanceOf(deployer.address);

  const txHashes = ((report.tx_hashes || {}) as Record<string, unknown>) || {};
  const nextReport = {
    ...report,
    deployed_at_utc: new Date().toISOString(),
    network: network.name,
    chain_id: Number(chain.chainId),
    deployer: deployer.address,
    contracts: {
      ...contracts,
      event_manager: eventManagerAddr,
      proof_registry: proofRegistryAddr,
      drt_token: drtAddr,
      settlement: settlementAddr,
    },
    tx_hashes: {
      ...txHashes,
      deploy_settlement: settlementDeployReceipt?.hash ?? settlementDeployTx.hash,
      set_settlement_contract: setReceipt?.hash ?? setTx.hash,
      fund_settlement_drt: fundReceipt?.hash ?? fundTx.hash,
    },
    funding: {
      mode: fundSpecRaw,
      fund_amount_wei: fundAmount.toString(),
      fund_amount_units: ethers.formatUnits(fundAmount, decimals),
      deployer_drt_balance_before_wei: deployerDrtBalanceBefore.toString(),
      deployer_drt_balance_after_wei: deployerDrtBalanceAfter.toString(),
      settlement_drt_balance_after_wei: settlementDrtBalanceAfter.toString(),
    },
  };

  fs.mkdirSync(path.dirname(reportPath), { recursive: true });
  fs.writeFileSync(reportPath, `${JSON.stringify(nextReport, null, 2)}\n`, "utf-8");

  console.log("[settlement-redeploy] updated deployment report:", reportPath);
  console.log("[settlement-redeploy] settlement:", settlementAddr);
  console.log("[settlement-redeploy] fund amount (DRT):", ethers.formatUnits(fundAmount, decimals));
  console.log("[settlement-redeploy] fund tx:", fundReceipt?.hash ?? fundTx.hash);
}

main().catch((err) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error("[settlement-redeploy] failed:", message);
  process.exit(1);
});
