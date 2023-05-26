// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond Owner Operations Interface
 */
interface IOwnerOperations is ICerchiaDRTEvents {
	/**
	 * @dev     Callable by owners, to add a new standard linked to a parameter configuration for the off-chain api
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   symbol Symbol Standard will be denoted by
	 * @param   startDate  The date to start tracking index levels and doing settlement for linked deals
	 * @param   maturityDate  The date to stop tracking index levels and doing settlement for linked deals
	 * @param   feeInBps Fee in basis points of deal's notional, to be sent to the fee address upon deal triggers/matures
	 * @param   strike  Number that if index level is higher or equal, deal should trigger
	 * @param   exponentOfTenMultiplierForStrike  Similar to ERC20's decimals. Off-chain API data is of float type.
	 *          On the blockchain, we sent it multiplied by 10 ** exponentOfTenMultiplierForStrike, to make it integer
	 */
	function ownerAddNewStandard(
		bytes32 configurationId,
		string calldata symbol,
		uint64 startDate,
		uint64 maturityDate,
		uint128 feeInBps,
		int128 strike,
		uint8 exponentOfTenMultiplierForStrike
	) external;

	/**
	 * @dev     Callable by owners, to add a new token that users can create deals based on
	 * @param   denomination The name that the token will have inside our smart contract
	 * @param   token  The address to find the token at
	 */
	function ownerAddNewToken(string calldata denomination, address token) external;

	/**
	 * @dev     Callable by owners, to delete some of the existing standards
	 * @param   symbols  Symbols of standards to delete
	 */
	function ownerDeleteStandards(string[] calldata symbols) external;

	/**
	 * @dev     Callable by owners, to delete some of the existing tokens
	 * @param   symbols  Symbols of tokens to delete
	 */
	function ownerDeleteTokens(string[] calldata symbols) external;

	function ownerAddNewKYXProvider(address kyxProviderAddress, string calldata name) external;

	function ownerDeleteKYXProviders(address[] calldata providerNames) external;
}
