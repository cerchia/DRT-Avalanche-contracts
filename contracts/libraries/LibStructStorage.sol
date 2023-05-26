// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title   Wrapper library storing constants and structs of CerchiaDRT Diamond
 */
library LibStructStorage {
	enum DealState {
		BidLive, // if deal only has Bid side
		AskLive, // if deal only has Ask side
		Matched, // if deal has both sides, but it can't yet be triggered/matured
		Live // if deal has both sides, and it can be triggered/matured
	}

	struct Standard {
		// keccak256 of JSON containing parameter set for off-chain API
		bytes32 configurationId;
		// value under which deal doesn't trigger
		int128 strike;
		// fee to send to fee address, represented in basis points
		uint128 feeInBps;
		// start date for the time of protection
		uint64 startDate;
		// end date for the time of protection
		uint64 maturityDate;
		// Similar to ERC20's decimals. Off-chain API data is of float type.
		// On the blockchain, we sent it multiplied by 10 ** exponentOfTenMultiplierForStrike, to make it integer
		uint8 exponentOfTenMultiplierForStrike;
	}

	struct Voucher {
		// units won by either side, when deal triggers/matures
		uint128 notional;
		// units paid by Bid side
		uint128 premium;
		// is copied over from Standard
		bytes32 configurationId;
		// is copied over from Standard
		uint128 feeInBps;
		// is copied over from Standard
		int128 strike;
		// is copied over from Standard
		uint64 startDate;
		// is copied over from Standard
		uint64 maturityDate;
		// token that deal operates on
		address token;
	}

	struct Deal {
		// address that created the deal
		address initiator;
		// address of the Bid side
		address buyer;
		// address of the Ask side
		address seller;
		// funds currently in the deal: premium if BidLive, (notional - premium) if AskLive, notional if Matched/Live
		uint128 funds;
		// timestamp after which deal will expire, if still in BidLive/AskLive state
		uint64 expiryDate;
		Voucher voucher;
		DealState state;
		// true if buyer claimed back funds, if dissolution happened
		bool buyerHasClaimedBack;
		// true if seller claimed back funds, if dissolution happened
		bool sellerHasClaimedBack;
		// for LibDealsSet.sol implementation of a CRUD interface
		uint256 id;
		uint256 indexInDealsArray;
	}

	struct IndexLevel {
		// value of the off-chain observation, for a date + parameter set configuration
		int128 value;
		// since a value of 0 is valid, we need a flag to check if an index level was set or not
		bool exists;
	}

	// Error codes with descriptive names
	string public constant UNIX_TIMESTAMP_IS_NOT_EXACT_DATE = "1";
	string public constant STANDARD_SYMBOL_IS_EMPTY = "2";
	string public constant STANDARD_WITH_SAME_SYMBOL_ALREADY_EXISTS = "3";
	string public constant STANDARD_START_DATE_IS_ZERO = "4";
	string public constant STANDARD_MATURITY_DATE_IS_NOT_BIGGER_THAN_START_DATE = "5";
	string public constant STANDARD_FEE_IN_BPS_EXCEEDS_MAX_FEE_IN_BPS = "6";
	string public constant ACCOUNT_TO_BE_OWNER_IS_ALREADY_OWNER = "7";
	string public constant ACCOUNT_TO_BE_OPERATOR_IS_ALREADY_OWNER = "8";
	string public constant ACCOUNT_TO_BE_OPERATOR_IS_ALREADY_OPERATOR = "9";
	string public constant TOKEN_WITH_DENOMINATION_ALREADY_EXISTS = "10";
	string public constant TOKEN_ADDRESS_CANNOT_BE_EMPTY = "11";
	string public constant TRANSITION_CALLER_IS_NOT_OWNER = "12";
	string public constant DEACTIVATED_FOR_OWNERS = "13";
	string public constant ACCESS_CONTROL_FACET_ALREADY_INITIALIZED = "14";
	string public constant TOKEN_DENOMINATION_IS_EMPTY = "15";
	string public constant SHOULD_BE_OWNER = "16";
	string public constant EMPTY_SYMBOL = "20";
	string public constant EMPTY_DENOMINATION = "21";
	string public constant STANDARD_NOT_FOUND = "22";
	string public constant STANDARD_DOES_NOT_EXIST = "23";
	string public constant TOKEN_DOES_NOT_EXIST = "24";
	string public constant NOTIONAL_SHOULD_BE_GREATER_THAN_ZERO = "25";
	string public constant NOTIONAL_SHOULD_BE_MULTIPLE_OF_10000 = "26";
	string public constant PREMIUM_SHOULD_BE_LESS_THAN_NOTIONAL = "27";
	string public constant INSUFFICIENT_BALANCE = "28";
	string public constant ERROR_TRANSFERRING_TOKEN = "29";
	string public constant INSUFFICIENT_SPEND_TOKEN_ALLOWENCE = "30";
	string public constant EXPIRY_DATE_SHOULD_BE_LESS_THAN_OR_EQUAL_TO_MATURITY_DATE = "31";
	string public constant EXPIRY_DATE_CANT_BE_IN_THE_PAST = "32";
	string public constant PREMIUM_SHOULD_BE_GREATER_THAN_ZERO = "33";
	string public constant ONLY_CLAIMBACK_ALLOWED = "34";
	string public constant NO_DEAL_FOR_THIS_DEAL_ID = "35";
	string public constant DEAL_CAN_NOT_BE_CANCELLED = "36";
	string public constant USER_TO_CANCEL_DEAL_IS_NOT_INITIATOR = "37";
	string public constant TOKEN_WITH_DENOMINATION_DOES_NOT_EXIST = "38";
	string public constant TOKEN_TRANSFER_FAILED = "39";
	string public constant ACCOUNT_TO_BE_FEE_ADDRESS_IS_ALREADY_OWNER = "40";
	string public constant ACCOUNT_TO_BE_FEE_ADDRESS_IS_ALREADY_OPERATOR = "41";
	string public constant DEAL_ID_SHOULD_BE_GREATER_THAN_OR_EQUAL_TO_ZERO = "42";
	string public constant DEAL_NOT_FOUND = "43";
	string public constant DEAL_STATE_IS_NOT_ASK_LIVE = "44";
	string public constant CAN_NOT_MATCH_YOUR_OWN_DEAL = "45";
	string public constant DEAL_SELLER_SHOULD_NOT_BE_EMPTY = "46";
	string public constant DEAL_BUYER_IS_EMPTY = "47";
	string public constant DEAL_STATE_IS_NOT_BID_LIVE = "48";
	string public constant DEAL_BUYER_SHOULD_NOT_BE_EMPTY = "49";
	string public constant STRIKE_IS_NOT_MULTIPLE_OF_TEN_RAISED_TO_EXPONENT = "50";
	string public constant CONFIGURATION_ID_IS_EMPTY = "51";
	string public constant USER_HAS_NO_ACTIVE_DEALS_FOR_CONFIGURATION_ID = "52";
	string public constant CALLER_IS_NOT_ORACLE_ADDRESS = "53";
	string public constant TIMESTAMP_SHOULD_BE_VALID_BLOCK_TIMESTAMP = "54";
	string public constant ORACLE_DID_NOT_FULLFIL = "55";
	string public constant SETTLEMENT_INDEX_LEVEL_DOES_NOT_EXIST = "56";
	string public constant MATURITY_DATE_SHOULD_BE_IN_THE_FUTURE = "57";
	string public constant CONTRACT_IS_IN_DISSOLUTION = "58";
	string public constant CANNOT_CLAIM_BACK_UNLESS_IN_DISSOLUTION = "59";
	string public constant CALLER_IS_NOT_VALID_DEAL_CLAIMER = "60";
	string public constant FUNDS_ALREADY_CLAIMED = "61";
	string public constant THERE_ARE_STILL_DEALS_LEFT = "62";
	string public constant DEACTIVATED_FOR_OPERATORS = "63";
	string public constant NEED_TO_PASS_KYX = "64";
	string public constant ONLY_OPERATOR_ALLOWED = "65";
	string public constant SHOULD_BE_END_USER = "66";
	string public constant MISSING_KYX_PROVIDER_NAME = "67";
	string public constant KYX_PROVIDER_ADDRESS_CAN_NOT_BE_EMPTY = "68";
	string public constant KYX_PROVIDER_ALREADY_EXISTS = "69";
	string public constant CANNOT_SETTLE_SOMEONE_ELSES_DEAL = "70";
	string public constant UNIX_TIMESTAMP_IS_NOT_END_OF_DATE = "71";

	// Value representing invalid index level from off-chain API
	int128 public constant INVALID_LEVEL_VALUE = type(int128).min;

	// Commonly used constants
	uint128 public constant TEN_THOUSAND = 10000;
	uint128 public constant MAX_FEE_IN_BPS = TEN_THOUSAND;
	uint128 public constant ZERO = 0;

	// Used by AccessControlFacet's OpenZeppelin Roles implementation
	bytes32 public constant OWNER_ROLE = keccak256("OWNER");
	bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
}
