const { expect } = require("chai");
const { ethers } = require("hardhat");

//Disable (false) or Enable (true) logs for debugging purposes, edit the DEBUG variable
const DEBUG = true;
function log(...args) {
  if (DEBUG) console.log(...args);
}

//Test suite
describe("OwnershipController functionality: Test automation script with Mocha & Chai & Hardhat", function () {
  //Initialization
  let mock; //Mock contract variable, stores the deployed instance of the Mock contract

  //Mocha lifecylce hook
  beforeEach(async function() { //Runs before each and every test case (it(...)) inside the same test suite (describe(...)) to provide a clean new state for the test cases
    const Mock = await ethers.getContractFactory("Mock"); //Uses Ethers.js (injected by Hardhat) to compile and load the contract factory (necessary for creating new Mock type objects) for the Mock contract
    mock = await Mock.deploy(); //Deploys a new instance of the Mock contract into Hardhat's local Ethereum test network, the 'mock' variable will be referenced during the test cases
    await mock.waitForDeployment(); //Wait until the deployment transaction is confirmed (mined), and the contract is deployed on the local in-memory blockchain
  });

  //Test cases

  it("[SHOULD] set owner to msg.sender on deployment", async function() {
    const [deployer] = await ethers.getSigners();
  
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();

    expect(await mock.owner()).to.equal(deployer.address);
  });
  

  it("[SHOULD] emit OwnershipTransferCompleted event during deployment", async function() {
    const [deployer] = await ethers.getSigners();
  
    const MockFactory = await ethers.getContractFactory("Mock", deployer);

    expect(await MockFactory.deploy()).to.emit("OwnershipTransferCompleted").withArgs("0x0000000000000000000000000000000000000000", deployer.address);
  });
  

  it("[SHOULD] have zero address as pending owner after deployment", async function() {
    const [deployer] = await ethers.getSigners();
  
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();

    expect(await mock.pendingOwner()).to.equal("0x0000000000000000000000000000000000000000");
  });
  

  it("[SHOULD] initialize renounceUnlocked to false", async function() {
    expect(await mock.renounceUnlocked()).to.be.false;
  });
  

  it("[SHOULD] return true if it was called by the contract owner", async function() {
    const [deployer] = await ethers.getSigners(); //Deployer will be the owner

    //Deploy the contract from the deployer address (owner)
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Positive path: call function as owner
    expect(await mock.connect(deployer).testOnlyOwnerModifier()).to.equal(true);
  });


  it("[SHOULD] revert with the message 'Only owner!' due to insufficient access privilege", async function() {
    const [deployer, nonOwner] = await ethers.getSigners(); //Deployer will be the owner

    //Deploy the contract from the deployer address (owner)
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Negative path: non-owner should revert
    await expect(mock.connect(nonOwner).testOnlyOwnerModifier()).to.be.revertedWith("Only owner!");
  });


  it("[SHOULD] return true if it was called by a non-owner account", async function() {
    const [deployer, nonOwner] = await ethers.getSigners(); //Deployer will be the owner

    //Deploy the contract from the deployer address (owner)
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Positive path: call function as non-owner
    expect(await mock.connect(nonOwner).testonlyWhenNotOwnerModifier()).to.equal(true);
  });


  it("[SHOULD] revert the function call if it is called by the owner of the contract", async function() {
    const [deployer] = await ethers.getSigners(); //Deployer will be the owner

    //Deploy the contract from the deployer address (owner)
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Negative path: owner should revert
    await expect(mock.connect(deployer).testonlyWhenNotOwnerModifier()).to.be.reverted;
  });


  it("[SHOULD] transfer ownership to the new owner", async function() {
    const [deployer, newOwner] = await ethers.getSigners(); //Deployer is the initial owner
  
    //Deploy the mock contract from the deployer (initial owner)
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Check initial owner
    expect(await mock.owner()).to.equal(deployer.address);
  
    //Transfer ownership using mock wrapper
    await mock.mock_transferOwnership(newOwner.address);
  
    //Check new owner
    expect(await mock.owner()).to.equal(newOwner.address);
  });
  

  it("[SHOULD] emit OwnershipTransferCompleted event with correct parameters", async function() {
    const [deployer, newOwner] = await ethers.getSigners();
  
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Expect the event to be emitted with correct arguments
    await expect(mock.mock_transferOwnership(newOwner.address)).to.emit(mock, "OwnershipTransferCompleted").withArgs(deployer.address, newOwner.address);
  });


  it("[SHOULD] overwrite an existing owner with a new one using _transferOwnership", async function() {
    const [deployer, newOwner1, newOwner2] = await ethers.getSigners();
  
    //Deploy the contract using the deployer (initial owner)
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //The initial owner should be the deployer
    expect(await mock.owner()).to.equal(deployer.address);
  
    //First transfer: change ownership to newOwner1
    await mock.mock_transferOwnership(newOwner1.address);
    expect(await mock.owner()).to.equal(newOwner1.address);
  
    //Second transfer: overwrite owner with newOwner2
    await mock.mock_transferOwnership(newOwner2.address);
    expect(await mock.owner()).to.equal(newOwner2.address);
  });
  
  

  it("[SHOULD] set the pending owner to the provided address", async function() {
    const [deployer, pendingOwner] = await ethers.getSigners(); //Deployer is the initial owner
  
    //Deploy contract
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //pendingOwner should be zero address by default
    expect(await mock.pendingOwner()).to.equal("0x0000000000000000000000000000000000000000");
  
    //Call mock wrapper to set new pending owner
    await mock.mock_setPendingOwner(pendingOwner.address);
  
    //Check if pendingOwner is updated correctly
    expect(await mock.pendingOwner()).to.equal(pendingOwner.address);
  });


  it("[SHOULD] overwrite an existing pending owner with a new one", async function() {
    const [deployer, firstPending, secondPending] = await ethers.getSigners();
  
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Set first pending owner
    await mock.mock_setPendingOwner(firstPending.address);
    expect(await mock.pendingOwner()).to.equal(firstPending.address);
  
    //Overwrite with second pending owner
    await mock.mock_setPendingOwner(secondPending.address);
    expect(await mock.pendingOwner()).to.equal(secondPending.address);
  });


  it("[SHOULD] allow the owner to reset the pending owner", async function() {
    const [deployer, newPendingOwner] = await ethers.getSigners(); //Initialize two addresses, deployer is the owner
    const MockFactory = await ethers.getContractFactory("Mock", deployer); //Prepare contract factory
    const mock = await MockFactory.deploy(); //Deploy contract
  
    await mock.mock_setPendingOwner(newPendingOwner.address); //Set pending owner to newPendingOwner address
    expect(await mock.pendingOwner()).to.equal(newPendingOwner.address); //Pending owner now should be the newPendingOwner address
  
    await expect(mock.connect(deployer).resetPendingOwner()).to.not.be.reverted; //Reset pending owner, should not reset when invoked by the owner
    expect(await mock.pendingOwner()).to.equal("0x0000000000000000000000000000000000000000"); //Pending owner address should be the default for the address data type (zero address)
  });
  

  it("[SHOULD] revert if a non-owner address initiates the reset of the pending owner", async function() {
    const [deployer, newPendingOwner, nonOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();

    await mock.mock_setPendingOwner(newPendingOwner.address); //Set pending owner to newPendingOwner address
    expect(await mock.pendingOwner()).to.equal(newPendingOwner.address); //Pending owner now should be the newPendingOwner address

    await expect(mock.connect(nonOwner).resetPendingOwner()).to.be.revertedWith("Only owner!");
    expect(await mock.pendingOwner()).to.be.equal(newPendingOwner.address);
  });


  it("[SHOULD] actually set pending owner to zero address after being set", async function() {
    const [deployer, newPendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    await mock.mock_setPendingOwner(newPendingOwner.address);
    expect(await mock.pendingOwner()).to.equal(newPendingOwner.address);
  
    await mock.resetPendingOwner();
    expect(await mock.pendingOwner()).to.equal("0x0000000000000000000000000000000000000000");
  });
  
  
  it("[SHOULD] emit no event but change state correctly when resetPendingOwner is called", async function() {
    const [deployer, newPendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    await mock.mock_setPendingOwner(newPendingOwner.address);
    const tx = await mock.resetPendingOwner();
  
    expect(await mock.pendingOwner()).to.equal("0x0000000000000000000000000000000000000000");

    const receipt = await tx.wait();
    const emittedEvents = receipt.events ?? []; //if receipt.events is null or undefined, then it will be an empty array
    expect(emittedEvents.length).to.equal(0);
  });
  

  it("[SHOULD] allow the owner to start the timelock queue when enough signatures are collected", async function() {
    const [deployer] = await ethers.getSigners(); //Deployer is the contract owner
  
    //Deploy contract from deployer address
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Get signer addresses
    const signers = await mock.getSigners();
    const signerAddresses = signers.slice(0, 5); //Use first 5 for the signature threshold
  
    //Register signatures from valid signer addresses
    for(const signer of signerAddresses) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signer] });
      await network.provider.send("hardhat_setBalance", [signer, "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signer);
      await mock.connect(impSigner).registerSignature();
    }
  
    //Start the timelock queue from the owner account
    const tx = await mock.connect(deployer).startQueue();
    await expect(tx).to.emit(mock, "TimelockQueueStarted");
  
    const blockTimestamp = (await ethers.provider.getBlock(tx.blockNumber)).timestamp;
    expect(await mock.getQueueTime()).to.equal(blockTimestamp);
  
    //Stop impersonation
    for(const signer of signerAddresses) {
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signer] });
    }
  });
  
  
  it("[SHOULD] revert the timelock queue initation if the caller is not the owner", async function() {
    const [deployer, nonOwner] = await ethers.getSigners();
  
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Register valid signatures using impersonation
    const signers = await mock.getSigners();
    const signerAddresses = signers.slice(0, 5);
  
    for(const signer of signerAddresses) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signer] });
      await network.provider.send("hardhat_setBalance", [signer, "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signer);
      await mock.connect(impSigner).registerSignature();
    }
  
    //Attempt to start queue from a non-owner account
    await expect(mock.connect(nonOwner).startQueue()).to.be.revertedWith("Only owner!");
  
    //Stop impersonation
    for(const signer of signerAddresses) {
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signer] });
    }
  });
  

  it("[SHOULD] revert the timelock queue initation if signature threshold is not met", async function() {
    const [deployer] = await ethers.getSigners();
  
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Get signer addresses
    const signers = await mock.getSigners();
    const signer = signers[0]; //Only one signer signs
  
    //Register one signature
    await network.provider.request({ method: "hardhat_impersonateAccount", params: [signer] });
    await network.provider.send("hardhat_setBalance", [signer, "0x1000000000000000000"]);
    const impSigner = await ethers.getSigner(signer);
    await mock.connect(impSigner).registerSignature();
  
    //Try to start queue (should revert due to insufficient signatures)
    await expect(mock.connect(deployer).startQueue()).to.be.reverted;
  
    await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signer] });
  });
  
  
  it("[SHOULD] revert the timelock queue initation if signatures expire before the owner starts the queue", async function() {
    const [deployer] = await ethers.getSigners(); //Contract owner
  
    //Deploy the contract
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Get signer addresses
    const signers = await mock.getSigners();
    const signerAddresses = signers.slice(0, 5);
  
    //Register valid signatures
    for(const signer of signerAddresses) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signer] });
      await network.provider.send("hardhat_setBalance", [signer, "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signer);
      await mock.connect(impSigner).registerSignature();
    }
  
    //Manipulate time, jump into the future where the signature session is expired
    await ethers.provider.send("evm_increaseTime", [901]);
    await ethers.provider.send("evm_mine");
  
    //Owner attempts to start queue after signature expiry
    await expect(mock.connect(deployer).startQueue()).to.be.reverted;
  
    //Stop impersonation
    for(const signer of signerAddresses) {
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signer] });
    }
  });
  

  it("[SHOULD] allow a signer to initiate the social guardian recovery mechanism when enough signatures are collected", async function() {
    const [deployer, newOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
    const signers = await mock.getSigners();
  
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
    }
  
    const signer = await ethers.getSigner(signers[0]);
    const tx = await mock.connect(signer).socialGuardianRecovery(newOwner.address);
    await expect(tx).to.emit(mock, "SocialGuardianRecoveryCompleted");
    expect(await mock.owner()).to.equal(newOwner.address);
  });
  

  it("[SHOULD] revert if called by a non-signer even if enough signatures are collected", async function() {
    const [deployer, nonSigner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
    const signers = await mock.getSigners();
  
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
    }
  
    await expect(mock.connect(nonSigner).socialGuardianRecovery(nonSigner.address)).to.be.revertedWith("Not a signer!");
  });
  

  it("[SHOULD] revert if called by a signer but signature threshold is not met", async function() {
    const [deployer, newOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
    const signers = await mock.getSigners();
  
    await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[0]] });
    await network.provider.send("hardhat_setBalance", [signers[0], "0x1000000000000000000"]);
    const signer = await ethers.getSigner(signers[0]);
    await mock.connect(signer).registerSignature();
  
    await expect(mock.connect(signer).socialGuardianRecovery(newOwner.address)).to.be.reverted;
  });
  

  it("[SHOULD] revert if called by the owner", async function() {
    const [deployer] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    await expect(mock.connect(deployer).socialGuardianRecovery(deployer.address)).to.be.revertedWith("Not a signer!");
  });

  
  it("[SHOULD] revert if called by a non-signer and non-owner", async function() {
    const [deployer, nonSigner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    await expect(mock.connect(nonSigner).socialGuardianRecovery(nonSigner.address)).to.be.revertedWith("Not a signer!");
  });

  
  it("[SHOULD] revert if signer calls after ownership has been relinquished", async function() {
    const [deployer, newOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", deployer);
    const mock = await MockFactory.deploy();
  
    //Transfer ownership to the zero address (relinquish ownership)
    await mock.mock_transferOwnership("0x0000000000000000000000000000000000000000");
    expect(await mock.owner()).to.equal("0x0000000000000000000000000000000000000000");
  
    const signers = await mock.getSigners();
  
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
    }
  
    const signer = await ethers.getSigner(signers[0]);
    await expect(mock.connect(signer).socialGuardianRecovery(newOwner.address)).to.be.reverted;
  });
  

  it("[SHOULD] revert if called by a non-owner address", async function() {
    const [owner, nonOwner, newPendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    await expect(mock.connect(nonOwner).transferOwnership(newPendingOwner.address)).to.be.revertedWith("Only owner!");
  });
  

  it("[SHOULD] revert if delay has not elapsed in timelock window", async function() {
    const [owner, newPendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    const signers = await mock.getSigners();

    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();
  
    await expect(mock.connect(owner).transferOwnership(newPendingOwner.address)).to.be.reverted;
  });


  it("[SHOULD] revert if signature threshold is not met", async function() {
    const [owner, newPendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Need to meet the signature threshold to be able to initiate a new timelock queue, these signatures will be used up by the startQueue call, therefore the transferOwnership function will fail due to lack of valid signatures
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    await ethers.provider.send("evm_increaseTime", [30]);
    await ethers.provider.send("evm_mine");

    //The current signature count here is 0, because the startQueue function consumed the signatures that were registered before -> transferOwnership will fail due to insufficient valid signatures

    await expect(mock.connect(owner).transferOwnership(newPendingOwner.address)).to.be.reverted;
  });


  it("[SHOULD] allow execution if all conditions are valid", async function() {
    const [owner, newPendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Need to meet the signature threshold to be able to initiate a new timelock queue, these signatures will be used up by the startQueue call, therefore the transferOwnership function will fail due to lack of valid signatures
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    //Valid execution window (inclusive): [24;84] why? --> Because signature registrations result in transactions that each consumes 1 second, therefore we must account for the additional time elapsed
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");

    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    const tx = await mock.connect(owner).transferOwnership(newPendingOwner.address);
    await expect(tx).to.emit(mock, "OwnershipTransferInitiated").withArgs(owner.address, newPendingOwner.address);

    expect(await mock.pendingOwner()).to.equal(newPendingOwner.address);
  });
  

  it("[SHOULD] revert if the new pending owner is the zero address", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Need to meet the signature threshold to be able to initiate a new timelock queue, these signatures will be used up by the startQueue call, therefore the transferOwnership function will fail due to lack of valid signatures
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    //Valid execution window (inclusive): [24;84] why? --> Because signature registrations result in transactions that each consumes 1 second, therefore we must account for the additional time elapsed
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");

    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await expect(mock.connect(owner).transferOwnership("0x0000000000000000000000000000000000000000")).to.be.reverted;
  });


  it("[SHOULD] revert if new owner is the current owner", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Need to meet the signature threshold to be able to initiate a new timelock queue, these signatures will be used up by the startQueue call, therefore the transferOwnership function will fail due to lack of valid signatures
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    //Valid execution window (inclusive): [24;84] why? --> Because signature registrations result in transactions that each consumes 1 second, therefore we must account for the additional time elapsed
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");

    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await expect(mock.connect(owner).transferOwnership(owner.address)).to.be.reverted;
  });


  it("[SHOULD] revert if the same pending owner is nominated twice", async function() {
    const [owner, newPendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Need to meet the signature threshold to be able to initiate a new timelock queue, these signatures will be used up by the startQueue call, therefore the transferOwnership function will fail due to lack of valid signatures
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    //Valid execution window (inclusive): [24;84] why? --> Because signature registrations result in transactions that each consumes 1 second, therefore we must account for the additional time elapsed
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");

    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    const tx = await mock.connect(owner).transferOwnership(newPendingOwner.address);
    await expect(tx).to.emit(mock, "OwnershipTransferInitiated").withArgs(owner.address, newPendingOwner.address);

    expect(await mock.pendingOwner()).to.equal(newPendingOwner.address);

    //Nominate the same pending owner again
    //Register signatures again
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }

    //Start a timelock queue again
    await mock.connect(owner).startQueue();

    //Manipulate time to be within the execution window
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");

    //Collect signatures for the transferOwnership call
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }

    //Attempt to transferOwnership again to the same newPendingOwner address, it should revert due to nominating the same pending owner again
    await expect(mock.connect(owner).transferOwnership(newPendingOwner.address)).to.be.reverted;
  });


  it("[SHOULD] revert if called by a non-pending owner account", async function() {
    const [owner, pendingOwner, randomUser] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    await mock.mock_setPendingOwner(pendingOwner.address);
  
    await expect(mock.connect(randomUser).acceptOwnership()).to.be.reverted;
  });

  
  it("[SHOULD] revert if called by the current owner", async function() {
    const [owner, pendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    await mock.mock_setPendingOwner(pendingOwner.address);
  
    await expect(mock.connect(owner).acceptOwnership()).to.be.reverted;
  });

  
  it("[SHOULD] allow pending owner to accept ownership and reset pending owner", async function() {
    const [owner, pendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    await mock.mock_setPendingOwner(pendingOwner.address);
  
    const tx = await mock.connect(pendingOwner).acceptOwnership();
  
    await expect(tx).to.emit(mock, "OwnershipTransferCompleted").withArgs(owner.address, pendingOwner.address);
  
    expect(await mock.owner()).to.equal(pendingOwner.address);
    expect(await mock.pendingOwner()).to.equal("0x0000000000000000000000000000000000000000");
  });
  

  it("[SHOULD] not emit any event other than OwnershipTransferCompleted, verify event arguments", async function() {
    const [owner, newPendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    //Simulate the nomination of the new owner
    await mock.mock_setPendingOwner(newPendingOwner.address);

    await expect(mock.connect(newPendingOwner).acceptOwnership()).to.emit(mock, "OwnershipTransferCompleted").withArgs(owner.address, newPendingOwner.address);
  });
  

  it("[SHOULD] revert if acceptOwnership is called twice", async function() {
    const [owner, newPendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    await mock.mock_setPendingOwner(newPendingOwner.address);
  
    await mock.connect(newPendingOwner).acceptOwnership();
  
    await expect(mock.connect(newPendingOwner).acceptOwnership()).to.be.reverted;
  });
  

  it("[SHOULD] revert if called by a non-owner", async function() {
    const [owner, nonOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    await expect(mock.connect(nonOwner).startRenounceProcess()).to.be.revertedWith("Only owner!");
  });
  
  
  it("[SHOULD] revert if timelock is not in valid grace period", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Need to meet the signature threshold to be able to initiate a new timelock queue, these signatures will be used up by the startQueue call, therefore the transferOwnership function will fail due to lack of valid signatures
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    //Valid execution window (inclusive): [24;84]
    await ethers.provider.send("evm_increaseTime", [85]);
    await ethers.provider.send("evm_mine");

    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await expect(mock.connect(owner).startRenounceProcess()).to.be.reverted;
  });


  it("[SHOULD] revert if signature threshold is not met", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Need to meet the signature threshold to be able to initiate a new timelock queue, these signatures will be used up by the startQueue call, therefore the transferOwnership function will fail due to lack of valid signatures
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    //Valid execution window (inclusive): [24;84]
    await ethers.provider.send("evm_increaseTime", [30]);
    await ethers.provider.send("evm_mine");
    
    //Current signature count is 0, startQueue consumed all signatures

    await expect(mock.connect(owner).startRenounceProcess()).to.be.reverted;
  });


  it("[SHOULD] revert if renounce process is already initiated", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Need to meet the signature threshold to be able to initiate a new timelock queue, these signatures will be used up by the startQueue call, therefore the transferOwnership function will fail due to lack of valid signatures
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    //Valid execution window (inclusive): [24;84]
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");

    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    //Start ownership relinquishment process
    await expect(mock.connect(owner).startRenounceProcess()).to.emit(mock, "RenounceProcessInitiated").withArgs(owner.address);
    expect(await mock.renounceUnlocked()).to.be.true;

    //Register signatures again for a new timelock queue initiation
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }

    //Start a new timelock queue again
    await mock.connect(owner).startQueue();

    //Valid execution window (inclusive): [24;84]
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");

    //Register signatures again for a new ownership relinquishment process initiation
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }

    //Start ownership relinquishment process
    await expect(mock.connect(owner).startRenounceProcess()).to.be.reverted;
    expect(await mock.renounceUnlocked()).to.be.true;
  });
  

  it("[SHOULD] allow execution if all conditions are met", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Need to meet the signature threshold to be able to initiate a new timelock queue, these signatures will be used up by the startQueue call, therefore the transferOwnership function will fail due to lack of valid signatures
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    //Valid execution window (inclusive): [24;84]
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");

    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    //Start ownership relinquishment process
    await expect(mock.connect(owner).startRenounceProcess()).to.emit(mock, "RenounceProcessInitiated").withArgs(owner.address);
    expect(await mock.renounceUnlocked()).to.be.true;
  });


  it("[SHOULD] revert if called by non-owner", async function() {
    const [owner, nonOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    await expect(mock.connect(nonOwner).terminateRenounceProcess()).to.be.revertedWith("Only owner!");
  });


  it("[SHOULD] revert if renounce process is not initiated", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    await expect(mock.connect(owner).terminateRenounceProcess()).to.be.reverted;
    expect(await mock.renounceUnlocked()).to.be.false;
  });


  it("[SHOULD] terminate the renounce process and emit RenounceProcessTerminated event", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Need to meet the signature threshold to be able to initiate a new timelock queue, these signatures will be used up by the startQueue call, therefore the transferOwnership function will fail due to lack of valid signatures
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    //Valid execution window (inclusive): [24;84]
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");

    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    //Start ownership relinquishment process
    await expect(mock.connect(owner).startRenounceProcess()).to.emit(mock, "RenounceProcessInitiated").withArgs(owner.address);
    expect(await mock.renounceUnlocked()).to.be.true;

    //Terminate the ownership relinquishment process
    const tx = await mock.connect(owner).terminateRenounceProcess();
    await expect(tx).to.emit(mock, "RenounceProcessTerminated").withArgs(owner.address);
    expect(await mock.renounceUnlocked()).to.be.false;
  });


  it("[SHOULD] revert if called by non-owner", async function() {
    const [owner, nonOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    await expect(mock.connect(nonOwner).renounceOwnership()).to.be.revertedWith("Only owner!");
  });


  it("[SHOULD] revert if renounce process has not been initiated", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    await expect(mock.connect(owner).renounceOwnership()).to.be.reverted;
    expect(await mock.owner()).to.equal(owner.address);
    expect(await mock.renounceUnlocked()).to.be.false;
  });


  it("[SHOULD] transfer ownership to zero address and reset pending owner", async function() {
    const [owner, dummyPendingOwner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();

    const signers = await mock.getSigners();

    //Register signatures to start timelock queue
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const signer = await ethers.getSigner(signers[i]);
      await mock.connect(signer).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }

    await mock.connect(owner).startQueue();
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");

    //Register signatures again for startRenounceProcess
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const signer = await ethers.getSigner(signers[i]);
      await mock.connect(signer).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }

    await mock.connect(owner).startRenounceProcess();
    expect(await mock.renounceUnlocked()).to.be.true;

    //Set a dummy pending owner to test if it is reset after a successful ownership relinquishment process
    await mock.mock_setPendingOwner(dummyPendingOwner.address);
    expect(await mock.pendingOwner()).to.equal(dummyPendingOwner.address);

    await expect(mock.connect(owner).renounceOwnership()).to.emit(mock, "OwnershipTransferCompleted").withArgs(owner.address, "0x0000000000000000000000000000000000000000");

    expect(await mock.owner()).to.equal("0x0000000000000000000000000000000000000000");
    expect(await mock.pendingOwner()).to.equal("0x0000000000000000000000000000000000000000");
  });


  it("[SHOULD] not allow renounceOwnership if it was already renounced", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    const signers = await mock.getSigners();
  
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");
  
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startRenounceProcess();

    await mock.connect(owner).renounceOwnership();

    await expect(mock.connect(owner).renounceOwnership()).to.be.reverted;
  });
  

  it("[SHOULD] prevent renounceOwnership from leaving pending owner set (state integrity)", async function() {
    const [owner, pending] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    await mock.mock_setPendingOwner(pending.address);
  
    const signers = await mock.getSigners();
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();

    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");
  
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startRenounceProcess();

    await mock.connect(owner).renounceOwnership();
  
    expect(await mock.pendingOwner()).to.equal("0x0000000000000000000000000000000000000000");
  });
  

  it("[SHOULD] prevent further access to owner-only functions after renouncing ownership", async function() {
    const [owner] = await ethers.getSigners();
    const MockFactory = await ethers.getContractFactory("Mock", owner);
    const mock = await MockFactory.deploy();
  
    const signers = await mock.getSigners();
  
    //Register signatures to initiate queue
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    await mock.connect(owner).startQueue();
  
    await ethers.provider.send("evm_increaseTime", [24]);
    await ethers.provider.send("evm_mine");
  
    //Register signatures again
    for(let i = 0; i < Number(await mock.getRequiredSignatures()); i++) {
      await network.provider.request({ method: "hardhat_impersonateAccount", params: [signers[i]] });
      await network.provider.send("hardhat_setBalance", [signers[i], "0x1000000000000000000"]);
      const impSigner = await ethers.getSigner(signers[i]);
      await mock.connect(impSigner).registerSignature();
      await network.provider.request({ method: "hardhat_stopImpersonatingAccount", params: [signers[i]] });
    }
  
    //Start and finalize renounce process
    await mock.connect(owner).startRenounceProcess();
    await mock.connect(owner).renounceOwnership();
  
    //Owner should now be the zero address
    expect(await mock.owner()).to.equal("0x0000000000000000000000000000000000000000");
  
    //Attempt to call an owner-only function should revert
    await expect(mock.connect(owner).resetPendingOwner()).to.be.revertedWith("Only owner!");
  });
});