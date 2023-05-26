// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond Match Interface
 */
interface IMatchDeal is ICerchiaDRTEvents {
	/**
	 * @notice  Callable by a user, to match another user's BidLive deal
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   dealId  Id of the deal user wants to match
	 */
	function userUpdateDealFromBidToMatched(address callerAddress, uint256 dealId) external;

	/**
	 * @notice  Callable by a user, to match another user's AskLive deal
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   dealId  Id of the deal user wants to match
	 */
	function userUpdateDealFromAskToMatched(address callerAddress, uint256 dealId) external;
}
