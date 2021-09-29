//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

library SimpleCommit {
	enum CommitStatesType {
		Waiting,
		Revealed
	}

	struct CommitType {
		bytes32 commited;
		uint256 money;
		bool jogada;
		bool guess;
		bool verified;
		CommitStatesType currentState;
	}

	function commit(
		CommitType memory c,
		bytes32 hashedCommit,
		bool guess,
		uint256 money
	) public pure {
		c.commited = hashedCommit;
		c.guess = guess;
		c.money = money;
		c.verified = false;
		c.currentState = CommitStatesType.Waiting;
	}

	function reveal(
		CommitType memory c,
		bytes32 nonce,
		bool v
	) public pure {
		require(c.currentState == CommitStatesType.Waiting);

		bytes32 ver = sha256(abi.encodePacked(nonce, v));
		c.currentState = CommitStatesType.Revealed;

		if (ver == c.commited) {
			c.verified = true;
			c.jogada = v;
		}
	}

	function isCorrect(CommitType memory c) public pure returns (bool) {
		require(c.currentState == CommitStatesType.Revealed);

		return c.verified;
	}

	function getMoney(CommitType memory c) public pure returns (uint256) {
		require(c.currentState == CommitStatesType.Revealed);
		require(c.verified == true);

		return c.money;
	}

	function getJogada(CommitType memory c) public pure returns (bool) {
		require(c.currentState == CommitStatesType.Revealed);
		require(c.verified == true);

		return c.jogada;
	}

	function getState(CommitType memory c)
		public
		pure
		returns (CommitStatesType)
	{
		return c.currentState;
	}

	function getGuess(CommitType memory c) public pure returns (bool) {
		return c.guess;
	}
}
