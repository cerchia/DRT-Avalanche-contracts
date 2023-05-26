// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title   Wrapper library storing constants and structs of Oracle Diamond
 */
library LibOracleStructStorage {
	// Error codes with descriptive names
	string public constant SHOULD_BE_OWNER = "16";
	string public constant LIB_ORACLE_STORAGE_ALREADY_INITIALIZED = "501";
	string public constant INVALID_REQUEST_ID = "502";
	string public constant LEVEL_DATA_IS_NOT_VALID = "503";
	string public constant ORACLE_IS_NOT_WORKING = "504";
	string public constant ACCOUNT_TO_BE_OWNER_IS_ALREADY_OWNER = "505";
	string public constant ORACLE_CALLER_CAN_ONLY_BE_CERCHIA_DRT = "506";
	string public constant SHOULD_BE_PROPOSED_NEW_OWNER = "507";
	string public constant OWNER_CAN_NOT_BE_CERCHIA_DRT = "508";

	// Value representing invalid index level from off-chain API
	int128 public constant INVALID_LEVEL_VALUE = type(int128).min;
}
