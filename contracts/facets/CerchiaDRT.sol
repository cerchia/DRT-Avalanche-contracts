// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICerchiaDRT } from "../interfaces/ICerchiaDRT.sol";
import { IAccessControl } from "../interfaces/IAccessControl.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { LibCommonOperations } from "../libraries/LibCommonOperations.sol";
import { LibDealsSet } from "../libraries/LibDealsSet.sol";

import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibCerchiaDRTStorage as Storage } from "../libraries/LibCerchiaDRTStorage.sol";

import { RoleBased } from "../RoleBased.sol";

/**
 * @title  CerchiaDRT Diamond Create/Cancel Deal Implementation
 */
contract CerchiaDRT is RoleBased, ICerchiaDRT {
	using LibDealsSet for LibDealsSet.DealsSet;
	using SafeERC20 for IERC20;

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
	 * @dev     Prevents calling a function from anyone that hasn't passed KYX verification
	 * If call reaches here from KYX Provider, it means caller has been verified and forwarded here.
	 * If call reaches here not from KYX Provider, it means it comes from someone that hasn't gone through verification.
	 */
	modifier isKYXWhitelisted() {
		// If caller has not passed KYC/KYB, should not be able to proceed
		require(IAccessControl(address(this)).isKYXProvider(msg.sender), LibStructStorage.NEED_TO_PASS_KYX);
		_;
	}

	function userCreateNewDealAsBid(
		address callerAddress,
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external isKYXWhitelisted onlyUser(callerAddress) notRestrictedToUserClaimBack isEndOfDate(expiryDate) {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Can't create bid if contract is in dissolution
		require(!s._isInDissolution, LibStructStorage.CONTRACT_IS_IN_DISSOLUTION);

		// Check calldata is valid and create voucher
		LibStructStorage.Voucher memory voucher = _validateNewDealInputData(
			callerAddress,
			true,
			symbol,
			denomination,
			notional,
			premium,
			expiryDate,
			s
		);

		// Create deal and get its id
		uint256 id = s._dealsSet.insert(
			LibStructStorage.Deal(
				callerAddress,
				callerAddress,
				address(0),
				premium,
				expiryDate,
				voucher,
				LibStructStorage.DealState.BidLive,
				false,
				false,
				0,
				0
			)
		);

		// Emit event
		_emitNewBidEvent(callerAddress, id, symbol, denomination, expiryDate, notional, premium);

		// Transfer token from user to contract
		SafeERC20.safeTransferFrom(IERC20(s._tokens[denomination]), callerAddress, address(this), premium);
	}

	/**
	 * @inheritdoc ICerchiaDRT
	 * @dev     Not callable if user functions are deactivated or contract has been dissoluted
	 * @dev     Transfers `notional - premium` amount, in token called `denomination`, from caller to smart contract
	 * @dev     Caller should approve smart contract for `notional - premium` beforehand
	 */
	function userCreateNewDealAsAsk(
		address callerAddress,
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external isKYXWhitelisted onlyUser(callerAddress) notRestrictedToUserClaimBack isEndOfDate(expiryDate) {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Can't create ask if contract is in dissolution
		require(!s._isInDissolution, LibStructStorage.CONTRACT_IS_IN_DISSOLUTION);

		// Check calldata is valid and create voucher
		LibStructStorage.Voucher memory voucher = _validateNewDealInputData(
			callerAddress,
			false,
			symbol,
			denomination,
			notional,
			premium,
			expiryDate,
			s
		);

		// Create deal and get its id
		uint256 id = s._dealsSet.insert(
			LibStructStorage.Deal(
				callerAddress,
				address(0),
				callerAddress,
				notional - premium,
				expiryDate,
				voucher,
				LibStructStorage.DealState.AskLive,
				false,
				false,
				0,
				0
			)
		);

		// Emit event
		_emitNewAskEvent(callerAddress, id, symbol, denomination, expiryDate, notional, premium);

		// Transfer token from user to contract
		SafeERC20.safeTransferFrom(IERC20(s._tokens[denomination]), callerAddress, address(this), notional - premium);
	}

	/**
	 * @inheritdoc ICerchiaDRT
	 * @dev     Not callable if user functions are deactivated or contract has been dissoluted
	 * @dev     Deletes deal and transfers `premium` or `notional - premium`, depending on deal state, back to initiator
	 * @dev     Caller should approve smart contract for premium beforehand
	 */
	function userUpdateDealToCancel(
		address callerAddress,
		uint256 dealId
	) external isKYXWhitelisted onlyUser(callerAddress) notRestrictedToUserClaimBack {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Can't cancel deal if contract is in dissolution, can only claim it back
		require(!s._isInDissolution, LibStructStorage.CONTRACT_IS_IN_DISSOLUTION);

		require(s._dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		LibStructStorage.Deal storage deal = s._dealsSet.getById(dealId);

		require(_canCancelDeal(deal), LibStructStorage.DEAL_CAN_NOT_BE_CANCELLED);

		// Check user is not cancelling someone else's deal
		address initiator = deal.initiator;
		require(initiator == callerAddress, LibStructStorage.USER_TO_CANCEL_DEAL_IS_NOT_INITIATOR);

		// Duplication, since these are needed after deal deletion
		IERC20 token = IERC20(deal.voucher.token);
		uint128 fundsToReturn = deal.funds;

		// No need to check if deal exists, reaching this point means it exists
		s._dealsSet.deleteById(dealId);

		// Emit event
		emit UserUpdateDealToCancel(dealId, initiator, fundsToReturn);

		// Transfer token back to initiator
		SafeERC20.safeTransfer(token, initiator, fundsToReturn);
	}

	/**
	 * @dev     A user can only cancel their own deals, if there is not yet a counterparty involved
	 * @dev     BidLive/AskLive are states for deals with only a buyer or seller, while Matched and Live imply both parties
	 * @param   deal  Deal intended for cancellation
	 * @return  bool  True if deal can be cancelled (is in BidLive or AskLive state)
	 */
	function _canCancelDeal(LibStructStorage.Deal storage deal) private view returns (bool) {
		return deal.state == LibStructStorage.DealState.BidLive || deal.state == LibStructStorage.DealState.AskLive;
	}

	/**
	 * @dev     Helper function to validate input data for creation of BidLive/AskLive deals
	 * @param   isBid  True if deal to be created should be Bid, false if it should be Live
	 * @param   symbol  Symbol of the standard this deal is based on
	 * @param   denomination  Symbol of the token this deal is based on
	 * @param   notional  Notional of the deal (how much buyer wins if deal triggers, minus fee)
	 * @param   premium  Premium of the deal (how much seller wins if deal matures, minus fee))
	 * @param   expiryDate  Date after which this deal, if not Matched, will expire
	 * @param   s  Diamond Pattern storage slot
	 * @return  voucher  Structure used by us to encapsulate part of a deal's data
	 */
	function _validateNewDealInputData(
		address callerAddress,
		bool isBid,
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate,
		Storage.CerchiaDRTStorage storage s
	) private view returns (LibStructStorage.Voucher memory voucher) {
		// Check symbol was supplied and we have a standard with that symbol
		require(LibCommonOperations._isNotEmpty(symbol), LibStructStorage.EMPTY_SYMBOL);
		LibStructStorage.Standard storage standard = s._standards[symbol];
		require(standard.startDate > 0, LibStructStorage.STANDARD_DOES_NOT_EXIST);

		// Check denomination was supplied and we have a token with that denomination
		require(LibCommonOperations._isNotEmpty(denomination), LibStructStorage.EMPTY_DENOMINATION);

		require(s._tokens[denomination] != address(0), LibStructStorage.TOKEN_DOES_NOT_EXIST);

		// Notional needs to be a multiple of 10000, and P < N
		require(notional > 0, LibStructStorage.NOTIONAL_SHOULD_BE_GREATER_THAN_ZERO);
		require(premium > 0, LibStructStorage.PREMIUM_SHOULD_BE_GREATER_THAN_ZERO);
		require(
			notional % LibStructStorage.TEN_THOUSAND == LibStructStorage.ZERO,
			LibStructStorage.NOTIONAL_SHOULD_BE_MULTIPLE_OF_10000
		);
		require(premium < notional, LibStructStorage.PREMIUM_SHOULD_BE_LESS_THAN_NOTIONAL);

		// Can not create deal that expires in the past
		// solhint-disable-next-line not-rely-on-time
		require(expiryDate > block.timestamp, LibStructStorage.EXPIRY_DATE_CANT_BE_IN_THE_PAST);

		// expiry date should be <= standard.maturityDate
		require(
			expiryDate <= standard.maturityDate,
			LibStructStorage.EXPIRY_DATE_SHOULD_BE_LESS_THAN_OR_EQUAL_TO_MATURITY_DATE
		);

		// Check that user owns necessary funds, and has approved allowance beforehand
		uint128 amountToTransfer = isBid ? premium : notional - premium;
		require(
			IERC20(s._tokens[denomination]).balanceOf(callerAddress) >= amountToTransfer,
			LibStructStorage.INSUFFICIENT_BALANCE
		);
		require(
			IERC20(s._tokens[denomination]).allowance(callerAddress, address(this)) >= amountToTransfer,
			LibStructStorage.INSUFFICIENT_SPEND_TOKEN_ALLOWENCE
		);

		// Create and return voucher
		return
			LibStructStorage.Voucher(
				notional,
				premium,
				standard.configurationId,
				standard.feeInBps,
				standard.strike,
				standard.startDate,
				standard.maturityDate,
				s._tokens[denomination]
			);
	}

	function _emitNewBidEvent(
		address callerAddress,
		uint256 dealId,
		string calldata standardSymbol,
		string calldata tokenDenomination,
		uint64 expiryDate,
		uint128 notional,
		uint128 premium
	) private {
		// Emit event
		emit NewBid(dealId, callerAddress, standardSymbol, tokenDenomination, expiryDate, notional, premium);
	}

	function _emitNewAskEvent(
		address callerAddress,
		uint256 dealId,
		string calldata standardSymbol,
		string calldata tokenDenomination,
		uint64 expiryDate,
		uint128 notional,
		uint128 premium
	) private {
		// Emit event
		emit NewAsk(dealId, callerAddress, standardSymbol, tokenDenomination, expiryDate, notional, premium);
	}
}
