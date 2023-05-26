// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IAccessControl } from "./interfaces/IAccessControl.sol";
import { IGetEntityFacet } from "./interfaces/IGetEntityFacet.sol";

import { LibStructStorage } from "./libraries/LibStructStorage.sol";

contract RoleBased {
	/**
	 * @dev     Prevents calling a function from anyone not being a user
	 * @param   callerAddress  The msg.sender that called KYXProvider and was forwarded after KYX
	 */
	modifier onlyUser(address callerAddress) {
		require(IAccessControl(address(this)).isUser(callerAddress), LibStructStorage.SHOULD_BE_END_USER);
		_;
	}

	/**
	 * @dev  Prevents calling a function from anyone not being the owner
	 */
	modifier onlyOwner() {
		require(
			IAccessControl(address(this)).hasRole(LibStructStorage.OWNER_ROLE, msg.sender),
			LibStructStorage.SHOULD_BE_OWNER
		);
		_;
	}

	/**
	 * @dev Prevents calling a function if users are restricted to claimback only
	 */
	modifier notRestrictedToUserClaimBack() {
		require(!IGetEntityFacet(address(this)).isRestrictedToUserClaimBack(), LibStructStorage.ONLY_CLAIMBACK_ALLOWED);

		_;
	}
}
