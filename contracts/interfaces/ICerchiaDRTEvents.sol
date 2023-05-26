// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICerchiaDRTEvents {
	// When an owner adds a new standard
	event OwnerAddedNewStandard(
		address indexed owner,
		string symbol,
		bytes32 configurationId,
		int128 strike,
		uint128 feeInBps,
		uint64 startDate,
		uint64 maturityDate,
		uint8 exponentOfTenMultiplierForStrike
	);

	// When an owner adds a new token
	event OwnerAddedNewToken(address indexed owner, string symbol, address token);

	// When an owner adds a new approved KYX Provider
	event OwnerAddedNewKYXProvider(address indexed owner, string name, address indexed kyxProviderAddress);

	// When a user creates a BidLive deal
	event NewBid(
		uint256 indexed dealId,
		address indexed initiator,
		string standardSymbol,
		string tokenDenomination,
		uint64 expiryDate,
		uint128 notional,
		uint128 premium
	);

	// When a user creates an AskLive deal
	event NewAsk(
		uint256 indexed dealId,
		address indexed initiator,
		string standardSymbol,
		string tokenDenomination,
		uint64 expiryDate,
		uint128 notional,
		uint128 premium
	);

	// When a user cancels their own deal
	event UserUpdateDealToCancel(uint256 indexed dealId, address indexed initiator, uint128 fundsReturned);

	// When a user matches another user's deal, turning the deal's state into Matched
	event Match(uint256 indexed dealId, address indexed matcher, uint128 fundsSent);

	// When AnyAccountInitiateIndexDataUpdate was called, but level already exists for configurationId + timestamp
	event AnyAccountInitiateIndexDataUpdateAlreadyAvailable(bytes32 configurationId, uint64 timestamp, int128 level);

	// When data is successfully returned to CerchiaDRT Diamond, from Oracle Diamond
	event IndexDataCallBackSuccess(bytes32 configurationId, uint64 timestamp, int128 level);

	// When AutomaticDissolution triggers, because of faulty oracle during index data update or settlement
	event AutomaticDissolution(address indexed sender, bytes32 indexed configurationId, uint64 timestamp);

	// When a user claims their funds from a deal, after AutomaticDissolution happens
	event Claimed(uint256 indexed dealId, address claimer, uint128 fundsClaimed);

	// Emmited by AnyAccountProcessContingentSettlement
	event BidLiveDealExpired(uint256 indexed dealId, address indexed initiator, uint128 fundsReturned);
	event AskLiveDealExpired(uint256 indexed dealId, address indexed initiator, uint128 fundsReturned);
	event MatchedDealWentLive(uint256 indexed dealId);

	event LiveDealTriggered(
		uint256 indexed dealId,
		address indexed buyer,
		uint128 buyerReceived,
		address indexed feeAddress,
		uint128 feeAddressReceived
	);

	event LiveDealMatured(
		uint256 indexed dealId,
		address indexed seller,
		uint128 sellerReceived,
		address indexed feeAddress,
		uint128 feeAddressReceived
	);

	// When an owner deletes one of the standards
	event OwnerDeletedStandard(address indexed owner, string symbol);

	// When an owner deletes one of the tokens
	event OwnerDeletedToken(address indexed owner, string symbol);

	// When an owner adds an approved KYX Provider
	event OwnerDeletedKYXProvider(address indexed owner, string name, address indexed kyxProviderAddress);
}
