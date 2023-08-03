// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WordleGame {
    // Constants
    uint256 constant ANSWER_LENGTH = 8;
    bytes32 constant ANSWER_HASH =
        0x60c4004508ddcd8d1b0ea1c56ed1e5679d756d72e40f1a00820dbe5d9f69ff63;
    uint256 constant ATTEMPTS_LIMIT = 6;
    uint256 constant PRIZE = 10 ether; // 10 APT

    // Player data
    struct PlayerAttempt {
        bytes8 word;
        bytes32[] letterHashes;
        bool[] letterCorrectness;
    }

    struct Player {
        PlayerAttempt[] attempts;
        bool wordGuessed;
    }

    // State variables
    address public owner;
    Player[] public players;

    // Events
    event GuessWordAttempt(
        uint256 indexed attemptIndex,
        bytes8 word,
        bytes32[] letterHashes,
        bool[] letterCorrectness
    );
    event SubmitCorrectAnswer(uint256 indexed attemptIndex);

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Function to reset the game and allow players to start a new game by sending some ETH
    function resetGame() external payable {
        require(
            msg.sender == owner,
            "Only the contract owner can reset the game."
        );
        require(msg.value >= PRIZE, "Insufficient ETH sent for the prize.");
        delete players;
    }

    // Function to make a guess attempt and verify if the guess is correct
    function guessWord(bytes8 word) external {
        require(word.length == ANSWER_LENGTH, "Incorrect word length.");
        require(players.length < ATTEMPTS_LIMIT, "Attempts limit reached.");

        bytes32 wordHash = keccak256(abi.encodePacked(word));
        bool isCorrect = wordHash == ANSWER_HASH;

        Player memory newPlayer;
        newPlayer.attempts = new PlayerAttempt[](0);
        newPlayer.wordGuessed = false;

        players.push(newPlayer);
        uint256 currentAttempt = players.length - 1;
        Player storage currentPlayer = players[currentAttempt];

        bytes32[] memory letterHashes = new bytes32[](ANSWER_LENGTH);
        bool[] memory letterCorrectness = new bool[](ANSWER_LENGTH);

        for (uint256 i = 0; i < ANSWER_LENGTH; i++) {
            bytes32 letterHash = getLetterHash(i);
            bytes32 guessLetterHash = keccak256(
                abi.encodePacked(word[i], i, msg.sender, block.timestamp)
            );

            letterHashes[i] = guessLetterHash;
            letterCorrectness[i] = guessLetterHash == letterHash;
        }

        currentPlayer.attempts.push(
            PlayerAttempt(word, letterHashes, letterCorrectness)
        );

        emit GuessWordAttempt(
            currentAttempt,
            word,
            letterHashes,
            letterCorrectness
        );

        if (isCorrect) {
            currentPlayer.wordGuessed = true;
            emit SubmitCorrectAnswer(currentAttempt);
        }
    }

    // Function to get the attempts made by a player
    function getGuessAttempts(
        uint256 playerIndex
    ) external view returns (PlayerAttempt[] memory) {
        require(playerIndex < players.length, "Invalid player index.");
        return players[playerIndex].attempts;
    }

    // Function to get the hash of a letter depending on the provided index
    function getLetterHash(uint256 index) internal pure returns (bytes32) {
        require(index < ANSWER_LENGTH, "Letter index out of bounds.");
        if (index == 0)
            return
                0x3eecb4a5c11c8bab18ddad1d268c827aaabb17c83f51869832a5af15efdedfcb;
        if (index == 1)
            return
                0xe63a84c18447bfca5c67b20a58fc6a4fefa762e4fa0e6b3b2e46f64daba345e5;
        if (index == 2)
            return
                0xd034b2b544e4ffb619a9c156ae578fe21f38eb0997f097ca9569807ca157f4f6;
        if (index == 3)
            return
                0x6920014bef534e7eea89545a50d6aef0921f1972efcddce9f22f04a45b47d472;
        if (index == 4)
            return
                0xc837f30e97185c362830b324e58a3e6782095ee8457109b27f03819ff516e121;
        if (index == 5)
            return
                0xc837f30e97185c362830b324e58a3e6782095ee8457109b27f03819ff516e121;
        if (index == 6)
            return
                0x345baaa13bbe3a40695db7697fbe3f64206323b77cf3635902106f9f29667361;
        if (index == 7)
            return
                0x037f4095baddc6f37fde4740c304b1691512d2fc9cf7ede8a93b8c9ec3d1fe07;
    }
}
