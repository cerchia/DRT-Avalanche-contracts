// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAnyAccountOperationsFacet } from "../interfaces/IAnyAccountOperationsFacet.sol";
import { IAccessControl } from "../interfaces/IAccessControl.sol";
import { ICerchiaOracle } from "../interfaces/ICerchiaOracle.sol";
import { IGetEntityFacet } from "../interfaces/IGetEntityFacet.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { LibCommonOperations } from "../libraries/LibCommonOperations.sol";
import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibDealsSet } from "../libraries/LibDealsSet.sol";

import { LibCerchiaDRTStorage as Storage } from "../libraries/LibCerchiaDRTStorage.sol";
import { LibAccessControlStorage as ACStorage } from "../libraries/LibAccessControlStorage.sol";

/**
 * @title  CerchiaDRT Diamond's AnyAccount Implementation
 */
contract AnyAccountOperationsFacet is IAnyAccountOperationsFacet {
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
	 * @dev  Prevents calling a function from anyone not being the Oracle Diamond address
	 */
	modifier onlyOracleAddress() {
		require(
			IAccessControl(address(this)).getOracleAddress() == msg.sender,
			LibStructStorage.CALLER_IS_NOT_ORACLE_ADDRESS
		);

		_;
	}

	/**
	 * @dev Prevents calling a function from anyone not being an operator
	 */
	modifier onlyOperator() {
		require(
			IAccessControl(address(this)).hasRole(LibStructStorage.OPERATOR_ROLE, msg.sender),
			LibStructStorage.ONLY_OPERATOR_ALLOWED
		);
		_;
	}

	/**
	 * @dev Prevents calling a function if operators are deactivated
	 */
	modifier isNotDeactivatedForOperator() {
		require(
			!IGetEntityFacet(address(this)).getIsDeactivatedForOperators(),
			LibStructStorage.DEACTIVATED_FOR_OPERATORS
		);
		_;
	}

	/**
	 * @dev     Prevents calling a function from anyone not being a user
	 * @param   callerAddress  The msg.sender that called KYXProvider and was forwarded after KYX
	 */
	modifier onlyUser(address callerAddress) {
		require(IAccessControl(address(this)).isUser(callerAddress), LibStructStorage.SHOULD_BE_END_USER);
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

	/**
	 * @inheritdoc IAnyAccountOperationsFacet
	 * @dev  To be called on-demand by users
	 */
	function initiateIndexDataUpdate(
		address callerAddress,
		bytes32 configurationId,
		uint64 timestamp
	) external isKYXWhitelisted onlyUser(callerAddress) isEndOfDate(timestamp) isValidBlockTimestamp(timestamp) {
		// Only users can initiate index data update here. They shouldn't be deactivated
		require(!IGetEntityFacet(address(this)).isRestrictedToUserClaimBack(), LibStructStorage.ONLY_CLAIMBACK_ALLOWED);

		// Users should have Matched/Live deals, for the configurationId at hand,
		// otherwise them initiating update doesn't make sense
		require(
			Storage.getStorage()._userActiveDealsCount[callerAddress][configurationId] > 0,
			LibStructStorage.USER_HAS_NO_ACTIVE_DEALS_FOR_CONFIGURATION_ID
		);

		_initiateIndexDataUpdate(callerAddress, configurationId, timestamp);
	}

	/**
	 * @inheritdoc IAnyAccountOperationsFacet
	 * @dev  For each configurationId, to be called daily by operators
	 */
	function operatorInitiateIndexDataUpdate(
		bytes32 configurationId,
		uint64 timestamp
	) external onlyOperator isNotDeactivatedForOperator isEndOfDate(timestamp) isValidBlockTimestamp(timestamp) {
		_initiateIndexDataUpdate(msg.sender, configurationId, timestamp);
	}

	/**
	 * @inheritdoc IAnyAccountOperationsFacet
	 * @dev     The second part of the Oracle flow. After the Oracle emits event to be picked up off-chain,
	 *          off-chain components call the Oracle with the required data, which calls back into CerchiaDRT Diamond
	 *          to provide the required data and store it for future computation
	 */
	function indexDataCallBack(
		bytes32 configurationId,
		uint64 timestamp,
		int128 level
	) external onlyOracleAddress isEndOfDate(timestamp) isValidBlockTimestamp(timestamp) {
		// Revert if level was invalid
		if (level == LibStructStorage.INVALID_LEVEL_VALUE) {
			revert(LibStructStorage.ORACLE_DID_NOT_FULLFIL);
		} else {
			// Otherwise, store level and emit succes event
			Storage.CerchiaDRTStorage storage s = Storage.getStorage();

			s._indexLevels[configurationId][timestamp] = LibStructStorage.IndexLevel(level, true);
			s._indexLevelTimestamps[configurationId].push(timestamp);

			emit IndexDataCallBackSuccess(configurationId, timestamp, level);
		}
	}

	/**
	 * @inheritdoc IAnyAccountOperationsFacet
	 */
	function processContingentSettlement(
		address callerAddress,
		uint64 timestamp,
		uint256 dealId
	) external isKYXWhitelisted onlyUser(callerAddress) isEndOfDate(timestamp) isValidBlockTimestamp(timestamp) {
		// Only users  can initiate processContingentSettlement. They shouldn't be deactivated
		require(!IGetEntityFacet(address(this)).isRestrictedToUserClaimBack(), LibStructStorage.ONLY_CLAIMBACK_ALLOWED);

		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		require(s._dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		LibStructStorage.Deal storage deal = s._dealsSet.getById(dealId);

		// As a user, should only be able to settle your own deal
		require(
			callerAddress == deal.buyer || callerAddress == deal.seller,
			LibStructStorage.CANNOT_SETTLE_SOMEONE_ELSES_DEAL
		);

		_processContingentSettlement(callerAddress, timestamp, deal);
	}

	/**
	 * @inheritdoc IAnyAccountOperationsFacet
	 * @dev     For each deal, to be called daily by operators, and on-demand by users if they want to
	 */
	function operatorProcessContingentSettlement(
		uint64 timestamp,
		uint256 dealId
	) external onlyOperator isNotDeactivatedForOperator isEndOfDate(timestamp) isValidBlockTimestamp(timestamp) {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		require(s._dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		_processContingentSettlement(msg.sender, timestamp, s._dealsSet.getById(dealId));
	}

	/**
	 * @dev     Helper function for the Oracle flow. Emits event if data already exists for timestamp + configurationId,
	 *          otherwise asks Oracle for data if Oracle is working. If not working, dissolutes current smart contract
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 */
	function _initiateIndexDataUpdate(address callerAddress, bytes32 configurationId, uint64 timestamp) private {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Emit event if level already exists
		if (s._indexLevels[configurationId][timestamp].exists) {
			emit AnyAccountInitiateIndexDataUpdateAlreadyAvailable(
				configurationId,
				timestamp,
				s._indexLevels[configurationId][timestamp].value
			);
		} else {
			address oracleAddress = IAccessControl(address(this)).getOracleAddress();
			// If oracle is working, try to get level. Otherwise, dissolute contract
			if (ICerchiaOracle(oracleAddress).isWorking()) {
				ICerchiaOracle(oracleAddress).getLevel(configurationId, timestamp);
			} else {
				_automaticDissolution(callerAddress, configurationId, timestamp);
			}
		}
	}

	/**
	 * @dev     Helper function to delete all standards, in case of AutomaticDissolution
	 */
	function _deleteAllStandards() private {
		Storage.CerchiaDRTStorage storage cerchiaDRTStorage = Storage.getStorage();

		// Cache array length to save gas
		uint256 standardsLength = cerchiaDRTStorage._standardsKeys.length;

		for (uint i; i < standardsLength; ) {
			delete cerchiaDRTStorage._standards[cerchiaDRTStorage._standardsKeys[i]];

			unchecked {
				++i;
			}
		}
		delete cerchiaDRTStorage._standardsKeys;
	}

	/**
	 * @dev     Helper function to deactivate all functions except user claimback, in case of AutomaticDissolution
	 */
	function _disableEverythingExceptClaimback() private {
		ACStorage.AccessControlStorage storage accessControlStorage = ACStorage.getStorage();

		accessControlStorage._isDeactivatedForOwners = true;
		accessControlStorage._isDeactivatedForOperators = true;
		accessControlStorage._usersCanOnlyClaimBack = true;
	}

	/**
	 * @dev     AutomaticDissolution should make all existing deals available to be claimed back by participant parties,
	 *          delete all standards, disable all functions except user claimback, and emit event
	 * @param   sender  Initiator of the Settlement or Index Data Update processes, which triggered AutomaticDissolution
	 * @param   configurationId  Id of the parameter set for off-chain API, to have index level for
	 * @param   timestamp  Exact timestamp for off-chain API, to have index level for
	 */
	function _automaticDissolution(address sender, bytes32 configurationId, uint64 timestamp) private {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Flag that makes all deals available to be claimed back by participant parties
		s._isInDissolution = true;

		// Delete all standards
		_deleteAllStandards();

		// Disable all functions except user claimback
		_disableEverythingExceptClaimback();

		// Emit event
		emit AutomaticDissolution(sender, configurationId, timestamp);
	}

	/**
	 * @dev     Helper function to try and settle a deal, for an exact timestamp
	 * @dev     BidLive and AskLive deals are like open offers, and can only expire if date is past expiryDate
	 * @dev     Matched deals can become Live, if date is between the standard's startDate and maturityDate
	 * @dev     If a Matched deal has become Live, it could also settle if date is bigger than standard's startDate
	 * @dev     Live deals can settle, if date is after standard's startDate but before standard's maturityDate
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   date  Timestamp to settle deal for
	 * @param   deal  Deal to try and settle
	 */
	function _processContingentSettlement(
		address callerAddress,
		uint64 date,
		LibStructStorage.Deal storage deal
	) private {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		if (deal.state == LibStructStorage.DealState.BidLive || deal.state == LibStructStorage.DealState.AskLive) {
			// If deal is BidLive or AskLive, and we are past expiration date, expire deal and send back funds to initiator
			// Otherwise, there is nothing to be done
			if (date >= deal.expiryDate) {
				uint256 dealId = deal.id;
				address initiator = deal.initiator;
				LibStructStorage.DealState dealState = deal.state;
				IERC20 token = IERC20(deal.voucher.token);
				uint128 fundsToReturn = deal.funds;

				// No need to check if deal exists, reaching this point means it exists
				// Delete expired deal
				s._dealsSet.deleteById(dealId);

				// Emit the correct event
				if (dealState == LibStructStorage.DealState.BidLive) {
					emit BidLiveDealExpired(dealId, initiator, fundsToReturn);
				} else {
					emit AskLiveDealExpired(dealId, initiator, fundsToReturn);
				}

				// Transfer funds back to initiator of deal, since BidLive/AskLive
				// implies either buyer of seller are involved, but not both
				SafeERC20.safeTransfer(token, initiator, fundsToReturn);
			}
		} else if (deal.state == LibStructStorage.DealState.Matched) {
			// If startDate < date <= maturityDate, deal should become Live
			if (deal.voucher.startDate < date && date <= deal.voucher.maturityDate) {
				address oracleAddress = IAccessControl(address(this)).getOracleAddress();
				if (!ICerchiaOracle(oracleAddress).isWorking()) {
					_automaticDissolution(callerAddress, deal.voucher.configurationId, date);
				} else {
					deal.state = LibStructStorage.DealState.Live;
					emit MatchedDealWentLive(deal.id);

					// A Live deal where startDate < date <= maturityDate should attempt to trigger
					// Here we want to compare calendar dates
					// (date should be bigger than startDate in date terms, not time as well)
					// A simple comparison like deal.voucher.startDate < date wouldn't work
					// because startDate is in 00:00:00 format,
					// while date is in 23:59:59 format
					if (deal.voucher.startDate + LibCommonOperations.SECONDS_IN_A_DAY - 1 < date) {
						_processEoDForLiveDeal(date, deal);
					}
				}
			}
		} else if (deal.state == LibStructStorage.DealState.Live) {
			// A Live deal where startDate < date <= maturityDate should attempt to trigger
			// Here we want to compare calendar dates
			// (date should be bigger than startDate in date terms, not time as well)
			// A simple comparison like deal.voucher.startDate < date wouldn't work
			// because startDate is in 00:00:00 format,
			// while date is in 23:59:59 format
			if (
				deal.voucher.startDate + LibCommonOperations.SECONDS_IN_A_DAY - 1 < date &&
				date <= deal.voucher.maturityDate
			) {
				_processEoDForLiveDeal(date, deal);
			}
		}
	}

	/**
	 * @dev     During Settlement, if a deal is Live and after the standard's startDate, its' strike can be compared
	 *          to the existing levels, which can trigger or mature the deal
	 * @dev     Should revert if there is no index level to compare to, for date + configurationId combination
	 * @dev     If triggered (level >= strike), buyer receives notional without fee, fee address receives fee,
	 *          and deal is deleted
	 * @dev     If matured (date >= standard.maturityDate and level is stil < strike), seller receives notional
	 *          without fee, fee address receives fee, and deal is deleted
	 * @param   date  Timestamp to settle deal for
	 * @param   deal  Deal to try and settle
	 */
	function _processEoDForLiveDeal(uint64 date, LibStructStorage.Deal storage deal) private {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Revert if no index level to compare to
		LibStructStorage.IndexLevel storage indexLevel = s._indexLevels[deal.voucher.configurationId][date];
		if (!indexLevel.exists) {
			revert(LibStructStorage.SETTLEMENT_INDEX_LEVEL_DOES_NOT_EXIST);
		}

		int128 strike = deal.voucher.strike;
		int128 level = s._indexLevels[deal.voucher.configurationId][date].value;

		address feeAddress = IAccessControl(address(this)).getFeeAddress();
		uint128 fundsToFeeAddress = (deal.voucher.notional * deal.voucher.feeInBps) / LibStructStorage.MAX_FEE_IN_BPS;
		if (level >= strike) {
			// Triggered
			// Should send (fundsToFeeAddress = funds * feeInBps) to feeAddress
			// Should send (fundstoBuyer = funds - funds * feeInBps) to buyer
			uint256 dealId = deal.id;
			address buyer = deal.buyer;
			uint128 fundsToBuyer = deal.funds - fundsToFeeAddress;
			IERC20 token = IERC20(deal.voucher.token);

			// Both userActiveDealsCount should decrement
			s._userActiveDealsCount[buyer][deal.voucher.configurationId]--;
			s._userActiveDealsCount[deal.seller][deal.voucher.configurationId]--;

			// No need to check if deal exists, reaching this point means it exists
			// Deal is triggered so finished, should be deleted
			s._dealsSet.deleteById(dealId);

			// Emit triggered event
			emit LiveDealTriggered(dealId, buyer, fundsToBuyer, feeAddress, fundsToFeeAddress);

			// Send fee to feeAddress and remainder to buyer
			SafeERC20.safeTransfer(token, feeAddress, fundsToFeeAddress);
			SafeERC20.safeTransfer(token, buyer, fundsToBuyer);
		} else {
			if (date >= deal.voucher.maturityDate) {
				// Matured
				// Should send (fundsToFeeAddress = funds * feeInBps) to feeAddress
				// Should send (fundsToSeller = funds - funds * feeInBps) to seller
				uint256 dealId = deal.id;
				address seller = deal.seller;
				uint128 fundsToSeller = deal.funds - fundsToFeeAddress;
				IERC20 token = IERC20(deal.voucher.token);

				// Both userActiveDealsCount should decrement
				s._userActiveDealsCount[deal.buyer][deal.voucher.configurationId]--;
				s._userActiveDealsCount[seller][deal.voucher.configurationId]--;

				// No need to check if deal exists, reaching this point means it exists
				// Deal is matured so finished, should be deleted
				s._dealsSet.deleteById(dealId);

				// Emit matured event
				emit LiveDealMatured(dealId, seller, fundsToSeller, feeAddress, fundsToFeeAddress);

				// Send fee to feeAddress and remainder to seller
				SafeERC20.safeTransfer(token, feeAddress, fundsToFeeAddress);
				SafeERC20.safeTransfer(token, seller, fundsToSeller);
			}
		}
	}
}
