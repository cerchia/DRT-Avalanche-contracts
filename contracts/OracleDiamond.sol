// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
import { IAccessControlOracle } from "./interfaces/IAccessControlOracle.sol";
import { ICerchiaOracle } from "./interfaces/ICerchiaOracle.sol";

import { LibDiamond } from "./libraries/LibDiamond.sol";

import { DiamondInit } from "./facets/DiamondInit.sol";

/**
 * @title Oracle Diamond
 * @dev Encapsulates Oracle functionality (GetLevel, OwnerSetLevel, etc.)
 * @dev Should be 1-1 implementation of Nick Mudgen's Diamond 3
 */
contract OracleDiamond {
	constructor(
		address diamondLoupeFacet,
		address diamondInitFacet,
		address cerchiaOracleFacet,
		address accessControlOracleFacet
	) {
		// Add the diamondCut external function from the diamondCutFacet
		IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](4);

		// Diamond Loupe Facet
		bytes4[] memory diamondLoupeFacetSelectors = new bytes4[](5);
		diamondLoupeFacetSelectors[0] = IDiamondLoupe.facets.selector;
		diamondLoupeFacetSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
		diamondLoupeFacetSelectors[2] = IDiamondLoupe.facetAddresses.selector;
		diamondLoupeFacetSelectors[3] = IDiamondLoupe.facetAddress.selector;
		diamondLoupeFacetSelectors[4] = IERC165.supportsInterface.selector;

		cuts[0] = IDiamondCut.FacetCut({
			facetAddress: diamondLoupeFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: diamondLoupeFacetSelectors
		});

		// Diamond Init Facet
		bytes4[] memory diamondInitFacetSelectors = new bytes4[](1);
		diamondInitFacetSelectors[0] = DiamondInit.init.selector;

		cuts[1] = IDiamondCut.FacetCut({
			facetAddress: diamondInitFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: diamondInitFacetSelectors
		});

		// Cerchia Oracle Facet
		bytes4[] memory cerchiaOracleSelectors = new bytes4[](6);
		cerchiaOracleSelectors[0] = ICerchiaOracle.getLevel.selector;
		cerchiaOracleSelectors[1] = ICerchiaOracle.ownerSetLevel.selector;
		cerchiaOracleSelectors[2] = ICerchiaOracle.ownerSetStatus.selector;
		cerchiaOracleSelectors[3] = ICerchiaOracle.isWorking.selector;
		cerchiaOracleSelectors[4] = ICerchiaOracle.getLastRequestIndex.selector;
		cerchiaOracleSelectors[5] = ICerchiaOracle.getRequestor.selector;

		cuts[2] = IDiamondCut.FacetCut({
			facetAddress: cerchiaOracleFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: cerchiaOracleSelectors
		});

		// Access Control Facet
		bytes4[] memory accessControlFacetOracleSelectors = new bytes4[](7);
		accessControlFacetOracleSelectors[0] = IAccessControlOracle.initAccessControlFacet.selector;
		accessControlFacetOracleSelectors[1] = IAccessControlOracle.requestOwnershipTransfer.selector;
		accessControlFacetOracleSelectors[2] = IAccessControlOracle.confirmOwnershipTransfer.selector;
		accessControlFacetOracleSelectors[3] = IAccessControlOracle.cancelOwnershipTransfer.selector;
		accessControlFacetOracleSelectors[4] = IAccessControlOracle.getOwner.selector;
		accessControlFacetOracleSelectors[5] = IAccessControlOracle.getProposedNewOwner.selector;
		accessControlFacetOracleSelectors[6] = IAccessControlOracle.getCerchiaDRTAddress.selector;

		cuts[3] = IDiamondCut.FacetCut({
			facetAddress: accessControlOracleFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: accessControlFacetOracleSelectors
		});

		LibDiamond.diamondCut(cuts, diamondInitFacet, abi.encodeWithSelector(DiamondInit.init.selector));
	}

	// solhint-disable-next-line no-empty-blocks
	receive() external payable {}

	// Find facet for function that is called and execute the
	// function if a facet is found and return any value.
	fallback() external payable {
		LibDiamond.DiamondStorage storage ds;
		bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
		// get diamond storage
		assembly {
			ds.slot := position
		}
		// get facet from function selector
		address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
		require(facet != address(0), string(abi.encodePacked("OracleDiamond: Function does not exist: ", msg.sig)));

		// Execute external function from facet using delegatecall and return any value.
		assembly {
			// copy function selector and any arguments
			calldatacopy(0, 0, calldatasize())
			// execute function call using the facet
			let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
			// get any return value
			returndatacopy(0, 0, returndatasize())
			// return any return value or error back to the caller
			switch result
			case 0 {
				revert(0, returndatasize())
			}
			default {
				return(0, returndatasize())
			}
		}
	}
}
