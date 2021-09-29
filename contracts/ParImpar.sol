//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "./Commit.sol";

/*
	Par - True
	Impar - False
*/

contract ParImpar {
	using SimpleCommit for SimpleCommit.CommitType;

	enum ContractState {
		Idle,
		Fulfilled
	}

	address payable owner;
	address payable secondPlayer;
	uint256 timeLimit;
	ContractState state;

	mapping(address => SimpleCommit.CommitType) moves;

	constructor(bytes32 hashedCommit, bool guess) payable {
		SimpleCommit.CommitType memory c;
		c.commit(hashedCommit, guess, msg.value);

		owner = payable(msg.sender);
		moves[msg.sender] = c;
		timeLimit = block.timestamp + 10 minutes;
		state = ContractState.Idle;
	}

	function play(bytes32 hashedCommit, bool guess) public payable {
		require(msg.sender != owner, "Sorry, you cannot play with yourself.");
		require(
			secondPlayer != msg.sender,
			"You have already done a move. You should reveal your move now."
		);
		require(
			secondPlayer == address(0),
			"Sorry, another player has already played a move! You might have to wait the player fufill the game or give up."
		);

		secondPlayer = payable(msg.sender);

		SimpleCommit.CommitType memory c;

		c.commit(hashedCommit, guess, msg.value);

		moves[msg.sender] = c;
	}

	function revealMove(bool value, bytes32 nonce) public view {
		require(
			msg.sender == owner || msg.sender == secondPlayer,
			"Only the players can reveal the moves"
		);

		SimpleCommit.CommitType memory c = moves[msg.sender];
		// se ele revelar incorretamente ele não consegue revelar de novo
		require(
			c.getState() == SimpleCommit.CommitStatesType.Waiting,
			"You can only reveal a unrevealed commit"
		);

		c.reveal(nonce, value);

		if (c.isCorrect()) {
			return;
		} else {
			revert(
				"Sorry, your value + nonce does not match your registered commit"
			);
		}
	}

	function finishGame() public payable {
		require(
			state == ContractState.Idle,
			"Sorry, the game has already finished. Start another contract if you wanna play."
		);

		SimpleCommit.CommitType memory ownerCommit = moves[owner];
		SimpleCommit.CommitType memory playerCommit = moves[secondPlayer];

		if (block.timestamp >= timeLimit) {
			//Caso o tempo limite passou ganha quem revelou, caso algum deles não revelou
			//Se nenhum deles revelou o dinheiro é retornado para a origem
			if (
				playerCommit.getState() ==
				SimpleCommit.CommitStatesType.Waiting &&
				ownerCommit.getState() == SimpleCommit.CommitStatesType.Revealed
			) {
				owner.transfer(
					playerCommit.getMoney() + ownerCommit.getMoney()
				);
				state = ContractState.Fulfilled;
				return;
			} else if (
				playerCommit.getState() ==
				SimpleCommit.CommitStatesType.Revealed &&
				ownerCommit.getState() == SimpleCommit.CommitStatesType.Waiting
			) {
				secondPlayer.transfer(
					playerCommit.getMoney() + ownerCommit.getMoney()
				);
				state = ContractState.Fulfilled;
				return;
			} else if (
				playerCommit.getState() ==
				SimpleCommit.CommitStatesType.Waiting &&
				ownerCommit.getState() == SimpleCommit.CommitStatesType.Waiting
			) {
				owner.transfer(ownerCommit.getMoney());
				secondPlayer.transfer(playerCommit.getMoney());
				state = ContractState.Fulfilled;
				return;
			}
		}

		require(
			ownerCommit.isCorrect(),
			"The owner still didnt reveal his commit"
		);
		require(
			playerCommit.isCorrect(),
			"The player still didnt reveal his commit"
		);

		// Jogador 1 perde quando..
		if (evaluateIfPlayer1Loses(ownerCommit, playerCommit)) {
			secondPlayer.transfer(
				ownerCommit.getMoney() + playerCommit.getMoney()
			);
			state = ContractState.Fulfilled;
			return;
		}

		// Jogador 2 perde quando..
		if (evaluateIfPlayer2Loses(ownerCommit, playerCommit)) {
			owner.transfer(ownerCommit.getMoney() + playerCommit.getMoney());
			state = ContractState.Fulfilled;
			return;
		}

		// Caso não caia em nenhum dos ifs então foi um empate, o dinheiro é retornado para a origem
		owner.transfer(ownerCommit.getMoney());
		secondPlayer.transfer(playerCommit.getMoney());
		state = ContractState.Fulfilled;
		return;
	}

	function evaluateIfPlayer1Loses(
		SimpleCommit.CommitType memory player1Commit,
		SimpleCommit.CommitType memory player2Commit
	) private pure returns (bool) {
		if (
			(player1Commit.getJogada() == true &&
				player1Commit.getGuess() == true &&
				player2Commit.getJogada() == false &&
				player2Commit.getGuess() == false) ||
			(player1Commit.getJogada() == false &&
				player1Commit.getGuess() == false &&
				player2Commit.getJogada() == false &&
				player2Commit.getGuess() == true) ||
			(player1Commit.getJogada() == true &&
				player1Commit.getGuess() == false &&
				player2Commit.getJogada() == true &&
				player2Commit.getGuess() == true) ||
			(player1Commit.getJogada() == false &&
				player1Commit.getGuess() == true &&
				player2Commit.getJogada() == true &&
				player2Commit.getGuess() == false)
		) {
			return true;
		}
		return false;
	}

	function evaluateIfPlayer2Loses(
		SimpleCommit.CommitType memory player1Commit,
		SimpleCommit.CommitType memory player2Commit
	) private pure returns (bool) {
		if (
			(player2Commit.getJogada() == true &&
				player2Commit.getGuess() == true &&
				player1Commit.getJogada() == false &&
				player1Commit.getGuess() == false) ||
			(player2Commit.getJogada() == false &&
				player2Commit.getGuess() == false &&
				player1Commit.getJogada() == false &&
				player1Commit.getGuess() == true) ||
			(player2Commit.getJogada() == true &&
				player2Commit.getGuess() == false &&
				player1Commit.getJogada() == true &&
				player1Commit.getGuess() == true) ||
			(player2Commit.getJogada() == false &&
				player2Commit.getGuess() == true &&
				player1Commit.getJogada() == true &&
				player1Commit.getGuess() == false)
		) {
			return true;
		}
		return false;
	}
}
