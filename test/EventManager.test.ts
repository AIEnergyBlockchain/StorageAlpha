import { expect } from "chai";
import { ethers } from "hardhat";
import { EventManager } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("EventManager", function () {
  let eventManager: EventManager;
  let operator: SignerWithAddress;
  let other: SignerWithAddress;

  const eventId = ethers.id("event-001");
  const start = 1700000000n;
  const end = 1700003600n;
  const targetKw = 300n;
  const rewardRate = 10n;
  const penaltyRate = 5n;

  beforeEach(async function () {
    [operator, other] = await ethers.getSigners();
    const factory = await ethers.getContractFactory("EventManager");
    eventManager = await factory.deploy(operator.address);
  });

  it("creates an event successfully", async function () {
    await expect(
      eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate)
    )
      .to.emit(eventManager, "EventCreated")
      .withArgs(eventId, start, end, targetKw);

    const ev = await eventManager.getEventInfo(eventId);
    expect(ev.targetKw).to.equal(targetKw);
    expect(ev.status).to.equal(1);
  });

  it("reverts when non-operator creates an event", async function () {
    await expect(
      eventManager
        .connect(other)
        .createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate)
    ).to.be.revertedWith("Not operator");
  });

  it("closes an active event", async function () {
    await eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate);

    await expect(eventManager.closeEvent(eventId))
      .to.emit(eventManager, "EventClosed")
      .withArgs(eventId);

    const ev = await eventManager.getEventInfo(eventId);
    expect(ev.status).to.equal(2);
  });

  it("reverts on duplicate eventId", async function () {
    await eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate);

    await expect(
      eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate)
    ).to.be.revertedWith("Event already exists");
  });

  it("reverts on invalid time window", async function () {
    await expect(
      eventManager.createEvent(eventId, end, start, targetKw, rewardRate, penaltyRate)
    ).to.be.revertedWith("Invalid time window");
  });

  it("allows operator to mark closed event as settled", async function () {
    await eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate);
    await eventManager.closeEvent(eventId);

    await expect(eventManager.markSettled(eventId))
      .to.emit(eventManager, "EventSettled")
      .withArgs(eventId);

    const ev = await eventManager.getEventInfo(eventId);
    expect(ev.status).to.equal(3);
  });

  it("blocks non-operator/non-settlement from markSettled", async function () {
    await eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate);
    await eventManager.closeEvent(eventId);

    await expect(
      eventManager.connect(other).markSettled(eventId)
    ).to.be.revertedWith("Not settlement/operator");
  });

  it("requires closed status before settled", async function () {
    await eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate);

    await expect(eventManager.markSettled(eventId)).to.be.revertedWith(
      "Must be closed first"
    );
  });

  it("sets settlement contract only by operator", async function () {
    await expect(
      eventManager.connect(other).setSettlementContract(other.address)
    ).to.be.revertedWith("Not operator");

    await eventManager.setSettlementContract(other.address);
    expect(await eventManager.settlementContract()).to.equal(other.address);
  });
});
