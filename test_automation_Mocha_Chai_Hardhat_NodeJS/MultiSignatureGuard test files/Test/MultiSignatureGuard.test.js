const { expect } = require("chai");
const { ethers } = require("hardhat");

//Disable (false) or Enable (true) logs for debugging purposes, edit the DEBUG variable
const DEBUG = true;
function log(...args) {
  if (DEBUG) console.log(...args);
}

//Test suite
describe("MultiSignatureGuard functionality: Test automation script with Mocha & Chai & Hardhat", function () {
  //Initialization
  let mock; //Mock contract variable, stores the deployed instance of the Mock contract

  //Mocha lifecylce hook
  beforeEach(async function() { //Runs before each and every test case (it(...)) inside the same test suite (describe(...)) to provide a clean new state for the test cases
    const Mock = await ethers.getContractFactory("Mock"); //Uses Ethers.js (injected by Hardhat) to compile and load the contract factory (necessary for creating new Mock type objects) for the Mock contract
    mock = await Mock.deploy(); //Deploys a new instance of the Mock contract into Hardhat's local Ethereum test network, the 'mock' variable will be referenced during the test cases
    await mock.waitForDeployment(); //Wait until the deployment transaction is confirmed (mined), and the contract is deployed on the local in-memory blockchain
  });

  //Test cases

  it("[SHOULD] Initialize all signers correctly and match the total signer count", async function() {
    const signers = await mock.getSigners();
    const totalSigners = await mock.getTotalSignersConstant();
  
    //Check array length
    expect(signers.length).to.equal(totalSigners);
  
    //Check each address is registered as a signer
    for(const signer of signers) {
      const isValid = await mock.isSigner(signer);
      expect(isValid).to.be.true;
    }
  });


  it("[SHOULD] Revert if a zero address exists in the signers array", async function() {
    const Factory = await ethers.getContractFactory("MockWithZeroAddress");
    await expect(Factory.deploy()).to.be.revertedWith("Zero address found");
  });
  

  it("[SHOULD] Revert if the size of the signer array does not match with the _TOTAL_SIGNERS constant variable", async function() {
    const Factory = await ethers.getContractFactory("MockWithSignerArraySizeMismatch");
    await expect(Factory.deploy()).to.be.revertedWith("Incorrect number of signers");
  });


  it("[SHOULD] Constructor set all storage variables correctly", async function() {
    //Note: Constant variables are embedded inside (part of the bytecode) the contract source code (hardcoded), therefore their values are set even before the constructor runs and the contract is deployed
    //Check signature expiry time value after contract construction (should be zero)
    const EXPECTED_INITIAL_EXPIRY_TIME = 0;
    const signatureExpiryTime = await mock.getSignatureExpiryTime();
    expect(signatureExpiryTime).to.equal(EXPECTED_INITIAL_EXPIRY_TIME);

    //Check current signature count value after contract construction (should be zero)
    const EXPECTED_INITIAL_SIGNATURE_COUNT = 0;
    const currentSignatureCount = await mock.currentSignatureCount();
    expect(currentSignatureCount).to.equal(EXPECTED_INITIAL_SIGNATURE_COUNT);
    
    const signers = await mock.getSigners(); //Get signer addresses

    //Check signer array size
    const totalSigners = await mock.getTotalSignersConstant();
    expect(signers.length).to.equal(totalSigners);
  
    //Check each address is registered as a signer (should be true for every signer address after construction)
    for(const signer of signers) {
      const isValid = await mock.isSigner(signer);
      expect(isValid).to.be.true;
    }

    //Check signature status of signers (should be false for every signer address after construction)
    for(const signer of signers) {
      const isValid = await mock.hasSigned(signer);
      expect(isValid).to.be.false;
    }
  });


  it("[SHOULD] Enforce onlySigner modifier: revert for non-signer and allow for valid signer (via impersonation)", async function() {
    //Call protected function from a non-signer address (default Hardhat generated account)
    const [nonSigner] = await ethers.getSigners();
    await expect(mock.connect(nonSigner).onlySignerMockFunction()).to.be.revertedWith("Not a signer!");
    
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signerAddress = signers[0]; //Pick the first valid signer
  
    //Impersonate a valid signer address using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signerAddress],
    });
  
    const impersonatedSigner = await ethers.getSigner(signerAddress);
  
    //Fund the impersonated account
    await network.provider.send(
      "hardhat_setBalance", [signerAddress, "0x1000000000000000000",]
    );

    //Check to confirm impersonation is active
    expect(await impersonatedSigner.getAddress()).to.equal(signerAddress);

    //Ensure it succeeds when called from an impersonated signer
    const EXPECTED_RESPONSE = "Access granted";
    const result = await mock.connect(impersonatedSigner).onlySignerMockFunction();
    expect(result).to.equal(EXPECTED_RESPONSE);
  
    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signerAddress],
    });
  });
  
  
  it("[SHOULD] reset all signatures by setting _currentSignatureCount to zero and set all signers to false in the _hasSigned mapping, then it should emit the event 'SignaturesReset'", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signerAddress1 = signers[0]; //Pick the first valid signer

    //Impersonate a valid signer address using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signerAddress1],
    });
  
    const impersonatedSigner = await ethers.getSigner(signerAddress1);
  
    //Fund the impersonated account
    await network.provider.send(
      "hardhat_setBalance", [signerAddress1, "0x1000000000000000000",]
    );

    //Check to confirm impersonation is active
    expect(await impersonatedSigner.getAddress()).to.equal(signerAddress1);

    await mock.connect(impersonatedSigner).registerSignature();

    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signerAddress1],
    });

    //Current signature count should be 1
    expect(await mock.currentSignatureCount()).to.equal(1);
    log("Signature count before reset: ", await mock.currentSignatureCount());

    //The signer address should have a true flag associated with it in the _hasSigned mapping
    expect(await mock.hasSigned(signerAddress1)).to.be.true;
    log("Signature status for signer before reset: ", await mock.hasSigned(signerAddress1));

    //Let's call the _resetAllSignatures function (overidden by 'resetAllSignatures' in the Mock contract due to internal visibility in the base contract)
    await mock.resetAllSignatures();

    //Current signature count should be 0
    expect(await mock.currentSignatureCount()).to.equal(0);
    log("Signature count after reset: ", await mock.currentSignatureCount());

    //The signer address should have a false flag associated with it in the _hasSigned mapping
    expect(await mock.hasSigned(signerAddress1)).to.be.false;
    log("Signature status for signer after reset: ", await mock.hasSigned(signerAddress1));

    //Check the whole signer set just to be safe
    for (const signer of signers) {
      expect(await mock.hasSigned(signer)).to.be.false;
    }

    //Check event emission, 'SignaturesReset' event
    await expect(mock.resetAllSignatures()).to.emit(mock, "SignaturesReset");

    //Register signatures from all signers, and then reset all signatures
    for (const signerAddress of signers) {
      //Impersonate the next signer in the loop
      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [signerAddress],
      });

      //Fund the signer
      await network.provider.send(
        "hardhat_setBalance",
        [signerAddress, "0x1000000000000000000"] //1 ETH
      );

      const impersonatedSigner = await ethers.getSigner(signerAddress);

      //Register signature
      await mock.connect(impersonatedSigner).registerSignature();

      //Stop impersonation
      await network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [signerAddress],
      });
    }

    //All signatures should be registered from the whole signer set
    expect(await mock.currentSignatureCount()).to.equal(await mock.getTotalSignersConstant());
    log("Signature count after all signatures were submitted: ", await mock.currentSignatureCount());

    //Check the signatures status for each signer
    for(const signerAddress of signers) {
      expect(await mock.hasSigned(signerAddress)).to.be.true;
      log("Signature status for signer before reset: ", signerAddress, ": ", await mock.hasSigned(signerAddress));
    }

    //Reset all signatures
    await mock.resetAllSignatures();

    //The signature count should be zero after reset
    expect(await mock.currentSignatureCount()).to.equal(0);
    log("Signature count after reset: ", await mock.currentSignatureCount());

    //All signature statuses for each associated signer should be false after reset
    for(const signerAddress of signers) {
      expect(await mock.hasSigned(signerAddress)).to.be.false;
      log("Signature status for signer after reset: ", signerAddress, ": ", await mock.hasSigned(signerAddress));
    }

    //Check event emission, 'SignaturesReset' event
    await expect(mock.resetAllSignatures()).to.emit(mock, "SignaturesReset");
  });

  
  it("[SHOULD] allow a valid signer to register a signature, update state, and emit correct events", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signer = signers[0]; //Pick the first valid signer

    //Impersonate a valid signer address using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer],
    });
  
    const impersonatedSigner = await ethers.getSigner(signer);
  
    //Fund the impersonated account
    await network.provider.send(
      "hardhat_setBalance", [signer, "0x1000000000000000000",]
    );

    //Check to confirm impersonation is active
    expect(await impersonatedSigner.getAddress()).to.equal(signer);

    //Signature expirty time should be zero before the signature registration
    expect(await mock.getSignatureExpiryTime()).to.equal(0);
    log("Signature expiry time before signature registration: ", await mock.getSignatureExpiryTime());

    //The signer address should have a false flag associated with it in the _hasSigned mapping
    expect(await mock.hasSigned(signer)).to.be.false;
    log("_hasSigned status before signature registration: ", await mock.hasSigned(signer));

    //Current signature count should be zero before signature registration
    expect(await mock.currentSignatureCount()).to.equal(0);
    log("Signature count before signature registration: ", await mock.currentSignatureCount());

    //Register signature
    const tx = await mock.connect(impersonatedSigner).registerSignature();

    //It is a new signature session (_currentSignatureCount was zero before the signature), 'SignatureRegistered' and 'SignatureValidityTimeCountdownStarted' events should be emitted
    await expect(tx).to.emit(mock, "SignatureRegistered").withArgs(signers[0]);
    await expect(tx).to.emit(mock, "SignatureValidityTimeCountdownStarted");

    //_currentSignatureCount should be 1 after the signature
    expect(await mock.currentSignatureCount()).to.equal(1);
    log("Signature count after signature registration: ", await mock.currentSignatureCount());

    //The _hasSigned mapping should have a true value associated with the address of the signer
    expect(await mock.hasSigned(signer)).to.be.true;
    log("_hasSigned status after signature registration: ", await mock.hasSigned(signer));

    //Get the signature expiry timestamp
    const signatureExpiryTime = await mock.getSignatureExpiryTime();

    //Get current timestamp
    const blockTimestamp = (await ethers.provider.getBlock(tx.blockNumber)).timestamp;
    log("Block timestamp [seconds]:", blockTimestamp);
    
    //Get validity time
    const validityTime = await mock.getSignatureValidityTime();
    log("Signature validity time [seconds]:", validityTime);
  
    //The signature expirty time should be equal to the sum of the block timestamp and the signature validity time
    expect(signatureExpiryTime).to.equal(BigInt(blockTimestamp) + validityTime);
    log("Signature expiry time after signature registration: ", BigInt(blockTimestamp) + validityTime);

    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer],
    });
  });


  it("[SHOULD] revert if the same signer tries to sign twice in the same session", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signer = signers[0]; //Pick the first valid signer

    //Impersonate a valid signer address using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer],
    });

    const impersonatedSigner = await ethers.getSigner(signer);

    //Fund the impersonated account
    await network.provider.send(
      "hardhat_setBalance", [signer, "0x1000000000000000000",]
    );

    //Check to confirm impersonation is active
    expect(await impersonatedSigner.getAddress()).to.equal(signer);

    log("Current signature count before signature registration: ", await mock.currentSignatureCount());

    //Register signature
    await mock.connect(impersonatedSigner).registerSignature();

    log("Current signature count after signature registration: ", await mock.currentSignatureCount());

    //Should revert the second signature registration transaction because in the _hasSigned mapping, the address has a true value
    await expect(mock.connect(impersonatedSigner).registerSignature()).to.be.reverted;

    log("Current signature count after invalid (duplicate within same session) signature registration: ", await mock.currentSignatureCount());
    
    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer],
    });
  });


  it("[SHOULD] revert if a non-signer tries to register a signature", async function() {
    const [nonSigner] = await ethers.getSigners(); //Default Hardhat account, not part of the signer set

    //The signature registration attempt should revert because the caller is not in the signer set
    await expect(mock.connect(nonSigner).registerSignature()).to.be.revertedWith("Not a signer!");

    //The current signature count should not increase
    expect(await mock.currentSignatureCount()).to.equal(0);
    log("Signature count after the failed attempt: ", await mock.currentSignatureCount());

    //The address should not be marked in the _hasSigned mapping
    expect(await mock.hasSigned(nonSigner.address)).to.be.false;
    log("Has signed status for the non-signer after failed signature attempt: ", await mock.hasSigned(nonSigner.address));
  });


  it("[SHOULD] emit 'SignatureValidityTimeCountdownStarted' when first signature is registered in a session", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signer = signers[0]; //Pick the first valid signer

    //Impersonate a valid signer address using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer],
    });

    const impersonatedSigner = await ethers.getSigner(signer);

    //Fund the impersonated account
    await network.provider.send(
      "hardhat_setBalance", [signer, "0x1000000000000000000",]
    );

    //Check to confirm impersonation is active
    expect(await impersonatedSigner.getAddress()).to.equal(signer);

    //Register signature
    const tx = await mock.connect(impersonatedSigner).registerSignature();
    await expect(tx).to.emit(mock, "SignatureValidityTimeCountdownStarted");
    await expect(tx).to.emit(mock, "SignatureRegistered").withArgs(signer);
    
    //Get current timestamp
    const blockTimestamp = (await ethers.provider.getBlock(tx.blockNumber)).timestamp;
    log("Block timestamp [seconds]: ", blockTimestamp);
        
    //Get validity time
    const validityTime = await mock.getSignatureValidityTime();
    log("Signature validity time [seconds]: ", validityTime);

    const signatureExpiryTime = await mock.getSignatureExpiryTime();
    log("Signature expiry time [seconds]: ", signatureExpiryTime);

    //The signature expiry time should be equal to the sum of the block timestamp and the signature validity time
    expect(signatureExpiryTime).to.equal(BigInt(blockTimestamp) + validityTime);
    log("Signature expiry time after signature registration: ", BigInt(blockTimestamp) + validityTime);
    
    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer],
    });
  });


  it("[5] SHOULD reset signatures if signature expired before new registration", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signer_1 = signers[0]; //Pick the first valid signer
    const signer_2 = signers[1]; //Pick the second valid signer

    //Impersonate a valid signer address using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_1],
    });

    //Impersonate a valid signer address using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_2],
    });

    const impersonatedSigner_1 = await ethers.getSigner(signer_1);
    const impersonatedSigner_2 = await ethers.getSigner(signer_2);

    //Fund the impersonated account
    await network.provider.send(
      "hardhat_setBalance", [signer_1, "0x1000000000000000000",]
    );

    //Fund the impersonated account
    await network.provider.send(
      "hardhat_setBalance", [signer_2, "0x1000000000000000000",]
    );

    //Check to confirm impersonation is active
    expect(await impersonatedSigner_1.getAddress()).to.equal(signer_1);
    expect(await impersonatedSigner_2.getAddress()).to.equal(signer_2);

    //Register signature
    await mock.connect(impersonatedSigner_1).registerSignature();
    log("Signature expiry time after first signature: ", await mock.getSignatureExpiryTime());
    log("Signature count after first signature (in the first session): ", await mock.currentSignatureCount());

    //Fast-forward time past signature expiry (900 seconds default validity)
    await ethers.provider.send("evm_increaseTime", [901]);
    await ethers.provider.send("evm_mine");
    
    const tx = await mock.connect(impersonatedSigner_2).registerSignature();
    log("Signature expiry time after second signature: ", await mock.getSignatureExpiryTime());
    log("Signature count after second signature (in the second session, first has already expired at this point): ", await mock.currentSignatureCount());

    //Check whether all signers have a false signature status for the session except for signer 2 who signed after the expiry time
    for(const signer of signers) {
      if(signer !== signer_2) {
        expect(await mock.hasSigned(signer)).to.be.false;
      }
    }

    //Explicitly check whether signer_2 has a true signature status for the new session
    expect(await mock.hasSigned(signer_2)).to.be.true;

    await expect(tx).to.emit(mock, "SignaturesExpiredAndReset");
    await expect(tx).to.emit(mock, "SignatureValidityTimeCountdownStarted");

    //Get block timestamp of second signature
    const blockTimestamp = (await ethers.provider.getBlock(tx.blockNumber)).timestamp;
    log("Block timestamp after second signature [seconds]: ", blockTimestamp);

    //Get validity time
    const validityTime = await mock.getSignatureValidityTime();
    log("Signature validity time constant [seconds]: ", validityTime);

    //Expected expiry time
    const expectedExpiryTime = BigInt(blockTimestamp) + validityTime;
    log("Expected new signature expiry time after second signature registration: ", expectedExpiryTime);

    //Get the actual signature expiry time
    const signatureExpiryTime = await mock.getSignatureExpiryTime();
    log("Actual signature expiry time after second signature registration: ", signatureExpiryTime);

    //The signature expiry time should match the expected expiry time after new registration
    expect(signatureExpiryTime).to.equal(expectedExpiryTime);
    
    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_1],
    });

    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_2],
    });
  });

  
  it("[8] SHOULD correctly count multiple signers registration", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signer_1 = signers[0]; //Pick the first valid signer
    const signer_2 = signers[1]; //Pick the second valid signer
    const signer_3 = signers[2]; //Pick the third valid signer
  
    //Impersonate valid signer addresses using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_1],
    });
  
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_2],
    });
  
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_3],
    });
  
    const impersonatedSigner_1 = await ethers.getSigner(signer_1);
    const impersonatedSigner_2 = await ethers.getSigner(signer_2);
    const impersonatedSigner_3 = await ethers.getSigner(signer_3);
  
    //Fund the impersonated accounts
    await network.provider.send(
      "hardhat_setBalance", [signer_1, "0x1000000000000000000"]
    );
  
    await network.provider.send(
      "hardhat_setBalance", [signer_2, "0x1000000000000000000"]
    );
  
    await network.provider.send(
      "hardhat_setBalance", [signer_3, "0x1000000000000000000"]
    );
  
    //Check to confirm impersonation is active
    expect(await impersonatedSigner_1.getAddress()).to.equal(signer_1);
    expect(await impersonatedSigner_2.getAddress()).to.equal(signer_2);
    expect(await impersonatedSigner_3.getAddress()).to.equal(signer_3);
  
    //Register signatures from three different signers
    const tx1 = await mock.connect(impersonatedSigner_1).registerSignature();
    const tx2 = await mock.connect(impersonatedSigner_2).registerSignature();
    const tx3 = await mock.connect(impersonatedSigner_3).registerSignature();
  
    log("Signature count after three successful signature registrations: ", await mock.currentSignatureCount());
  
    //The signature count should be equal to 3 after three different signers signed
    expect(await mock.currentSignatureCount()).to.equal(3);
  
    //Each of these three signers should have a true flag in the _hasSigned mapping
    expect(await mock.hasSigned(signer_1)).to.be.true;
    expect(await mock.hasSigned(signer_2)).to.be.true;
    expect(await mock.hasSigned(signer_3)).to.be.true;
  
    //Check the whole signer set
    for (const signer of signers) {
      if (signer !== signer_1 && signer !== signer_2 && signer !== signer_3) {
        expect(await mock.hasSigned(signer)).to.be.false;
      }
    }
  
    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_1],
    });
  
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_2],
    });
  
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_3],
    });
  });
  

  it("[9] SHOULD emit events in correct order when registering a signature", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signer = signers[0]; //Pick the first valid signer
  
    //Impersonate a valid signer address using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer],
    });
  
    const impersonatedSigner = await ethers.getSigner(signer);
  
    //Fund the impersonated account
    await network.provider.send(
      "hardhat_setBalance", [signer, "0x1000000000000000000"]
    );
  
    //Check to confirm impersonation is active
    expect(await impersonatedSigner.getAddress()).to.equal(signer);
  
    //Register a signature
    const tx = await mock.connect(impersonatedSigner).registerSignature();
  
    //Wait for the transaction to be mined
    const receipt = await tx.wait();
  
    //Manually decode the events using the contract interface
    const iface = mock.interface; //Get the contract's ABI interface
  
    const eventNames = receipt.logs.map(log => {
        try {
          return iface.parseLog(log).name;
        } catch (err) {
          return null; //Not every log belongs to this contract
        }
      }).filter(name => name !== null);
  
    log("Emitted events during signature registration: ", eventNames);
  
    //Check event order: SignatureValidityTimeCountdownStarted must come first, SignatureRegistered must come second
    expect(eventNames[0]).to.equal("SignatureValidityTimeCountdownStarted");
    expect(eventNames[1]).to.equal("SignatureRegistered");
  
    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer],
    });
  });
  

  it("[10] SHOULD allow all signers to register without expiry and count correctly", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const impersonatedSigners = [];
  
    //Impersonate and fund each signer
    for (const signer of signers) {
      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [signer],
      });
  
      await network.provider.send(
        "hardhat_setBalance", [signer, "0x1000000000000000000"]
      );
  
      const impersonatedSigner = await ethers.getSigner(signer);
      expect(await impersonatedSigner.getAddress()).to.equal(signer);
  
      impersonatedSigners.push(impersonatedSigner);
    }
  
    //Register signatures from all signers
    for (const impersonatedSigner of impersonatedSigners) {
      await mock.connect(impersonatedSigner).registerSignature();
    }
  
    log("Signature count after all signers registered: ", await mock.currentSignatureCount());
  
    //The signature count should be equal to the number of total signers
    expect(await mock.currentSignatureCount()).to.equal(await mock.getTotalSignersConstant());
  
    //Each signer should have a true flag in the _hasSigned mapping
    for (const signer of signers) {
      expect(await mock.hasSigned(signer)).to.be.true;
    }
  
    //Stop impersonation
    for (const signer of signers) {
      await network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [signer],
      });
    }
  });
  

  it("[11] SHOULD reset old signatures automatically after partial expiry", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signer_1 = signers[0]; //Pick the first valid signer
    const signer_2 = signers[1]; //Pick the second valid signer
    const signer_3 = signers[2]; //Pick the third valid signer
  
    //Impersonate valid signer addresses using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_1],
    });
  
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_2],
    });
  
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_3],
    });
  
    const impersonatedSigner_1 = await ethers.getSigner(signer_1);
    const impersonatedSigner_2 = await ethers.getSigner(signer_2);
    const impersonatedSigner_3 = await ethers.getSigner(signer_3);
  
    //Fund the impersonated accounts
    await network.provider.send(
      "hardhat_setBalance", [signer_1, "0x1000000000000000000"]
    );
  
    await network.provider.send(
      "hardhat_setBalance", [signer_2, "0x1000000000000000000"]
    );
  
    await network.provider.send(
      "hardhat_setBalance", [signer_3, "0x1000000000000000000"]
    );
  
    //Check to confirm impersonation is active
    expect(await impersonatedSigner_1.getAddress()).to.equal(signer_1);
    expect(await impersonatedSigner_2.getAddress()).to.equal(signer_2);
    expect(await impersonatedSigner_3.getAddress()).to.equal(signer_3);
  
    //Register signatures from two different signers (signer_1 and signer_2)
    await mock.connect(impersonatedSigner_1).registerSignature();
    await mock.connect(impersonatedSigner_2).registerSignature();
    
    log("Signature count after two signatures: ", await mock.currentSignatureCount());
  
    //Fast-forward time past signature expiry (900 seconds default validity)
    await ethers.provider.send("evm_increaseTime", [901]);
    await ethers.provider.send("evm_mine");
  
    //Register a new signature after expiry with signer_3
    const tx = await mock.connect(impersonatedSigner_3).registerSignature();
    
    log("Signature count after new signature post-expiry: ", await mock.currentSignatureCount());
  
    //Check whether only signer_3 has a true signature status, all others should be false
    for (const signer of signers) {
      if (signer !== signer_3) {
        expect(await mock.hasSigned(signer)).to.be.false;
      }
    }
  
    //Explicitly check that signer_3 has signed in the new session
    expect(await mock.hasSigned(signer_3)).to.be.true;
  
    //After reset and signer_3's new signature, the signature count must be 1
    expect(await mock.currentSignatureCount()).to.equal(1);
  
    //Events emitted must include expiration reset and countdown started
    await expect(tx).to.emit(mock, "SignaturesExpiredAndReset").and.to.emit(mock, "SignatureValidityTimeCountdownStarted");
  
    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_1],
    });
  
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_2],
    });
  
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_3],
    });
  });


  it("[SHOULD] revert in case the current signature count is lower than the signature threshold", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signer_1 = signers[0]; //Pick the first valid signer
    const signer_2 = signers[1]; //Pick the second valid signer
    const signer_3 = signers[2]; //Pick the third valid signer
    const signer_4 = signers[3]; //Pick the fourth valid signer
    const signer_5 = signers[4]; //Pick the fifth valid signer

    //Impersonate valid signer addresses using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_1],
    });
  
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_2],
    });
  
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_3],
    });

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_4],
    });

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_5],
    });
  
    const impersonatedSigner_1 = await ethers.getSigner(signer_1);
    const impersonatedSigner_2 = await ethers.getSigner(signer_2);
    const impersonatedSigner_3 = await ethers.getSigner(signer_3);
    const impersonatedSigner_4 = await ethers.getSigner(signer_4);
    const impersonatedSigner_5 = await ethers.getSigner(signer_5);

    //Fund the impersonated accounts
    await network.provider.send(
      "hardhat_setBalance", [signer_1, "0x1000000000000000000"]
    );
  
    await network.provider.send(
      "hardhat_setBalance", [signer_2, "0x1000000000000000000"]
    );
  
    await network.provider.send(
      "hardhat_setBalance", [signer_3, "0x1000000000000000000"]
    );

    await network.provider.send(
      "hardhat_setBalance", [signer_4, "0x1000000000000000000"]
    );

    await network.provider.send(
      "hardhat_setBalance", [signer_5, "0x1000000000000000000"]
    );
  
    //Check to confirm impersonation is active
    expect(await impersonatedSigner_1.getAddress()).to.equal(signer_1);
    expect(await impersonatedSigner_2.getAddress()).to.equal(signer_2);
    expect(await impersonatedSigner_3.getAddress()).to.equal(signer_3);
    expect(await impersonatedSigner_4.getAddress()).to.equal(signer_4);
    expect(await impersonatedSigner_5.getAddress()).to.equal(signer_5);
    
    await mock.connect(impersonatedSigner_1).registerSignature();
    expect(await mock.hasSigned(signer_1)).to.be.true;
    log("Current signature count after the first signature: ", await mock.currentSignatureCount());
    await expect(mock.mockMultiSignatureGuardedFunction()).to.be.reverted;

    await mock.connect(impersonatedSigner_2).registerSignature();
    expect(await mock.hasSigned(signer_2)).to.be.true;
    log("Current signature count after the second signature: ", await mock.currentSignatureCount());
    await expect(mock.mockMultiSignatureGuardedFunction()).to.be.reverted;

    await mock.connect(impersonatedSigner_3).registerSignature();
    expect(await mock.hasSigned(signer_3)).to.be.true;
    log("Current signature count after the third signature: ", await mock.currentSignatureCount());
    await expect(mock.mockMultiSignatureGuardedFunction()).to.be.reverted;

    await mock.connect(impersonatedSigner_4).registerSignature();
    expect(await mock.hasSigned(signer_4)).to.be.true;
    log("Current signature count after the fourth signature: ", await mock.currentSignatureCount());
    await expect(mock.mockMultiSignatureGuardedFunction()).to.be.reverted;

    await mock.connect(impersonatedSigner_5).registerSignature();
    expect(await mock.hasSigned(signer_5)).to.be.true;
    log("Current signature count after the fifth signature: ", await mock.currentSignatureCount());

    //Threshold is 5, the current signature count is 5, the function should be allowed to execute because the signature threshold is reached
    await expect(mock.mockMultiSignatureGuardedFunction()).to.not.be.reverted;

    //All signatures should be reset, new session is started (the signatures can be used only once)
    for(const signer of signers) {
      expect(await mock.hasSigned(signer)).to.be.false;
    }

    //Current signature count should be reset (the signatures can be used only once)
    expect(await mock.currentSignatureCount()).to.equal(0);

    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_1],
    });
      
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_2],
    });
      
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_3],
    });

    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_4],
    });
      
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_5],
    });
  });


  it("[SHOULD] revert if signatures expire before calling the protected function", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signer_1 = signers[0]; //Pick the first valid signer
    const signer_2 = signers[1]; //Pick the second valid signer
    const signer_3 = signers[2]; //Pick the third valid signer
    const signer_4 = signers[3]; //Pick the fourth valid signer
    const signer_5 = signers[4]; //Pick the fifth valid signer

    //Impersonate valid signer addresses using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_1],
    });
  
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_2],
    });
  
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_3],
    });

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_4],
    });

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_5],
    });
  
    const impersonatedSigner_1 = await ethers.getSigner(signer_1);
    const impersonatedSigner_2 = await ethers.getSigner(signer_2);
    const impersonatedSigner_3 = await ethers.getSigner(signer_3);
    const impersonatedSigner_4 = await ethers.getSigner(signer_4);
    const impersonatedSigner_5 = await ethers.getSigner(signer_5);

    //Fund the impersonated accounts
    await network.provider.send(
      "hardhat_setBalance", [signer_1, "0x1000000000000000000"]
    );
  
    await network.provider.send(
      "hardhat_setBalance", [signer_2, "0x1000000000000000000"]
    );
  
    await network.provider.send(
      "hardhat_setBalance", [signer_3, "0x1000000000000000000"]
    );

    await network.provider.send(
      "hardhat_setBalance", [signer_4, "0x1000000000000000000"]
    );

    await network.provider.send(
      "hardhat_setBalance", [signer_5, "0x1000000000000000000"]
    );
  
    //Check to confirm impersonation is active
    expect(await impersonatedSigner_1.getAddress()).to.equal(signer_1);
    expect(await impersonatedSigner_2.getAddress()).to.equal(signer_2);
    expect(await impersonatedSigner_3.getAddress()).to.equal(signer_3);
    expect(await impersonatedSigner_4.getAddress()).to.equal(signer_4);
    expect(await impersonatedSigner_5.getAddress()).to.equal(signer_5);
    
    //Register signatures from 5 signers
    await mock.connect(impersonatedSigner_1).registerSignature();
    expect(await mock.hasSigned(signer_1)).to.be.true;

    await mock.connect(impersonatedSigner_2).registerSignature();
    expect(await mock.hasSigned(signer_2)).to.be.true;

    await mock.connect(impersonatedSigner_3).registerSignature();
    expect(await mock.hasSigned(signer_3)).to.be.true;

    await mock.connect(impersonatedSigner_4).registerSignature();
    expect(await mock.hasSigned(signer_4)).to.be.true;

    await mock.connect(impersonatedSigner_5).registerSignature();
    expect(await mock.hasSigned(signer_5)).to.be.true;

    log("Signature count after collecting required signatures: ", await mock.currentSignatureCount());
    
    //Fast-forward time past signature expiry (900 seconds default validity)
    await ethers.provider.send("evm_increaseTime", [901]);
    await ethers.provider.send("evm_mine");

    //Try to call the guarded function, it should revert due to expired signatures
    await expect(mock.mockMultiSignatureGuardedFunction()).to.be.reverted;

    //After revert, signature count should remain unchanged (not reset automatically, _resetAllSignatures() is not reached within the modifier's body)
    const requiredSignatures = await mock.getRequiredSignatures();
    expect(await mock.currentSignatureCount()).to.equal(requiredSignatures);
    log("Signature count after revert (should be unchanged): ", requiredSignatures);

    //Check that all signers have their hasSigned flags left true (not reset automatically, _resetAllSignatures() is not reached within the modifier's body)
    for (let i = 0; i < Number(requiredSignatures); i++) {
      expect(await mock.hasSigned(signers[i])).to.be.true;
      log("Signature status for the ", (i+1), ". signer: ", await mock.hasSigned(signers[i]));
    }

    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_1],
    });
      
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_2],
    });
      
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_3],
    });

    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_4],
    });
      
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_5],
    });
  });


  it("[SHOULD] reset expired signatures when a new signature is registered after expiration", async function() {
    const signers = await mock.getSigners(); //Get hardcoded signer addresses
    const signer_1 = signers[0];
    const signer_2 = signers[1];
    const signer_3 = signers[2];
    const signer_4 = signers[3];
    const signer_5 = signers[4];
    const signer_6 = signers[5]; //New signer for recovery after expiry
  
    //Impersonate valid signer addresses using Hardhat's address impersonation method
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_1],
    });
  
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_2],
    });
  
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_3],
    });

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_4],
    });

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_5],
    });

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [signer_6],
    });

    //Fund the impersonated accounts
    await network.provider.send(
      "hardhat_setBalance", [signer_1, "0x1000000000000000000"]
    );
      
    await network.provider.send(
      "hardhat_setBalance", [signer_2, "0x1000000000000000000"]
    );
      
    await network.provider.send(
      "hardhat_setBalance", [signer_3, "0x1000000000000000000"]
    );
    
    await network.provider.send(
      "hardhat_setBalance", [signer_4, "0x1000000000000000000"]
    );
    
    await network.provider.send(
      "hardhat_setBalance", [signer_5, "0x1000000000000000000"]
    );
  
    await network.provider.send(
      "hardhat_setBalance", [signer_6, "0x1000000000000000000"]
    );

    const impersonatedSigner_1 = await ethers.getSigner(signer_1);
    const impersonatedSigner_2 = await ethers.getSigner(signer_2);
    const impersonatedSigner_3 = await ethers.getSigner(signer_3);
    const impersonatedSigner_4 = await ethers.getSigner(signer_4);
    const impersonatedSigner_5 = await ethers.getSigner(signer_5);
    const impersonatedSigner_6 = await ethers.getSigner(signer_6);
  
    //Check to confirm impersonation is active
    expect(await impersonatedSigner_1.getAddress()).to.equal(signer_1);
    expect(await impersonatedSigner_2.getAddress()).to.equal(signer_2);
    expect(await impersonatedSigner_3.getAddress()).to.equal(signer_3);
    expect(await impersonatedSigner_4.getAddress()).to.equal(signer_4);
    expect(await impersonatedSigner_5.getAddress()).to.equal(signer_5);
    expect(await impersonatedSigner_6.getAddress()).to.equal(signer_6);

    //Register signatures from 5 signers
    await mock.connect(impersonatedSigner_1).registerSignature();
    await mock.connect(impersonatedSigner_2).registerSignature();
    await mock.connect(impersonatedSigner_3).registerSignature();
    await mock.connect(impersonatedSigner_4).registerSignature();
    await mock.connect(impersonatedSigner_5).registerSignature();
  
    log("Signature count after collecting required signatures: ", await mock.currentSignatureCount());
  
    //Fast-forward time past signature expiry (900 seconds)
    await ethers.provider.send("evm_increaseTime", [901]);
    await ethers.provider.send("evm_mine");
  
    //Protected function call should revert due to expiry
    await expect(mock.mockMultiSignatureGuardedFunction()).to.be.reverted;
  
    //Signature count and hasSigned are still non-reset (does not reset automatically if signatures expire in a session, only a new signature from the next session will reset them)
    const requiredSignatures = await mock.getRequiredSignatures();
    expect(await mock.currentSignatureCount()).to.equal(requiredSignatures);
    
    for (let i = 0; i < Number(requiredSignatures); i++) {
      expect(await mock.hasSigned(signers[i])).to.be.true;
    }
  
    //Register a new signature after expiry (with signer_6)
    const tx = await mock.connect(impersonatedSigner_6).registerSignature();
    
    //Should emit SignaturesExpiredAndReset and SignatureValidityTimeCountdownStarted
    await expect(tx).to.emit(mock, "SignaturesExpiredAndReset").and.to.emit(mock, "SignatureValidityTimeCountdownStarted").and.to.emit(mock, "SignatureRegistered").withArgs(signer_6);
  
    log("Signature count after resetting and new signature registration: ", await mock.currentSignatureCount());
  
    //Current signature count should now be 1
    expect(await mock.currentSignatureCount()).to.equal(1);
  
    //Only signer_6 should have true hasSigned status
    for (const signer of signers) {
      if (signer !== signer_6) {
        expect(await mock.hasSigned(signer)).to.be.false;
      }
    }
  
    expect(await mock.hasSigned(signer_6)).to.be.true;
  
    //Stop impersonation
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_1],
    });
          
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_2],
    });
          
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_3],
    });
    
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_4],
    });
          
    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_5],
    });

    await network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [signer_6],
    });
  });

});