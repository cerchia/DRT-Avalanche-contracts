// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IGetEntityFacet } from "../interfaces/IGetEntityFacet.sol";
import { IOwnerOperations } from "../interfaces/IOwnerOperations.sol";

import { LibCommonOperations } from "../libraries/LibCommonOperations.sol";
import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibCerchiaDRTStorage as Storage } from "../libraries/LibCerchiaDRTStorage.sol";
import { LibAccessControlStorage as ACStorage } from "../libraries/LibAccessControlStorage.sol";

import { RoleBased } from "../RoleBased.sol";

/**
 * @title  CerchiaDRT Diamond Owner Operations Implementation
 */
contract OwnerOperationsFacet is RoleBased, IOwnerOperations {
	/**
	 * @dev     Our project operates with exact timestamps only (think 2022-07-13 00:00:00), sent as Unix Epoch
	 * @param   unixTimestamp  Unix Epoch to be divisible by number of seconds in a day
	 */
	modifier isExactDate(uint64 unixTimestamp) {
		require(LibCommonOperations._isExactDate(unixTimestamp), LibStructStorage.UNIX_TIMESTAMP_IS_NOT_EXACT_DATE);
		_;
	}

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
	 * @dev Prevents calling a function if owners are deactivated
	 */
	modifier isNotDeactivatedForOwner() {
		require(!IGetEntityFacet(address(this)).getIsDeactivatedForOwners(), LibStructStorage.DEACTIVATED_FOR_OWNERS);
		_;
	}

	/**
	 * @inheritdoc IOwnerOperations
	 */
	function ownerAddNewStandard(
		bytes32 configurationId,
		string calldata symbol,
		uint64 startDate,
		uint64 maturityDate,
		uint128 feeInBps,
		int128 strike,
		uint8 exponentOfTenMultiplierForStrike
	) external onlyOwner isNotDeactivatedForOwner isExactDate(startDate) isEndOfDate(maturityDate) {
		// Check calldata is valid (also in modifiers)
		require(LibCommonOperations._isNotEmpty(symbol), LibStructStorage.STANDARD_SYMBOL_IS_EMPTY);
		require(startDate > 0, LibStructStorage.STANDARD_START_DATE_IS_ZERO);
		require(maturityDate > startDate, LibStructStorage.STANDARD_MATURITY_DATE_IS_NOT_BIGGER_THAN_START_DATE);

		// solhint-disable-next-line not-rely-on-time
		require(maturityDate > block.timestamp, LibStructStorage.MATURITY_DATE_SHOULD_BE_IN_THE_FUTURE);

		require(
			feeInBps < LibStructStorage.MAX_FEE_IN_BPS,
			LibStructStorage.STANDARD_FEE_IN_BPS_EXCEEDS_MAX_FEE_IN_BPS
		);

		// Check standard with same symbol doesn't already exist
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();
		require(s._standards[symbol].startDate == 0, LibStructStorage.STANDARD_WITH_SAME_SYMBOL_ALREADY_EXISTS);

		// Store new standard and its symbol
		s._standards[symbol] = LibStructStorage.Standard(
			configurationId,
			strike,
			feeInBps,
			startDate,
			maturityDate,
			exponentOfTenMultiplierForStrike
		);
		s._standardsKeys.push(symbol);

		// Emit event
		_emitOwnerAddNewStandard(symbol, s._standards[symbol]);
	}

	/**
	 * @inheritdoc IOwnerOperations
	 * @dev  On Avalanche Fuji Chain, owner would call this with ("USDC", <REAL_USDC_ADDRESS_ON_FUJI>)
	 */
	function ownerAddNewToken(string calldata denomination, address token) external onlyOwner isNotDeactivatedForOwner {
		// Check calldata is valid
		require(LibCommonOperations._isNotEmpty(denomination), LibStructStorage.TOKEN_DENOMINATION_IS_EMPTY);
		require(token != address(0), LibStructStorage.TOKEN_ADDRESS_CANNOT_BE_EMPTY);

		// Check token doesn't already exist
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();
		require(
			!LibCommonOperations._tokenExists(s._tokens[denomination]),
			LibStructStorage.TOKEN_WITH_DENOMINATION_ALREADY_EXISTS
		);

		// Store new token and its denomination
		s._tokens[denomination] = token;
		s._tokensKeys.push(denomination);

		// Emit event
		emit OwnerAddedNewToken(msg.sender, denomination, token);
	}

	/**
	 * @inheritdoc  IOwnerOperations
	 * @dev         Since we expect a small number of standards, controller by owners, the below "for" loops are
	 *              not a gas or DoS concern
	 */
	function ownerDeleteStandards(string[] calldata symbols) external onlyOwner isNotDeactivatedForOwner {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		uint256 symbolsLength = symbols.length;

		// For each symbol to delete
		for (uint256 symbolIdx; symbolIdx < symbolsLength; ) {
			string calldata symbol = symbols[symbolIdx];

			uint256 standardKeysLength = s._standardsKeys.length;

			// If standard with that symbol exists
			if (s._standards[symbol].startDate > 0) {
				// Delete it from mapping
				delete s._standards[symbol];

				// Find its key in array and delete (use swap-with-last method)
				for (uint256 searchIdx; searchIdx < standardKeysLength; ) {
					if (_compareStrings(s._standardsKeys[searchIdx], symbol)) {
						s._standardsKeys[searchIdx] = s._standardsKeys[standardKeysLength - 1];
						s._standardsKeys.pop();
						break;
					}

					unchecked {
						++searchIdx;
					}
				}

				// Emit event
				emit OwnerDeletedStandard(msg.sender, symbol);
			}

			unchecked {
				++symbolIdx;
			}
		}
	}

	/**
	 * @inheritdoc IOwnerOperations
	 * @dev     Since we expect a small number of tokens, controller by owners, the below "for" loops are
	 *          not a gas or DoS concern
	 */
	function ownerDeleteTokens(string[] calldata symbols) external onlyOwner isNotDeactivatedForOwner {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		uint256 symbolsLength = symbols.length;

		// For each denomination to delete
		for (uint256 symbolIdx; symbolIdx < symbolsLength; ) {
			string calldata symbol = symbols[symbolIdx];

			uint256 tokenKeysLength = s._tokensKeys.length;

			// If token with that denomination exists
			if (s._tokens[symbol] != address(0)) {
				// Delete token from mapping
				delete s._tokens[symbol];

				// Find its key in array and delete (use swap-with-last method)
				for (uint256 searchIdx; searchIdx < tokenKeysLength; ) {
					if (_compareStrings(s._tokensKeys[searchIdx], symbol)) {
						s._tokensKeys[searchIdx] = s._tokensKeys[tokenKeysLength - 1];
						s._tokensKeys.pop();
						break;
					}

					unchecked {
						++searchIdx;
					}
				}

				// Emit event
				emit OwnerDeletedToken(msg.sender, symbol);
			}

			unchecked {
				++symbolIdx;
			}
		}
	}

	/**
	 * @param   a  First string
	 * @param   b  Seconds string
	 * @return  bool  True if strings are equal
	 */
	function _compareStrings(string memory a, string memory b) private pure returns (bool) {
		return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
	}

	/**
	 * @dev     Helper function to emit OwnerAddNewStandard event, to avoid StackTooDeep issue
	 * @param   symbol  Symbol of standard
	 * @param   standard  Whole standard struct
	 */
	function _emitOwnerAddNewStandard(string calldata symbol, LibStructStorage.Standard storage standard) private {
		emit OwnerAddedNewStandard(
			msg.sender,
			symbol,
			standard.configurationId,
			standard.strike,
			standard.feeInBps,
			standard.startDate,
			standard.maturityDate,
			standard.exponentOfTenMultiplierForStrike
		);
	}

	function ownerAddNewKYXProvider(
		address kyxProviderAddress,
		string calldata name
	) external override onlyOwner isNotDeactivatedForOwner {
		require(kyxProviderAddress != address(0), LibStructStorage.KYX_PROVIDER_ADDRESS_CAN_NOT_BE_EMPTY);
		require(LibCommonOperations._isNotEmpty(name), LibStructStorage.MISSING_KYX_PROVIDER_NAME);

		// Check KYX Provider doesn't already exist
		ACStorage.AccessControlStorage storage acStorage = ACStorage.getStorage();
		require(
			bytes(acStorage._kyxProviders[kyxProviderAddress]).length == 0,
			LibStructStorage.KYX_PROVIDER_ALREADY_EXISTS
		);

		acStorage._kyxProviders[kyxProviderAddress] = name;
		acStorage._kyxProvidersKeys.push(kyxProviderAddress);

		// Emit event
		emit OwnerAddedNewKYXProvider(msg.sender, name, kyxProviderAddress);
	}

	function ownerDeleteKYXProviders(
		address[] calldata providersToDelete
	) external override onlyOwner isNotDeactivatedForOwner {
		ACStorage.AccessControlStorage storage acStorage = ACStorage.getStorage();

		uint256 providersToDeleteLength = providersToDelete.length;

		// For each kyxProvider to delete
		for (uint256 providerIndexToDelete; providerIndexToDelete < providersToDeleteLength; ) {
			address providerAddressToDelete = providersToDelete[providerIndexToDelete];
			uint256 kyxProviderKeysLength = acStorage._kyxProvidersKeys.length;

			// Get the name from the address
			string memory name = acStorage._kyxProviders[providerAddressToDelete];

			// If kyxProvider with that name exists
			if (bytes(name).length > 0) {
				// Delete kyxProvider from mapping
				delete acStorage._kyxProviders[providerAddressToDelete];

				// Find its key in array and delete (use swap-with-last method)
				for (uint256 searchIdx; searchIdx < kyxProviderKeysLength; ) {
					if (providerAddressToDelete == acStorage._kyxProvidersKeys[searchIdx]) {
						acStorage._kyxProvidersKeys[searchIdx] = acStorage._kyxProvidersKeys[kyxProviderKeysLength - 1];
						acStorage._kyxProvidersKeys.pop();
						break;
					}

					unchecked {
						++searchIdx;
					}
				}

				// Emit event
				emit OwnerDeletedKYXProvider(msg.sender, name, providerAddressToDelete);
			}

			unchecked {
				++providerIndexToDelete;
			}
		}
	}
}
