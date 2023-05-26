// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IGetEntityFacet } from "../interfaces/IGetEntityFacet.sol";

import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibAccessControlStorage } from "../libraries/LibAccessControlStorage.sol";
import { LibDealsSet } from "../libraries/LibDealsSet.sol";

import { LibDealsSet } from "../libraries/LibDealsSet.sol";
import { LibCommonOperations } from "../libraries/LibCommonOperations.sol";

import { LibCerchiaDRTStorage as Storage } from "../libraries/LibCerchiaDRTStorage.sol";

/**
 * @title  CerchiaDRT Diamond Getters Implementation
 */
contract GetEntityFacet is IGetEntityFacet {
	using LibDealsSet for LibDealsSet.DealsSet;

	/**
	 * @dev     Settlement and Index levels related functions should only be called for exact timestamps not in the future
	 * @param   unixTimestamp  Unix Epoch to be checked against the current time on the blockchain
	 */
	modifier isValidBlockTimestamp(uint64 unixTimestamp) {
		require(
			LibCommonOperations._isValidBlockTimestamp(unixTimestamp),
			LibStructStorage.TIMESTAMP_SHOULD_BE_VALID_BLOCK_TIMESTAMP
		);
		_;
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function getStandardSymbols() external view returns (string[] memory) {
		return Storage.getStorage()._standardsKeys;
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function getStandard(string calldata symbol) external view returns (LibStructStorage.Standard memory) {
		return Storage.getStorage()._standards[symbol];
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function getTokenSymbols() external view returns (string[] memory) {
		return Storage.getStorage()._tokensKeys;
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function getTokenAddress(string calldata symbol) external view returns (address) {
		return Storage.getStorage()._tokens[symbol];
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 * @dev Reverts if there is no deal with this dealId
	 */
	function getDeal(uint256 dealId) external view returns (LibStructStorage.Deal memory) {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		require(s._dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		return s._dealsSet.getById(dealId);
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 * @dev Intended to be used by off-chain Settlement script: get all deal ids + run Settlement for each deal
	 */
	function getDealIds() external view returns (uint256[] memory) {
		LibDealsSet.DealsSet storage _dealsSet = Storage.getStorage()._dealsSet;

		uint256 dealsCount = _dealsSet.count();
		uint256[] memory _dealIds = new uint256[](dealsCount);

		for (uint256 i; i < dealsCount; ) {
			_dealIds[i] = _dealsSet._deals[i].id;

			unchecked {
				++i;
			}
		}

		return _dealIds;
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function getIndexLevelTimestamps(bytes32 configurationId) external view returns (uint64[] memory) {
		return Storage.getStorage()._indexLevelTimestamps[configurationId];
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function getUserActiveDealsCount(address userAddress, bytes32 configurationId) external view returns (uint32) {
		return Storage.getStorage()._userActiveDealsCount[userAddress][configurationId];
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function isRestrictedToUserClaimBack() external view returns (bool) {
		return LibAccessControlStorage.getStorage()._usersCanOnlyClaimBack;
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function getIsDeactivatedForOwners() external view returns (bool) {
		return LibAccessControlStorage.getStorage()._isDeactivatedForOwners;
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function getIsDeactivatedForOperators() external view returns (bool) {
		return LibAccessControlStorage.getStorage()._isDeactivatedForOperators;
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function isInDissolution() external view returns (bool) {
		return Storage.getStorage()._isInDissolution;
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function isLevelSet(
		bytes32 configurationId,
		uint64 timestamp
	) external view isValidBlockTimestamp(timestamp) returns (bool) {
		return Storage.getStorage()._indexLevels[configurationId][timestamp].exists;
	}

	/**
	 * @inheritdoc IGetEntityFacet
	 */
	function getLevel(
		bytes32 configurationId,
		uint64 timestamp
	) external view isValidBlockTimestamp(timestamp) returns (int128) {
		return Storage.getStorage()._indexLevels[configurationId][timestamp].value;
	}

	function getKYXProvidersAddresses() external view override returns (address[] memory providerAddresses) {
		return LibAccessControlStorage.getStorage()._kyxProvidersKeys;
	}

	function getKYXProviderName(
		address kyxProviderAddress
	) external view override returns (string memory kyxProviderName) {
		return LibAccessControlStorage.getStorage()._kyxProviders[kyxProviderAddress];
	}
}
