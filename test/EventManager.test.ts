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
  const end = 1700003600n; // +1 hour
  const targetKw = 300n;
  const rewardRate = 10n;
  const penaltyRate = 5n;

  beforeEach(async function () {
    [operator, other] = await ethers.getSigners();
    const factory = await ethers.getContractFactory("EventManager");
    eventManager = await factory.deploy(operator.address);
  });

  it("should create an event successfully", async function () {
    await expect(
      eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate)
    ).to.emit(eventManager, "EventCreated").withArgs(eventId, start, end, targetKw);

    const ev = await eventManager.getEventInfo(eventId);
    expect(ev.targetKw).to.equal(targetKw);
    expect(ev.status).to.equal(1); // Active
  });

  it("should revert when non-operator creates an event", async function () {
    await expect(
      eventManager.connect(other).createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate)
    ).to.be.revertedWith("Not operator");
  });

  it("should close an active event", async function () {
    await eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate);

    await expect(eventManager.closeEvent(eventId))
      .to.emit(eventManager, "EventClosed")
      .withArgs(eventId);

    const ev = await eventManager.getEventInfo(eventId);
    expect(ev.status).to.equal(2); // Closed
  });

  it("should revert on duplicate eventId", async function () {
    await eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate);

    await expect(
      eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate)
    ).to.be.revertedWith("Event already exists");
  });

  it("should revert on invalid time window (start >= end)", async function () {
    await expect(
      eventManager.createEvent(eventId, end, start, targetKw, rewardRate, penaltyRate)
    ).to.be.revertedWith("Invalid time window");

    await expect(
      eventManager.createEvent(eventId, start, start, targetKw, rewardRate, penaltyRate)
    ).to.be.revertedWith("Invalid time window");
  });

  it("should return event info via getEvent", async function () {
    await eventManager.createEvent(eventId, start, end, targetKw, rewardRate, penaltyRate);

    const ev = await eventManager.getEventInfo(eventId);
    expect(ev.eventId).to.equal(eventId);
    expect(ev.startTime).to.equal(start);
    expect(ev.endTime).to.equal(end);
    expect(ev.targetKw).to.equal(targetKw);
    expect(ev.rewardRate).to.equal(rewardRate);
    expect(ev.penaltyRate).to.equal(penaltyRate);
    expect(ev.creator).to.equal(operator.address);
  });
});
