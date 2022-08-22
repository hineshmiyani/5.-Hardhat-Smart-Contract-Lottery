// Raffle
// Enter the lottery (paying some amount)
// pick a random winner (verifiably random)
// Winner to bo selected every X minutes -> completly automated
// Chainlink Oracle -> Randomness, Automated Execution (Chainlink Keeper)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpKeepNotNedded(
  uint256 currentBalance,
  uint256 numPlayers,
  uint256 s_raffleState
);

/**
 *  @title A sample Raffle Contract
 *  @author Hinesh Miyani
 *  @notice This contract is for creating an untermperable decentralized  smart contract
 *  @dev This implements Chainlink VRF v2
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
  /* Tyoe Declarations */
  enum RaffleState {
    OPEN,
    CALCULATING
  } // uint256 0 = OPEN, 1 = CALCULATING

  /* State Variables */
  uint256 private immutable i_entranceFee;
  address payable[] private s_players;
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  bytes32 private immutable i_gasLane; // The gas lane key hash value, which is the maximum gas price you are willing to pay for a request in wei
  uint64 private immutable i_subscriptionId; // The subscription ID that this contract uses for funding requests.
  uint32 private immutable i_callBackGasLimit; // he limit for how much gas to use for the callback request to your contract's fulfillRandomWords() function.
  uint16 private constant REQUEST_CONFIRMATIONS = 3; // How many confirmations the Chainlink node should wait before responding.
  uint32 private constant NUM_WORDS = 1; // How many random number that we want to get

  // Lottery Variables
  address private s_recentWinner;
  RaffleState private s_raffleState;
  uint256 private s_lastTimeStamp;
  uint256 private immutable i_interval;

  /* Events */
  // Named events with the function name reversed
  event RaffleEnter(address indexed player);
  event RequestedRaffleWinner(uint256 indexed requestId);
  event WinnerPicked(address indexed winner);

  /* Functions */
  // vrfCoordinator is address that verify random number
  constructor(
    address vrfCoordinatorV2, // contract
    uint256 entranceFee,
    bytes32 gasLane,
    uint64 subscriptionId,
    uint32 callbackGasLimit,
    uint256 interval
  ) VRFConsumerBaseV2(vrfCoordinatorV2) {
    i_entranceFee = entranceFee;
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_callBackGasLimit = callbackGasLimit;
    s_raffleState = RaffleState.OPEN;
    s_lastTimeStamp = block.timestamp;
    i_interval = interval;
  }

  // payalbe attribute add into function when,
  // function receive or send ether
  function enterRaffle() external payable {
    // require(msg.value > i_entranceFee, "Not enough ETH!")
    if (msg.value < i_entranceFee) {
      revert Raffle__NotEnoughETHEntered();
    }
    if (s_raffleState != RaffleState.OPEN) {
      revert Raffle__NotOpen();
    }
    s_players.push(payable(msg.sender)); // type cast msg.sender into payable address

    // Emit an event when we update a dynamic array or mapping
    emit RaffleEnter(msg.sender);
  }

  /************ Implementing Chainlink VRF ************/
  /************ Implementing Chainlink Keepers - checkUpkeep ************/
  /**
   * @dev This is the function that the chainlink keeper nodes call
   * they look gor the 'upKeepNeeded' to return true.
   * The following should be true in order to return true.
   * 1. Our time interval should have passed
   * 2. The lottery should have at least 1 player, and have some ETH
   * 3. Our subscription is funded with LINK.
   * 4. The lottery should be in an 'open' state.
   */
  function checkUpkeep(
    bytes memory /* checkData */
  )
    public
    override
    returns (
      bool upkeepNeeded,
      bytes memory /* performData */
    )
  {
    bool isOpen = (RaffleState.OPEN == s_raffleState);
    bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
    bool hasPlayers = (s_players.length > 0);
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
  }

  /************ Implementing Chainlink VRF - The Request ************/
  /************ Implementing Chainlink Keepers - performUpkeep ************/
  function performUpkeep(
    bytes calldata /* performData  */
  ) external override {
    // Request the random number
    // once we get it, do something with it
    // 2 transaction process

    (bool upkeepNeeded, ) = checkUpkeep("");
    if (!upkeepNeeded) {
      revert Raffle__UpKeepNotNedded(
        address(this).balance,
        s_players.length,
        uint256(s_raffleState)
      );
    }
    s_raffleState = RaffleState.CALCULATING;
    uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_gasLane, // gasLane
      i_subscriptionId,
      REQUEST_CONFIRMATIONS,
      i_callBackGasLimit,
      NUM_WORDS
    );

    emit RequestedRaffleWinner(requestId);
  }

  /************ Implementing Chainlink VRF - The FulFill ************/
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable recentWinner = s_players[indexOfWinner];
    s_recentWinner = recentWinner;
    s_raffleState = RaffleState.OPEN;
    s_players = new address payable[](0); // reset players array after pick a winner
    s_lastTimeStamp = block.timestamp; // reset s_lastTimeStamp after pick a winner

    (bool success, ) = recentWinner.call{value: address(this).balance}("");
    if (!success) {
      revert Raffle__TransferFailed();
    }

    emit WinnerPicked(recentWinner);
  }

  /* View / Pure functions */

  function getEntranceFee() public view returns (uint256 entranceFee) {
    return i_entranceFee;
  }

  function getPlayer(uint256 index) public view returns (address) {
    return s_players[index];
  }

  function getRecentWinner() public view returns (address) {
    return s_recentWinner;
  }

  function getRaffleState() public view returns (RaffleState) {
    return s_raffleState;
  }

  function getNumWords() public pure returns (uint256) {
    return NUM_WORDS;
  }

  function getNumberOfPlayers() public view returns (uint256) {
    return s_players.length;
  }

  function getLatestTimeStamp() public view returns (uint256) {
    return s_lastTimeStamp;
  }

  function getRequestConfirmations() public pure returns (uint256) {
    return REQUEST_CONFIRMATIONS;
  }

  function getInterval() public view returns (uint256) {
    return i_interval;
  }

  function getSubscriptionId() public view returns (uint64) {
    return i_subscriptionId;
  }
}
