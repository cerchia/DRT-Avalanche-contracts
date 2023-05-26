// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IClaimBackFacet } from "../interfaces/IClaimBackFacet.sol";
import { IAccessControl } from "../interfaces/IAccessControl.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibDealsSet } from "../libraries/LibDealsSet.sol";
import { LibCerchiaDRTStorage as Storage } from "../libraries/LibCerchiaDRTStorage.sol";
import { LibAccessControlStorage as ACStorage } from "../libraries/LibAccessControlStorage.sol";

/**
 * @title  CerchiaDRT Diamond Claimback Implementation
 */
contract ClaimBackFacet is IClaimBackFacet {
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
	 * @inheritdoc IClaimBackFacet
	 * @dev     Only function allowed once AutomaticDissolution happens, so that we don't lock user funds inside
	 * @dev     Deletes deal if all parties involved have claimed back, emits event, and transfers to user the
	 *          correct amount of funds (depending on user being buyer or seller)
	 */
	function claimBack(address callerAddress, uint256 dealId) external isKYXWhitelisted {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		require(s._dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		LibStructStorage.Deal storage deal = s._dealsSet.getById(dealId);

		// Can only claim back if contract is in dissolution
		require(s._isInDissolution, LibStructStorage.CANNOT_CLAIM_BACK_UNLESS_IN_DISSOLUTION);

		// Only buyer or seller can claim
		require(
			callerAddress == deal.buyer || callerAddress == deal.seller,
			LibStructStorage.CALLER_IS_NOT_VALID_DEAL_CLAIMER
		);

		uint128 fundsToClaimBack;

		// Buyer (if any) claims back premium
		// Seller (if any) claims back notional - premium
		if (callerAddress == deal.buyer && !deal.buyerHasClaimedBack) {
			fundsToClaimBack = deal.voucher.premium;
			deal.buyerHasClaimedBack = true;
		} else if (callerAddress == deal.seller && !deal.sellerHasClaimedBack) {
			fundsToClaimBack = deal.voucher.notional - deal.voucher.premium;
			deal.sellerHasClaimedBack = true;
		}

		// fundsToClaimback being 0 means caller has already claimed back funds,
		// since we didn't enter any of the above if statements
		require(fundsToClaimBack > 0, LibStructStorage.FUNDS_ALREADY_CLAIMED);

		// One less deal in which msg.sender is involved, if deal was Active (Matched/Live)
		if (deal.state == LibStructStorage.DealState.Matched || deal.state == LibStructStorage.DealState.Live) {
			s._userActiveDealsCount[callerAddress][deal.voucher.configurationId]--;
		}

		// We might delete deal but need token later
		IERC20 token = IERC20(deal.voucher.token);

		// Decrease funds remaining inside deal
		deal.funds = deal.funds - fundsToClaimBack;

		// If there are no more funds, it means everyone claimed back and we should delete deal
		if (deal.funds == 0) {
			// No need to check if deal exists, reaching this point means it exists
			s._dealsSet.deleteById(dealId);
		}

		emit Claimed(dealId, callerAddress, fundsToClaimBack);

		SafeERC20.safeTransfer(token, callerAddress, fundsToClaimBack);
	}
}
