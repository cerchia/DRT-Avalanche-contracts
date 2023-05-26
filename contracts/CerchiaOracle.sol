// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaOracle } from "./interfaces/ICerchiaOracle.sol";
import { IAnyAccountOperationsFacet } from "./interfaces/IAnyAccountOperationsFacet.sol";
import { IAccessControlOracle } from "./interfaces/IAccessControlOracle.sol";

import { LibStructStorage } from "./libraries/LibStructStorage.sol";
import { LibCerchiaOracleStorage } from "./libraries/LibCerchiaOracleStorage.sol";
import { LibOracleStructStorage } from "./libraries/LibOracleStructStorage.sol";
import { LibCommonOperations } from "./libraries/LibCommonOperations.sol";

contract CerchiaOracle is ICerchiaOracle {
	/**
	 * @dev  Prevents calling a function from anyone not being the owner
	 */
	modifier onlyOwner() {
		require(msg.sender == IAccessControlOracle(address(this)).getOwner(), LibOracleStructStorage.SHOULD_BE_OWNER);
		_;
	}

	/**
	 * @dev Prevents calling a function from anyone but CerchiaDRT Diamond
	 */
	modifier onlyCerchiaDRT() {
		require(
			msg.sender == IAccessControlOracle(address(this)).getCerchiaDRTAddress(),
			LibOracleStructStorage.ORACLE_CALLER_CAN_ONLY_BE_CERCHIA_DRT
		);

		_;
	}

	/**
	 * @param   unixTimestamp  Unix Epoch to be end of date (YYYY/MM/DD 23:59:59)
	 */
	modifier isEndOfDate(uint64 unixTimestamp) {
		require(
			(unixTimestamp + 1) % LibCommonOperations.SECONDS_IN_A_DAY == 0,
			LibStructStorage.UNIX_TIMESTAMP_IS_NOT_END_OF_DATE
		);
		_;
	}

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
	 * @inheritdoc ICerchiaOracle
	 */
	function getLevel(
		bytes32 configurationId,
		uint64 timestamp
	) external onlyCerchiaDRT isEndOfDate(timestamp) isValidBlockTimestamp(timestamp) {
		LibCerchiaOracleStorage.CerchiaOracleStorage storage s = LibCerchiaOracleStorage.getStorage();
		uint256 id = s.requestId;

		s.requests[id] = msg.sender;
		s.requestId++;

		emit GetLevel(msg.sender, id, configurationId, timestamp);
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function ownerSetLevel(
		bytes32 configurationId,
		int128 level,
		uint256 requestId,
		uint64 timestamp,
		bool isValid
	) external onlyOwner isEndOfDate(timestamp) isValidBlockTimestamp(timestamp) {
		LibCerchiaOracleStorage.CerchiaOracleStorage storage s = LibCerchiaOracleStorage.getStorage();

		// Check that request for level hasn't somehow already been fulfilled
		require(s.requests[requestId] != address(0), LibOracleStructStorage.INVALID_REQUEST_ID);

		int128 levelToSend = level;

		// If oracle is not working, or off-chain value received was not value, transmit invalid value to CerchiaDRT
		if (!LibCerchiaOracleStorage.getStorage()._isWorking || !isValid) {
			levelToSend = LibOracleStructStorage.INVALID_LEVEL_VALUE;
		}

		// Request was fulfilled, should delete
		delete s.requests[requestId];

		// Return index level to CerchiaDRT
		IAnyAccountOperationsFacet(IAccessControlOracle(address(this)).getCerchiaDRTAddress()).indexDataCallBack(
			configurationId,
			timestamp,
			levelToSend
		);
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function ownerSetStatus(bool isWorking_) external onlyOwner {
		LibCerchiaOracleStorage.getStorage()._isWorking = isWorking_;
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function isWorking() external view returns (bool) {
		return LibCerchiaOracleStorage.getStorage()._isWorking;
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function getLastRequestIndex() external view returns (uint256 lastRequestId) {
		return LibCerchiaOracleStorage.getStorage().requestId;
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function getRequestor(uint256 requestId) external view returns (address requestor) {
		return LibCerchiaOracleStorage.getStorage().requests[requestId];
	}
}
