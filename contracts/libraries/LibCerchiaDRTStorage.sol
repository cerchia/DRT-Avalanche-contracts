// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibDealsSet } from "../libraries/LibDealsSet.sol";

/**
 * @title   Diamond Storage for CerchiaDRT Diamond's functions, except access control
 */
library LibCerchiaDRTStorage {
	bytes32 public constant CERCHIA_DRT_STORAGE_SLOT = keccak256("CERCHIA.DRT.STORAGE");

	/**
	 * @dev https://dev.to/mudgen/how-diamond-storage-works-90e
	 */
	struct CerchiaDRTStorage {
		// Standards
		// mapping(standard symbol => Standard)
		mapping(string => LibStructStorage.Standard) _standards;
		// list of all standard symbols
		string[] _standardsKeys;
		// Tokens
		// mapping(token symbol => token's address)
		mapping(string => address) _tokens;
		// list of all token symbols
		string[] _tokensKeys;
		// Deals
		// all the deals, structured so that we can easily do CRUD operations on them
		LibDealsSet.DealsSet _dealsSet;
		// Index levels
		// ConfigurationId (bytes32) -> Day (timestamp as uint64) -> Level
		mapping(bytes32 => mapping(uint64 => LibStructStorage.IndexLevel)) _indexLevels;
		// For each configurationId, stores a list of all the timestamps for which we have indexlevels
		mapping(bytes32 => uint64[]) _indexLevelTimestamps;
		// How many Active (Matched/Live) deals a user is involved in, for a configurationId
		mapping(address => mapping(bytes32 => uint32)) _userActiveDealsCount;
		// True if AutomaticDissolution was triggered
		bool _isInDissolution;
	}

	/**
	 * @dev     https://dev.to/mudgen/how-diamond-storage-works-90e
	 * @return  s  Returns a pointer to an "arbitrary" location in memory
	 */
	function getStorage() external pure returns (CerchiaDRTStorage storage s) {
		bytes32 position = CERCHIA_DRT_STORAGE_SLOT;
		assembly {
			s.slot := position
		}
	}
}
