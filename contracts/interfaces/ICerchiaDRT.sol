// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond Create/Cancel Deal Interface
 */
interface ICerchiaDRT is ICerchiaDRTEvents {
	/**
	 * @notice  Callable by a user, to create a new BidLive deal
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   symbol  Symbol of the standard this deal is based on
	 * @param   denomination  Symbol of the token this deal is based on
	 * @param   notional  Notional of the deal (how much buyer wins if deal triggers, minus fee)
	 * @param   premium  Premium of the deal (how much seller wins if deal matures, minus fee))
	 * @param   expiryDate  Date after which this deal, if not Matched, will expire
	 */
	function userCreateNewDealAsBid(
		address callerAddress,
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	/**
	 * @notice  Callable by a user, to create a new AskLive deal
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   symbol  Symbol of the standard this deal is based on
	 * @param   denomination  Symbol of the token this deal is based on
	 * @param   notional  Notional of the deal (how much buyer wins if deal triggers, minus fee)
	 * @param   premium  Premium of the deal (how much seller wins if deal matures, minus fee))
	 * @param   expiryDate  Date after which this deal, if not Matched, will expire
	 */
	function userCreateNewDealAsAsk(
		address callerAddress,
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	/**
	 * @notice  Callable by a user, to cancel a BidLive/AskLive deal, if user was the initiator
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   dealId  Deal user wants to cancel
	 */
	function userUpdateDealToCancel(address callerAddress, uint256 dealId) external;
}
