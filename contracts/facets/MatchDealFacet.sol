// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IMatchDeal } from "../interfaces/IMatchDeal.sol";
import { IAccessControl } from "../interfaces/IAccessControl.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { LibDealsSet } from "../libraries/LibDealsSet.sol";

import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibCerchiaDRTStorage as Storage } from "../libraries/LibCerchiaDRTStorage.sol";

import { RoleBased } from "../RoleBased.sol";

/**
 * @title  CerchiaDRT Diamond Match Interface
 */
contract MatchDealFacet is RoleBased, IMatchDeal {
	using LibDealsSet for LibDealsSet.DealsSet;
	using SafeERC20 for IERC20;

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

	/**
	 * @inheritdoc IMatchDeal
	 * @dev     Not callable if user functions are deactivated or contract has been dissoluted
	 * @dev     Transfers deal's `notional - premium` amount, in token called `denomination`, from caller to smart contract
	 * @dev     Caller should approve smart contract for `notional - premium` beforehand
	 */
	function userUpdateDealFromBidToMatched(
		address callerAddress,
		uint256 dealId
	) external isKYXWhitelisted onlyUser(callerAddress) notRestrictedToUserClaimBack {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Can't match if contract is in dissolution
		require(!s._isInDissolution, LibStructStorage.CONTRACT_IS_IN_DISSOLUTION);

		require(s._dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		LibStructStorage.Deal storage deal = s._dealsSet.getById(dealId);

		// Deal should be bid, matcher should not be initiator, deal should have buyer
		require(deal.state == LibStructStorage.DealState.BidLive, LibStructStorage.DEAL_STATE_IS_NOT_BID_LIVE);
		require(callerAddress != deal.initiator, LibStructStorage.CAN_NOT_MATCH_YOUR_OWN_DEAL);
		require(deal.buyer != address(0), LibStructStorage.DEAL_BUYER_SHOULD_NOT_BE_EMPTY);

		// Check that user owns necessary funds, and has approved allowance beforehand
		IERC20 token = IERC20(deal.voucher.token);
		uint128 amountToTransfer = deal.voucher.notional - deal.voucher.premium;
		require(token.balanceOf(callerAddress) >= amountToTransfer, LibStructStorage.INSUFFICIENT_BALANCE);
		require(
			token.allowance(callerAddress, address(this)) >= amountToTransfer,
			LibStructStorage.INSUFFICIENT_SPEND_TOKEN_ALLOWENCE
		);

		// Deal is now matched, has a seller, funds inside are = notional, both seller and buyer have a new active deal
		deal.state = LibStructStorage.DealState.Matched;
		deal.seller = callerAddress;
		deal.funds = deal.voucher.notional;
		s._userActiveDealsCount[deal.seller][deal.voucher.configurationId]++;
		s._userActiveDealsCount[deal.buyer][deal.voucher.configurationId]++;

		emit Match(dealId, callerAddress, amountToTransfer);

		// Transfer token from user to contract
		SafeERC20.safeTransferFrom(token, callerAddress, address(this), amountToTransfer);
	}

	/**
	 * @inheritdoc IMatchDeal
	 * @dev     Not callable if user functions are deactivated or contract has been dissoluted
	 * @dev     Transfers deal's `premium` amount, in token called `denomination`, from caller to smart contract
	 * @dev     Caller should approve smart contract for `premium` beforehand
	 */
	function userUpdateDealFromAskToMatched(
		address callerAddress,
		uint256 dealId
	) external isKYXWhitelisted onlyUser(callerAddress) notRestrictedToUserClaimBack {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Can't match if contract is in dissolution
		require(!s._isInDissolution, LibStructStorage.CONTRACT_IS_IN_DISSOLUTION);

		require(s._dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		LibStructStorage.Deal storage deal = s._dealsSet.getById(dealId);

		// Deal should be ask, matcher should not be initiator, deal should have seller
		require(deal.state == LibStructStorage.DealState.AskLive, LibStructStorage.DEAL_STATE_IS_NOT_ASK_LIVE);
		require(callerAddress != deal.initiator, LibStructStorage.CAN_NOT_MATCH_YOUR_OWN_DEAL);
		require(deal.seller != address(0), LibStructStorage.DEAL_SELLER_SHOULD_NOT_BE_EMPTY);

		// Check that user owns necessary funds, and has approved allowance beforehand
		IERC20 token = IERC20(deal.voucher.token);
		uint128 amountToTransfer = deal.voucher.premium;
		require(token.balanceOf(callerAddress) >= amountToTransfer, LibStructStorage.INSUFFICIENT_BALANCE);
		require(
			token.allowance(callerAddress, address(this)) >= amountToTransfer,
			LibStructStorage.INSUFFICIENT_SPEND_TOKEN_ALLOWENCE
		);

		// Deal is now matched, has a buyer, funds inside are = notional, both seller and buyer have a new active deal
		deal.state = LibStructStorage.DealState.Matched;
		deal.buyer = callerAddress;
		deal.funds = deal.voucher.notional;
		s._userActiveDealsCount[deal.seller][deal.voucher.configurationId]++;
		s._userActiveDealsCount[deal.buyer][deal.voucher.configurationId]++;

		emit Match(dealId, callerAddress, amountToTransfer);

		// Transfer token from user to contract
		SafeERC20.safeTransferFrom(token, callerAddress, address(this), amountToTransfer);
	}
}
