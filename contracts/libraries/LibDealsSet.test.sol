// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ILibDealsSet } from "../interfaces/ILibDealsSet.test.sol";

import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibDealsSet } from "../libraries/LibDealsSet.sol";

contract LibDealsSetTest is ILibDealsSet {
	using LibDealsSet for LibDealsSet.DealsSet;
	LibDealsSet.DealsSet private _dealsSet;

	event DealCreated(uint256 dealId);

	function insert(LibStructStorage.Deal memory deal) external override returns (uint256 returnedDealId) {
		uint256 dealId = _dealsSet.insert(deal);
		emit DealCreated(dealId);

		return dealId;
	}

	function deleteById(uint256 dealId) external override {
		require(_dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		_dealsSet.deleteById(dealId);
	}

	function count() external view override returns (uint256) {
		return _dealsSet.count();
	}

	function exists(uint256 dealId) external view override returns (bool) {
		return _dealsSet.exists(dealId);
	}

	function getIndex(uint256 dealId) external view override returns (uint256 indexInDealsArray) {
		require(_dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		return _dealsSet.getIndex(dealId);
	}

	function getById(uint256 dealId) external view override returns (LibStructStorage.Deal memory deal) {
		require(_dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		return _dealsSet.getById(dealId);
	}

	function getLastDealId() external view override returns (uint256 lastDealId) {
		return _dealsSet.getLastDealId();
	}
}
