// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { LibStructStorage } from "../libraries/LibStructStorage.sol";

/**
 * @title  CerchiaDRT Diamond Getters Interface
 */
interface IGetEntityFacet {
	/**
	 * @notice  Returns the symbols of all standards
	 * @return  string[]  Array of symbols of all the standards in the smart contract
	 */
	function getStandardSymbols() external view returns (string[] memory);

	/**
	 * @notice  Returns a standard, given a symbol
	 * @param   symbol  Symbol of the standard to return all information for
	 * @return  LibStructStorage.Standard  Whole standard matching supplied symbol
	 */
	function getStandard(string calldata symbol) external view returns (LibStructStorage.Standard memory);

	/**
	 * @notice  Returns the symbols of all tokens
	 * @return  string[]  Array of symbols of all the tokens registered in the smart contract
	 */
	function getTokenSymbols() external view returns (string[] memory);

	/**
	 * @notice  Returns a stored token's address, given a symbol
	 * @param   symbol  Symbol of the token to return address for
	 * @return  address  Address of the token matching supplied symbol
	 */
	function getTokenAddress(string calldata symbol) external view returns (address);

	/**
	 * @notice  Returns a deal, given the dealId
	 * @return  uint256[]  Array of ids of all the deals
	 */
	function getDeal(uint256 dealId) external view returns (LibStructStorage.Deal memory);

	/**
	 * @notice  Returns a list of all the deals ids
	 * @return  uint256[]  Array of ids of all the deals
	 */
	function getDealIds() external view returns (uint256[] memory);

	/**
	 * @notice  Returns all the timestamps for which index levels exist, given a parameter set configuration
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @return  uint64[]  For supplied configurationId, all the exact timestamps for which there is data present
	 */
	function getIndexLevelTimestamps(bytes32 configurationId) external view returns (uint64[] memory);

	/**
	 * @notice  Returns the number active (Matched/Live) deals for a user
	 * @param   userAddress  Address of the user to query for
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @return  uint32  How many active deals (Matched/Live) is used involved in?
	 */
	function getUserActiveDealsCount(address userAddress, bytes32 configurationId) external view returns (uint32);

	/**
	 */
	function isRestrictedToUserClaimBack() external view returns (bool);

	/**
	 * @notice  Returns True if owner functions are deactivated
	 */
	function getIsDeactivatedForOwners() external view returns (bool);

	/**
	 * @notice  Returns True if operator functions are deactivated
	 */
	function getIsDeactivatedForOperators() external view returns (bool);

	/**
	 * @notice  Returns True if contract is in dissolution
	 */
	function isInDissolution() external view returns (bool);

	/**
	 * @notice  Returns True if we have an index level for date + configurationId combination
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 * @return  bool  True if there is index level data for the exact timestamp + configurationId combination
	 */
	function isLevelSet(bytes32 configurationId, uint64 timestamp) external view returns (bool);

	/**
	 * @notice  Returns index level for date + configurationId combination
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 * @return  int128 Index level for the exact timestamp + configurationId combination
	 */
	function getLevel(bytes32 configurationId, uint64 timestamp) external view returns (int128);

	/**
	 * @return  kyxProviderAddresses  List of all approved KYX Providers
	 */
	function getKYXProvidersAddresses() external view returns (address[] memory kyxProviderAddresses);

	/**
	 * @param   kyxProviderAddress  Address to recover name for
	 * @return  kyxProviderName  The name of the KYX Provider under the provided address
	 */
	function getKYXProviderName(address kyxProviderAddress) external view returns (string memory kyxProviderName);
}
