// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title   Diamond Storage for Oracle Diamond's access control functions
 */
library LibAccessControlStorageOracle {
	bytes32 public constant ACCESS_CONTROL_STORAGE_SLOT_ORACLE = keccak256("ACCESS.CONTROL.STORAGE.ORACLE");

	/**
	 * @dev https://dev.to/mudgen/how-diamond-storage-works-90e
	 */
	struct AccessControlStorageOracle {
		// Owner of Oracle Diamond, address allowed to call OwnerSetLevel
		address _owner;
		// Proposed new owner of Oracle Diamond, for Ownable2Step flow
		address _proposedNewOwner;
		// Address of CerchiaDRT Diamond, used to enforce Oracle flow only being initiated by CerchiaDRT
		address _cerchiaDRTAddress;
		// True if AccessControlStorageOracle was initialized
		bool _initialized;
	}

	/**
	 * @dev     https://dev.to/mudgen/how-diamond-storage-works-90e
	 * @return  s  Returns a pointer to an "arbitrary" location in memory, holding our AccessControlStorageOracle struct
	 */
	function getStorage() internal pure returns (AccessControlStorageOracle storage s) {
		bytes32 position = ACCESS_CONTROL_STORAGE_SLOT_ORACLE;
		assembly {
			s.slot := position
		}
	}
}
