const { expect } = require("chai");
const { ethers } = require("hardhat");

//Disable (false) or Enable (true) logs for debugging purposes, edit the DEBUG variable
const DEBUG = false;
function log(...args) {
  if (DEBUG) console.log(...args);
}

//Test suite
//Delay used for testing: 30 seconds (_DELAY = 30 seconds)
//Grace period used for testing: 60 seconds (_GRACE_PERIOD = 60 seconds)
describe("TimelockGuard functionality: Test automation script with Mocha & Chai & Hardhat", function () {
  //Initialization
  let mock; //Mock contract variable, stores the deployed instance of the Mock contract

    //Mocha lifecylce hook
  beforeEach(async function () { //Runs before each and every test case (it(...)) inside the same test suite (describe(...)) to provide a clean new state for the test cases
    const Mock = await ethers.getContractFactory("Mock"); //Uses Ethers.js (injected by Hardhat) to compile and load the contract factory (necessary for creating new Mock type objects) for the Mock contract
    mock = await Mock.deploy(); //Deploys a new instance of the Mock contract into Hardhat's local Ethereum test network, the 'mock' variable will be referenced during the test cases
    await mock.waitForDeployment(); //Wait until the deployment transaction is confirmed (mined), and the contract is deployed on the local in-memory blockchain
  });

  //Test cases

  //Verifies that the timelock queue time is initialized to zero by default
  it("[SHOULD] be set to zero by default (the queue time)", async function () {
    const queueTime = await mock.getQueueTime();
    expect(queueTime).to.equal(0);
    log("Default queue time:", queueTime.toString());
  });


  //Ensure that the timelock queue mechanism starts properly and sets a non-zero timestamp
  it("[SHOULD] initiate the queue time", async function () {
    const queueTimeNotInitiated = await mock.getQueueTime();
    log("Queue time BEFORE initiation:", queueTimeNotInitiated.toString());

    await mock.callStartQueue(); //Start queue

    const queueTimeInitiated = await mock.getQueueTime();
    expect(queueTimeInitiated).to.be.gt(0);
    log("Queue time AFTER initiation:", queueTimeInitiated.toString());
  });


  //Verifies that invoking the callResetQueue (_resetQueue) function correctly resets the queue time to zero after it has been previously initiated by callStartQueue (_startQueue)
  it("[SHOULD] Reset the queue time after starting a queue", async function () {
    const queueTimeNotInitiated = await mock.getQueueTime();
    log("Queue time BEFORE initiation:", queueTimeNotInitiated.toString());

    await mock.callStartQueue(); //Start queue

    const queueTimeInitiated = await mock.getQueueTime();
    log("Queue time AFTER initiation:", queueTimeInitiated.toString());

    await mock.callResetQueue(); //Reset queue

    const queueTimeAfterReset = await mock.getQueueTime();
    log("Queue time AFTER reset:", queueTimeAfterReset.toString());

    const queueTime = await mock.getQueueTime();
    expect(queueTime).to.equal(0);
  });


  //Ensures that invoking the callStartQueue (_startQueue) function successfully sets a non-zero queue time and emits the TimelockQueueStarted event
  it("[SHOULD] Set queue time on callStartQueue and emit 'TimelockQueueStarted'", async function () {
    const queueTimeNotInitiated = await mock.getQueueTime();
    log("Queue time BEFORE initiation:", queueTimeNotInitiated.toString());
    
    //Call callStartQueue and expect the event "TimelockQueueStarted"
    await expect(mock.callStartQueue()).to.emit(mock, "TimelockQueueStarted");

    const queueTimeInitiated = await mock.getQueueTime();
    expect(queueTimeInitiated).to.be.gt(0); //queueTime should be greater than 0 after successful initiation
    log("Queue time AFTER initiation:", queueTimeInitiated.toString());
  });


  //Verifies that the callResetQueue (_resetQueue) function correctly resets the queue time to zero and emits the TimeLockQueueReset event
  it("[SHOULD] Reset the queue time to 0 and emit 'TimeLockQueueReset'", async function () {
    await mock.callStartQueue(); //Start queue

    const queueTimeBeforeExecution = await mock.getQueueTime();
    log("Queue time BEFORE reset:", queueTimeBeforeExecution.toString());

    //Expect the event to be emitted: TimeLockQueueReset
    await expect(mock.callResetQueue()).to.emit(mock, "TimeLockQueueReset");

    const queueTimeAfterReset = await mock.getQueueTime();
    expect(queueTimeAfterReset).to.equal(0);
    log("Queue time AFTER reset:", queueTimeAfterReset.toString());
  });


  //Ensures that calling the protected function (timelockedMockFunction) without first initiating the timelock queue results in a revert, and confirms that the queue time stays zero
  it("[SHOULD] Prevent execution, the timelock queue was not initiated before calling the protected function 'timelockedMockFunction', queue should be zero", async function() {
    await expect(mock.timelockedMockFunction()).to.be.reverted; //Call the protected function and expect it to be reverted due to a non-initiated timelock queue

    const queueTime = await mock.getQueueTime();
    expect(queueTime).to.equal(0);
    log("Queue time:", queueTime.toString());
  });


  //Verifies that attempting to execute the protected timelockedMockFunction before the required delay period has fully elapsed results in a revert and does not reset the queue time
  it("[SHOULD] Revert execution if called before the delay period is over, queue should not reset", async function() {
    await mock.callStartQueue(); //Start queue
    const DELAY = 30; //30s

    const queueTimeBeforeExecution = await mock.getQueueTime();
    log("Queue time BEFORE execution:", queueTimeBeforeExecution.toString());
    await ethers.provider.send("evm_increaseTime", [DELAY - 2]); //_DELAY is a hardcoded private constant (for gas efficiency reason), we cannot reference it from the Mock contract, invalid execution window
    await ethers.provider.send("evm_mine");

    await expect(mock.timelockedMockFunction()).to.be.reverted;
    const queueTimeAfterExecution = await mock.getQueueTime();
    expect(queueTimeAfterExecution).to.be.gt(0);
    log("Queue time AFTER execution:", queueTimeAfterExecution.toString());
  });


  //Ensures that the protected timelockedMockFunction can be successfully executed exactly at the end of the specified delay period and that the queue time is automatically reset to zero afterwards
  it("[SHOULD] Allow execution exactly at the end of the delay period, queue should reset also after execution", async function() {
    await mock.callStartQueue(); //Start queue
    const DELAY = 30; //30s

    await ethers.provider.send("evm_increaseTime", [DELAY - 1]); //Timestamp at call will be exactly at the end of the delay period, valid execution window
    await ethers.provider.send("evm_mine");

    const queueTimeBeforeExecution = await mock.getQueueTime();
    log("Queue time BEFORE execution:", queueTimeBeforeExecution.toString());

    await expect(mock.timelockedMockFunction()).to.not.be.reverted; //New block is added, the timelocked function transaction is contained in the new block, that is why we need DELAY - 1

    const queueTimeAfterExecution = await mock.getQueueTime();
    expect(queueTimeAfterExecution).to.equal(0);
    log("Queue time AFTER execution:", queueTimeAfterExecution.toString());
  });


  //Ensures that execution of the timelockedMockFunction is correctly reverted if attempted after the grace period (execution window) has expired, and confirms that the queue time is not reset to zero
  it("[SHOULD] Revert execution if the grace period is over, queue should not reset", async function() {
    await mock.callStartQueue(); //Start queue
    const DELAY = 30; //30s
    const GRACE = 60; //60s

    await ethers.provider.send("evm_increaseTime", [DELAY + GRACE]); //Timestamp at call will be greater than (_queueTime + _DELAY + _GRACE_PERIOD), invalid execution window
    await ethers.provider.send("evm_mine");

    const queueTimeBeforeExecution = await mock.getQueueTime();
    log("Queue time BEFORE execution:", queueTimeBeforeExecution.toString());

    await expect(mock.timelockedMockFunction()).to.be.reverted;

    const queueTimeAfterExecution = await mock.getQueueTime();
    expect(queueTimeAfterExecution).to.be.gt(0); //Queue time is expected to be greater than zero
    log("Queue time AFTER execution:", queueTimeAfterExecution.toString());
  });


  //Ensures that the timelockedMockFunction can be successfully executed within the grace period (execution window) following the required delay and that the queue time is properly reset to zero upon execution
  it("[SHOULD] Allow execution within the grace period, queue must be reset after execution", async function() {
    await mock.callStartQueue(); //Start queue
    const DELAY = 30; //30s
    const GRACE = 60; //60s

    await ethers.provider.send("evm_increaseTime", [DELAY + GRACE - 5]); //Before the grace period, valid execution window
    await ethers.provider.send("evm_mine");

    const queueTimeBeforeExecution = await mock.getQueueTime();
    log("Queue time BEFORE execution:", queueTimeBeforeExecution.toString());

    await expect(mock.timelockedMockFunction()).to.not.be.reverted;

    const queueTimeAfterExecution = await mock.getQueueTime();
    expect(queueTimeAfterExecution).to.equal(0); //Queue time is expected to be equal to zero
    log("Queue time AFTER execution:", queueTimeAfterExecution.toString());
  });


  //Ensures that the timelockedMockFunction can be executed successfully at the final valid moment within the grace period (boundary edge case) and confirms that the queue time is reset to zero afterwards
  it("[SHOULD] Allow execution within the grace period, edge case at the end of the grace period, queue must be reset after execution", async function() {
    await mock.callStartQueue(); //Start queue
    const DELAY = 30; //30s
    const GRACE = 60; //60s

    await ethers.provider.send("evm_increaseTime", [DELAY + GRACE - 1]); //Exactly at the end of the grace period, valid execution window
    await ethers.provider.send("evm_mine");

    const queueTimeBeforeExecution = await mock.getQueueTime();
    log("Queue time BEFORE execution:", queueTimeBeforeExecution.toString());

    await expect(mock.timelockedMockFunction()).to.not.be.reverted;

    const queueTimeAfterExecution = await mock.getQueueTime();
    expect(queueTimeAfterExecution).to.equal(0); //Queue time is expected to be equal to zero
    log("Queue time AFTER execution:", queueTimeAfterExecution.toString());
  });


  //Ensures that after successful execution of a timelocked function within the execution window, the queue time is properly reset to zero (validating the automatic cleanup of the timelock state)
  it("[SHOULD] Queue time must be reset after a successful execution of a timelocked function", async function() {
    await mock.callStartQueue(); //Start queue
    const DELAY = 30; //30s

    await ethers.provider.send("evm_increaseTime", [DELAY - 1]); //Valid execution window
    await ethers.provider.send("evm_mine");
    
    const queueTimeBeforeExecution = await mock.getQueueTime();
    log("Queue time BEFORE execution:", queueTimeBeforeExecution.toString());
    
    await mock.timelockedMockFunction();
    
    const queueTimeAfterExecution = await mock.getQueueTime();
    expect(queueTimeAfterExecution).to.equal(0); //Queue time is expected to be equal to zero
    log("Queue time AFTER execution:", queueTimeAfterExecution.toString());
  });


  //Ensures that the timelock queue cannot be reused for multiple executions without being explicitly restarted
  it("[SHOULD] Not allow reusing the queue without restarting it", async function() {
    await mock.callStartQueue(); //Start queue
    const DELAY = 30; //30s
  
    await ethers.provider.send("evm_increaseTime", [DELAY - 1]); //Valid execution window
    await ethers.provider.send("evm_mine");
  
    await expect(mock.timelockedMockFunction()).to.not.be.reverted;
  
    await expect(mock.timelockedMockFunction()).to.be.reverted;
  });
  

  //Verifies that calling callStartQueue (_startQueue) consecutively overwrites the previous queue timestamp with a new one, ensuring the queue can be properly reinitiated
  it("[SHOULD] Overwrite queue timestamp on consecutive startQueue calls", async function() {
    await mock.callStartQueue(); //Start queue 1
    const firstTime = await mock.getQueueTime(); //Log first queue timestamp
  
    await ethers.provider.send("evm_increaseTime", [5]);
    await ethers.provider.send("evm_mine");
  
    await mock.callStartQueue(); //Start queue 2
    const secondTime = await mock.getQueueTime(); //Log second queue timestamp
  
    expect(secondTime).to.be.gt(firstTime); //Second timestamp should be greater than the first one, means it was overwritten as it should be
  });
  

  //Ensures that the timelockedMockFunction reverts when called immediately after initiating the queue
  it("[SHOULD] Revert if called immediately after queue start", async function() {
    await mock.callStartQueue(); //Start queue
    await expect(mock.timelockedMockFunction()).to.be.reverted; //Call timelocked function immediately, should fail
  });


  //Ensures that if a timelocked function fails during execution and reverts, the queue time remains unchanged, preserving the timelock state in the event of execution failure in the protected function body
  it("[SHOULD] Not reset the queue in case the timelocked protected function fails and does not finish execution, the modifier should not reach the the code line that resets the queue", async function() {
    await mock.callStartQueue(); //Start queue
    const DELAY = 30; //30s

    await ethers.provider.send("evm_increaseTime", [DELAY - 1]); //Valid execution window
    await ethers.provider.send("evm_mine");

    await expect(mock.timelockedMockFunctionWhichReverts()).to.be.reverted; //Call timelocked function which fails and does not finish execution
    
    const queueTime = await mock.getQueueTime();
    expect(queueTime).to.be.gt(0); //Queue should be greater than zero, it should not reset
    log("Queue time after failed protected function execution: ", queueTime);
  });
  

  //Ensures that calling both startQueue and the timelocked function in the same block results in a revert
  it("[SHOULD] Fail if startQueue and timelocked function are called in the same block", async function() {
    await expect(mock.callStartAndTimelockedInSameBlock()).to.be.reverted;
  });
  

  //Verifies that the timelock mechanism remains consistent even when using an extremely large future timestamp
  it("[SHOULD] handle extremely large future timestamps without breaking logic", async function() {
    await mock.callStartQueue(); //Start queue
  
    const hundredYearsInSeconds = 100 * 365 * 24 * 60 * 60; //3153600000 seconds
    await ethers.provider.send("evm_increaseTime", [hundredYearsInSeconds]);
    await ethers.provider.send("evm_mine");
  
    //Try calling the timelocked function, it should revert due to being far past the grace period
    await expect(mock.timelockedMockFunction()).to.be.reverted;
  
    const queueTime = await mock.getQueueTime();
    expect(queueTime).to.be.gt(0); //Queue should still exist (is initiated) since the call failed
  });


  //Ensures that the timelock queue can be successfully restarted and used for a subsequent valid execution (single-use execution per queue cycle, re-queuing ability)
  it("[SHOULD] Revert the second function call within the same block, should allow re-queue and execution", async function() {
    await mock.callStartQueue(); //Start queue
    const DELAY = 30; //30s
    await ethers.provider.send("evm_increaseTime", [DELAY - 1]); //Valid execution window
    await ethers.provider.send("evm_mine");

    await expect(mock.timelockedMockFunction()).to.not.be.reverted;
    await expect(mock.timelockedMockFunction()).to.be.reverted;

    await mock.callStartQueue(); //Start queue
    await ethers.provider.send("evm_increaseTime", [DELAY - 1]); //Valid execution window
    await ethers.provider.send("evm_mine");

    await expect(mock.timelockedMockFunction()).to.not.be.reverted;
  });
  
});