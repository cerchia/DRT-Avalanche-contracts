// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICerchiaKYXProvider {
	function userCreateNewDealAsBid(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	function userCreateNewDealAsAsk(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	function userUpdateDealToCancel(uint256 dealId) external;

	function userUpdateDealFromBidToMatched(uint256 dealId) external;

	function userUpdateDealFromAskToMatched(uint256 dealId) external;

	function initiateIndexDataUpdate(bytes32 configurationId, uint64 timestamp) external;

	function processContingentSettlement(uint64 timestamp, uint256 dealId) external;

	function claimBack(uint256 dealId) external;
}
