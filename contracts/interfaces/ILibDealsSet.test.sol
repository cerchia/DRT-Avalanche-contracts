// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { LibStructStorage } from "../libraries/LibStructStorage.sol";

interface ILibDealsSet {
	// Data structure for efficient CRUD operations
	// Holds an array of deals, and a mapping pointing from dealId to deal's index in the array
	struct DealsSet {
		// mapping(dealId => _deals array index position)
		mapping(uint256 => uint256) _dealsIndexer;
		// deals array
		LibStructStorage.Deal[] _deals;
		// keeping track of last inserted deal id and increment when adding new items
		uint256 _lastDealId;
	}

	function insert(LibStructStorage.Deal memory deal) external returns (uint256 returnedDealId);

	function deleteById(uint256 dealId) external;

	function count() external view returns (uint);

	function exists(uint256 dealId) external view returns (bool);

	function getIndex(uint256 dealId) external view returns (uint256 indexInDealsArray);

	function getById(uint256 dealId) external view returns (LibStructStorage.Deal memory deal);

	function getLastDealId() external view returns (uint256 lastDealId);
}
