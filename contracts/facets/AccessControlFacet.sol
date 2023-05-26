// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IAccessControl } from "../interfaces/IAccessControl.sol";

import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibAccessControlStorage } from "../libraries/LibAccessControlStorage.sol";
import { LibCerchiaDRTStorage } from "../libraries/LibCerchiaDRTStorage.sol";
import { LibDealsSet } from "../libraries/LibDealsSet.sol";

// Since we are using DiamondPattern, one can no longer directly inherit AccessControl from Openzeppelin.
// This happens because DiamondPattern implies a different storage structure,
// but AccessControl handles memory internally.
// Following is the OpenZeppelin work, slightly changed to fit our use-case.

/**
 *  @title CerchiaDRT Diamond Access Control Implementation
 *  @dev    Inspired by OpenZeppelin's AccessControl Roles implementation, but adapted to Diamond Pattern storage
 *  @dev    Also implements activation/deactivations of functionalities by owners
 */
contract AccessControlFacet is IAccessControl {
	using LibDealsSet for LibDealsSet.DealsSet;

	/**
	 * @dev  Prevents initializating more than once
	 */
	modifier notInitialized() {
		LibAccessControlStorage.AccessControlStorage storage s = LibAccessControlStorage.getStorage();

		require(!s._initialized, LibStructStorage.ACCESS_CONTROL_FACET_ALREADY_INITIALIZED);
		s._initialized = true;
		_;
	}

	/**
	 * @dev  Prevents calling a function from anyone not having the OWNER_ROLE role
	 */
	modifier isOwner() {
		require(hasRole(LibStructStorage.OWNER_ROLE, msg.sender), LibStructStorage.SHOULD_BE_OWNER);
		_;
	}

	/**
	 * @inheritdoc IAccessControl
	 * @dev    Similar to OpenZeppelin's Transparent Proxy initialize function
	 * @dev    Intended to be called after deployment, on the Diamond, to alter Diamond's storage
	 * @dev    Currently called from off-chain, after all contracts' creation, through a script
	 * @dev    All addresses should be unique, no address can have multiple roles or responsabilities
	 */
	function initAccessControlFacet(
		address[3] calldata owners,
		address[3] calldata operators,
		address feeAddress,
		address oracleAddress
	) external notInitialized {
		_addOwner(owners[0]);
		_addOwner(owners[1]);
		_addOwner(owners[2]);

		_addOperator(operators[0]);
		_addOperator(operators[1]);
		_addOperator(operators[2]);

		_setFeeAddress(feeAddress);
		_setOracleAddress(oracleAddress);
	}

	/**
	 * @inheritdoc IAccessControl
	 * @dev  Deactivate all functions (owners, operators, users), except user claimback
	 * @dev  Should revert if there are still existing deals, otherwise it would lock users' funds
	 */
	function ownerDeactivateAllFunctions() external isOwner {
		LibAccessControlStorage.AccessControlStorage storage accessControlStorage = LibAccessControlStorage
			.getStorage();

		require(!accessControlStorage._isDeactivatedForOwners, LibStructStorage.DEACTIVATED_FOR_OWNERS);

		require(LibCerchiaDRTStorage.getStorage()._dealsSet.count() == 0, LibStructStorage.THERE_ARE_STILL_DEALS_LEFT);

		accessControlStorage._usersCanOnlyClaimBack = true;
		accessControlStorage._isDeactivatedForOwners = true;
		accessControlStorage._isDeactivatedForOperators = true;
	}

	/**
	 * @inheritdoc IAccessControl
	 * @dev  Should revert if there are still existing deals, otherwise it would lock users' funds,
	 *       or if owners are deactivated
	 */
	function ownerDeactivateUserFunctions() external isOwner {
		LibAccessControlStorage.AccessControlStorage storage accessControlStorage = LibAccessControlStorage
			.getStorage();

		require(!accessControlStorage._isDeactivatedForOwners, LibStructStorage.DEACTIVATED_FOR_OWNERS);

		require(LibCerchiaDRTStorage.getStorage()._dealsSet.count() == 0, LibStructStorage.THERE_ARE_STILL_DEALS_LEFT);

		accessControlStorage._usersCanOnlyClaimBack = true;
	}

	/**
	 * @inheritdoc IAccessControl
	 * @dev  Should revert if owners are deactivated
	 */
	function ownerDeactivateOperatorFunctions() external isOwner {
		LibAccessControlStorage.AccessControlStorage storage accessControlStorage = LibAccessControlStorage
			.getStorage();

		require(!accessControlStorage._isDeactivatedForOwners, LibStructStorage.DEACTIVATED_FOR_OWNERS);

		accessControlStorage._isDeactivatedForOperators = true;
	}

	/**
	 * @inheritdoc IAccessControl
	 * @dev  Should revert if owners are deactivated
	 */
	function ownerActivateOperatorFunctions() external isOwner {
		LibAccessControlStorage.AccessControlStorage storage accessControlStorage = LibAccessControlStorage
			.getStorage();

		require(!accessControlStorage._isDeactivatedForOwners, LibStructStorage.DEACTIVATED_FOR_OWNERS);

		accessControlStorage._isDeactivatedForOperators = false;
	}

	/**
	 * @inheritdoc IAccessControl
	 * @return  address  Address to send fees to
	 */
	function getFeeAddress() external view returns (address) {
		return LibAccessControlStorage.getStorage()._feeAddress;
	}

	/**
	 * @inheritdoc IAccessControl
	 * @return  address  Address of the oracle
	 */
	function getOracleAddress() external view returns (address) {
		return LibAccessControlStorage.getStorage()._oracleAddress;
	}

	/**
	 * @inheritdoc IAccessControl
	 */
	function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
		return LibAccessControlStorage.getStorage()._roles[role].members[account];
	}

	/**
	 * @dev Grants `role` to `account`.
	 */
	function _grantRole(bytes32 role, address account) internal virtual {
		if (!hasRole(role, account)) {
			LibAccessControlStorage.AccessControlStorage storage s = LibAccessControlStorage.getStorage();
			s._roles[role].members[account] = true;
			emit RoleGranted(role, account, msg.sender);
		}
	}

	/**
	 * @dev Adds a new owner. Address should not already be owner
	 */
	function _addOwner(address newOwner) private {
		require(!hasRole(LibStructStorage.OWNER_ROLE, newOwner), LibStructStorage.ACCOUNT_TO_BE_OWNER_IS_ALREADY_OWNER);
		_grantRole(LibStructStorage.OWNER_ROLE, newOwner);
	}

	/**
	 * @dev Adds a new operator. Address should not already be owner or operator
	 */
	function _addOperator(address newOperator) private {
		require(
			!hasRole(LibStructStorage.OWNER_ROLE, newOperator),
			LibStructStorage.ACCOUNT_TO_BE_OPERATOR_IS_ALREADY_OWNER
		);
		require(
			!hasRole(LibStructStorage.OPERATOR_ROLE, newOperator),
			LibStructStorage.ACCOUNT_TO_BE_OPERATOR_IS_ALREADY_OPERATOR
		);

		_grantRole(LibStructStorage.OPERATOR_ROLE, newOperator);
	}

	/**
	 * @dev Sets the fee address. Address should not already be owner or operator
	 */
	function _setFeeAddress(address feeAddress) private {
		require(
			!hasRole(LibStructStorage.OWNER_ROLE, feeAddress),
			LibStructStorage.ACCOUNT_TO_BE_FEE_ADDRESS_IS_ALREADY_OWNER
		);
		require(
			!hasRole(LibStructStorage.OPERATOR_ROLE, feeAddress),
			LibStructStorage.ACCOUNT_TO_BE_FEE_ADDRESS_IS_ALREADY_OPERATOR
		);

		LibAccessControlStorage.getStorage()._feeAddress = feeAddress;

		// Emit event for feeAddress, set by owner (admin)
		emit FeeAddressSet(feeAddress, msg.sender);
	}

	/**
	 * @dev Sets the oracle address. Address should not already be owner or operator
	 */
	function _setOracleAddress(address oracleAddress) private {
		LibAccessControlStorage.getStorage()._oracleAddress = oracleAddress;

		// Emit event for oracleAddress, set by owner (admin)
		emit OracleAddressSet(oracleAddress, msg.sender);
	}

	function isKYXProvider(address caller) external view override returns (bool) {
		bytes memory kyxProviderName = bytes(LibAccessControlStorage.getStorage()._kyxProviders[caller]);
		return kyxProviderName.length > 0;
	}

	/**
	 * @dev     Checks if a given address is a user only (not owner, not operator, not fee address)
	 * @param   caller  caller address
	 * @return  bool  if sender is a user address only
	 */
	function isUser(address caller) external view returns (bool) {
		return
			!hasRole(LibStructStorage.OWNER_ROLE, caller) &&
			!hasRole(LibStructStorage.OPERATOR_ROLE, caller) &&
			LibAccessControlStorage.getStorage()._feeAddress != caller;
	}
}
