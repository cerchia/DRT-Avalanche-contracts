// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IAccessControlOracle } from "../interfaces/IAccessControlOracle.sol";

import { LibOracleStructStorage } from "../libraries/LibOracleStructStorage.sol";
import { LibAccessControlStorageOracle } from "../libraries/LibAccessControlStorageOracle.sol";

// Since we are using DiamondPattern, one can no longer directly inherit contracts from Openzeppelin.
// This happens since DiamondPattern implies a different storage structure, but OpenZeppelin handles memory internally.
// Following contract is inspired from OpenZeppelin's Ownable2Step.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol

/**
 * @title  Oracle Diamond Access Control Implementation
 * @dev    Inspired by OpenZeppelin's AccessControl Roles implementation, but adapted to Diamond Pattern storage
 * @dev    Also implements activation/deactivations of functionalities by owners
 */
contract AccessControlFacetOracle is IAccessControlOracle {
	/**
	 * @dev  Prevents initializating more than once
	 */
	modifier notInitialized() {
		LibAccessControlStorageOracle.AccessControlStorageOracle storage s = LibAccessControlStorageOracle.getStorage();

		require(!s._initialized, LibOracleStructStorage.LIB_ORACLE_STORAGE_ALREADY_INITIALIZED);
		s._initialized = true;
		_;
	}

	/**
	 * @dev  Prevents calling a function from anyone not being the owner
	 */
	modifier onlyOwner() {
		require(
			msg.sender == LibAccessControlStorageOracle.getStorage()._owner,
			LibOracleStructStorage.SHOULD_BE_OWNER
		);
		_;
	}

	/**
	 * @dev  Prevents calling a function from anyone not being the proposed new owner
	 */
	modifier onlyProposedNewOwner() {
		require(
			msg.sender == LibAccessControlStorageOracle.getStorage()._proposedNewOwner,
			LibOracleStructStorage.SHOULD_BE_PROPOSED_NEW_OWNER
		);
		_;
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @dev    Similar to OpenZeppelin's Transparent Proxy initialize function
	 * @dev    Intended to be called after deployment, on the Diamond, to alter Diamond's storage
	 * @dev    Currently called from off-chain, after all contracts' creation, through a script
	 * @dev    Addresses should be unique, no address can have multiple roles or responsabilities
	 */
	function initAccessControlFacet(address owner, address cerchiaDRT) external notInitialized {
		require(owner != cerchiaDRT, LibOracleStructStorage.OWNER_CAN_NOT_BE_CERCHIA_DRT);

		LibAccessControlStorageOracle.AccessControlStorageOracle storage s = LibAccessControlStorageOracle.getStorage();
		s._owner = owner;
		s._cerchiaDRTAddress = cerchiaDRT;
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @dev  Owner can propose a new owner.
	 * @param newOwner this address becomes new owner after accepting the ownership transfer
	 */
	function requestOwnershipTransfer(address newOwner) external onlyOwner {
		LibAccessControlStorageOracle.getStorage()._proposedNewOwner = newOwner;

		emit RequestOwnershipTransfer(msg.sender, newOwner);
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @dev  The proposed new owner accepts the ownership transfer,
	 *          thus becoming the owner and setting proposed new owner to address(0)
	 */
	function confirmOwnershipTransfer() external onlyProposedNewOwner {
		delete LibAccessControlStorageOracle.getStorage()._proposedNewOwner;

		_transferOwnership(msg.sender);
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @dev   The owner can cancel the proposed ownership transfer, setting proposed new owner to address(0)
	 */
	function cancelOwnershipTransfer() external onlyOwner {
		address proposedNewOwner = LibAccessControlStorageOracle.getStorage()._proposedNewOwner;
		delete LibAccessControlStorageOracle.getStorage()._proposedNewOwner;

		emit CancelOwnershipTransfer(msg.sender, proposedNewOwner);
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @return  address  The owner of the Oracle Diamond
	 */
	function getOwner() external view returns (address) {
		return LibAccessControlStorageOracle.getStorage()._owner;
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @return  address  The proposed new owner of the Oracle Diamond
	 */
	function getProposedNewOwner() external view returns (address) {
		return LibAccessControlStorageOracle.getStorage()._proposedNewOwner;
	}

	/**
	 * @inheritdoc IAccessControlOracle
	 * @return  address  The address of the CerchiaDRT Diamond
	 */
	function getCerchiaDRTAddress() external view returns (address) {
		return LibAccessControlStorageOracle.getStorage()._cerchiaDRTAddress;
	}

	/**
	 * @dev Helper function to transfer ownership
	 */
	function _transferOwnership(address newOwner) internal {
		LibAccessControlStorageOracle.AccessControlStorageOracle storage s = LibAccessControlStorageOracle.getStorage();

		address oldOwner = s._owner;
		s._owner = newOwner;
		emit OwnershipTransfered(oldOwner, newOwner);
	}
}
