// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title  Oracle Diamond's functions, except access control
 */
interface ICerchiaOracle {
	// Emitted by Oracle Diamond, to be picked up by off-chain
	event GetLevel(address sender, uint256 request_id, bytes32 configurationId, uint64 timestamp);

	/**
	 * @dev     Emits GetLevel event, to be picked-up by off-chain listeners and initiate off-chain oracle flow
	 * @dev     Only callable by CerchiaDRT Diamond
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 */
	function getLevel(bytes32 configurationId, uint64 timestamp) external;

	/**
	 * @dev     Only callable by Oracle Diamond's owner, to set level for a configurationId + date combination
	 * @dev     Calls back into CerchiaDRT Diamond, to supply requested index level
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   level  Index level gotten from off-chain API
	 * @param   requestId  Request Id to fulfill
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 * @param   isValid  True if data from off-chain API was valid
	 */
	function ownerSetLevel(
		bytes32 configurationId,
		int128 level,
		uint256 requestId,
		uint64 timestamp,
		bool isValid
	) external;

	/**
	 * @dev     Only callable by Oracle Diamond's owner, to set status for the Oracle
	 * @param   isWorking_  True if off-chain API is working,
	 *                      False otherwise, as Oracle Diamond won't be able to supply data
	 */
	function ownerSetStatus(bool isWorking_) external;

	/**
	 * @return  bool  True if Oracle is working
	 */
	function isWorking() external view returns (bool);

	/**
	 * @return  lastRequestId  The id of the last request
	 */
	function getLastRequestIndex() external view returns (uint256 lastRequestId);

	/**
	 * @param   requestId  Id of a request, to get the address who requested index level
	 * @return  requestor  Address that requested index level, for a given requestId
	 */
	function getRequestor(uint256 requestId) external view returns (address requestor);
}
