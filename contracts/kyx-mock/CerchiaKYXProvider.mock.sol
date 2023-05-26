// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRT } from "../interfaces/ICerchiaDRT.sol";
import { IMatchDeal } from "../interfaces/IMatchDeal.sol";
import { IClaimBackFacet } from "../interfaces/IClaimBackFacet.sol";
import { IAnyAccountOperationsFacet } from "../interfaces/IAnyAccountOperationsFacet.sol";
import { ICerchiaKYXProvider } from "./ICerchiaKYXProvider.mock.sol";

contract CerchiaKYXProvider is ICerchiaKYXProvider {
	address private immutable _cerchiaDiamondAddress;

	constructor(address cerchiaDiamondAddress) {
		_cerchiaDiamondAddress = cerchiaDiamondAddress;
	}

	function userCreateNewDealAsBid(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external override {
		return
			ICerchiaDRT(_cerchiaDiamondAddress).userCreateNewDealAsBid(
				msg.sender,
				symbol,
				denomination,
				notional,
				premium,
				expiryDate
			);
	}

	function userCreateNewDealAsAsk(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external override {
		return
			ICerchiaDRT(_cerchiaDiamondAddress).userCreateNewDealAsAsk(
				msg.sender,
				symbol,
				denomination,
				notional,
				premium,
				expiryDate
			);
	}

	function userUpdateDealToCancel(uint256 dealId) external override {
		return ICerchiaDRT(_cerchiaDiamondAddress).userUpdateDealToCancel(msg.sender, dealId);
	}

	function userUpdateDealFromBidToMatched(uint256 dealId) external override {
		return IMatchDeal(_cerchiaDiamondAddress).userUpdateDealFromBidToMatched(msg.sender, dealId);
	}

	function userUpdateDealFromAskToMatched(uint256 dealId) external override {
		return IMatchDeal(_cerchiaDiamondAddress).userUpdateDealFromAskToMatched(msg.sender, dealId);
	}

	function initiateIndexDataUpdate(bytes32 configurationId, uint64 timestamp) external override {
		return
			IAnyAccountOperationsFacet(_cerchiaDiamondAddress).initiateIndexDataUpdate(
				msg.sender,
				configurationId,
				timestamp
			);
	}

	function processContingentSettlement(uint64 timestamp, uint256 dealId) external override {
		return
			IAnyAccountOperationsFacet(_cerchiaDiamondAddress).processContingentSettlement(
				msg.sender,
				timestamp,
				dealId
			);
	}

	function claimBack(uint256 dealId) external override {
		return IClaimBackFacet(_cerchiaDiamondAddress).claimBack(msg.sender, dealId);
	}
}
