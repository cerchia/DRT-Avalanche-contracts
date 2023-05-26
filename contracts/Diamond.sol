// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
import { ICerchiaDRT } from "./interfaces/ICerchiaDRT.sol";
import { IAccessControl } from "./interfaces/IAccessControl.sol";
import { IMatchDeal } from "./interfaces/IMatchDeal.sol";
import { IAnyAccountOperationsFacet } from "./interfaces/IAnyAccountOperationsFacet.sol";
import { IGetEntityFacet } from "./interfaces/IGetEntityFacet.sol";
import { IClaimBackFacet } from "./interfaces/IClaimBackFacet.sol";
import { IOwnerOperations } from "./interfaces/IOwnerOperations.sol";

import { LibDiamond } from "./libraries/LibDiamond.sol";

import { DiamondInit } from "./facets/DiamondInit.sol";

/**
 * @title CerchiaDRT Diamond
 * @notice Encapsulates core DRT functionality (creating deals, cancelling, matching, settling, etc.)
 * @dev Should be 1-1 implementation of Nick Mudgen's Diamond 3
 */
contract Diamond {
	constructor(
		address diamondLoupeFacet,
		address diamondInitFacet,
		address cerchiaDRTFacet,
		address accessControlFacet,
		address matchDealFacet,
		address anyAccountOperationsFacet,
		address getEntityFacet,
		address claimBackFacet,
		address ownerOperationsFacet
	) {
		// Add the diamondCut external function from the diamondCutFacet
		IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](9);

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

		// Cerchia DRT Facet
		bytes4[] memory cerchiaDRTSelectors = new bytes4[](3);
		cerchiaDRTSelectors[0] = ICerchiaDRT.userCreateNewDealAsBid.selector;
		cerchiaDRTSelectors[1] = ICerchiaDRT.userCreateNewDealAsAsk.selector;
		cerchiaDRTSelectors[2] = ICerchiaDRT.userUpdateDealToCancel.selector;

		cuts[2] = IDiamondCut.FacetCut({
			facetAddress: cerchiaDRTFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: cerchiaDRTSelectors
		});

		// Access Control Facet
		bytes4[] memory accessControlFacetSelectors = new bytes4[](10);
		accessControlFacetSelectors[0] = IAccessControl.initAccessControlFacet.selector;
		accessControlFacetSelectors[1] = IAccessControl.ownerDeactivateAllFunctions.selector;
		accessControlFacetSelectors[2] = IAccessControl.ownerDeactivateUserFunctions.selector;
		accessControlFacetSelectors[3] = IAccessControl.ownerDeactivateOperatorFunctions.selector;
		accessControlFacetSelectors[4] = IAccessControl.ownerActivateOperatorFunctions.selector;
		accessControlFacetSelectors[5] = IAccessControl.getFeeAddress.selector;
		accessControlFacetSelectors[6] = IAccessControl.getOracleAddress.selector;
		accessControlFacetSelectors[7] = IAccessControl.hasRole.selector;
		accessControlFacetSelectors[8] = IAccessControl.isKYXProvider.selector;
		accessControlFacetSelectors[9] = IAccessControl.isUser.selector;

		cuts[3] = IDiamondCut.FacetCut({
			facetAddress: accessControlFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: accessControlFacetSelectors
		});

		// MatchDeal Facet
		bytes4[] memory matchDealSelectors = new bytes4[](2);
		matchDealSelectors[0] = IMatchDeal.userUpdateDealFromBidToMatched.selector;
		matchDealSelectors[1] = IMatchDeal.userUpdateDealFromAskToMatched.selector;

		cuts[4] = IDiamondCut.FacetCut({
			facetAddress: matchDealFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: matchDealSelectors
		});

		// Any account operations facet
		bytes4[] memory anyAccountOperationsSelectors = new bytes4[](5);
		anyAccountOperationsSelectors[0] = IAnyAccountOperationsFacet.initiateIndexDataUpdate.selector;
		anyAccountOperationsSelectors[1] = IAnyAccountOperationsFacet.operatorInitiateIndexDataUpdate.selector;
		anyAccountOperationsSelectors[2] = IAnyAccountOperationsFacet.indexDataCallBack.selector;
		anyAccountOperationsSelectors[3] = IAnyAccountOperationsFacet.processContingentSettlement.selector;
		anyAccountOperationsSelectors[4] = IAnyAccountOperationsFacet.operatorProcessContingentSettlement.selector;

		cuts[5] = IDiamondCut.FacetCut({
			facetAddress: anyAccountOperationsFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: anyAccountOperationsSelectors
		});

		// GetEntityFacet
		bytes4[] memory getEntityFacetSelectors = new bytes4[](16);
		getEntityFacetSelectors[0] = IGetEntityFacet.getStandardSymbols.selector;
		getEntityFacetSelectors[1] = IGetEntityFacet.getStandard.selector;
		getEntityFacetSelectors[2] = IGetEntityFacet.getTokenSymbols.selector;
		getEntityFacetSelectors[3] = IGetEntityFacet.getTokenAddress.selector;
		getEntityFacetSelectors[4] = IGetEntityFacet.getDeal.selector;
		getEntityFacetSelectors[5] = IGetEntityFacet.getDealIds.selector;
		getEntityFacetSelectors[6] = IGetEntityFacet.getIndexLevelTimestamps.selector;
		getEntityFacetSelectors[7] = IGetEntityFacet.getUserActiveDealsCount.selector;
		getEntityFacetSelectors[8] = IGetEntityFacet.isRestrictedToUserClaimBack.selector;
		getEntityFacetSelectors[9] = IGetEntityFacet.getIsDeactivatedForOwners.selector;
		getEntityFacetSelectors[10] = IGetEntityFacet.getIsDeactivatedForOperators.selector;
		getEntityFacetSelectors[11] = IGetEntityFacet.isInDissolution.selector;
		getEntityFacetSelectors[12] = IGetEntityFacet.isLevelSet.selector;
		getEntityFacetSelectors[13] = IGetEntityFacet.getLevel.selector;
		getEntityFacetSelectors[14] = IGetEntityFacet.getKYXProvidersAddresses.selector;
		getEntityFacetSelectors[15] = IGetEntityFacet.getKYXProviderName.selector;

		cuts[6] = IDiamondCut.FacetCut({
			facetAddress: getEntityFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: getEntityFacetSelectors
		});

		// ClaimBack Facet
		bytes4[] memory claimBackFacetSelectors = new bytes4[](1);
		claimBackFacetSelectors[0] = IClaimBackFacet.claimBack.selector;

		cuts[7] = IDiamondCut.FacetCut({
			facetAddress: claimBackFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: claimBackFacetSelectors
		});

		// Owner Operations Facet
		bytes4[] memory ownerOperationsFacetSelectors = new bytes4[](6);
		ownerOperationsFacetSelectors[0] = IOwnerOperations.ownerAddNewStandard.selector;
		ownerOperationsFacetSelectors[1] = IOwnerOperations.ownerAddNewToken.selector;
		ownerOperationsFacetSelectors[2] = IOwnerOperations.ownerDeleteStandards.selector;
		ownerOperationsFacetSelectors[3] = IOwnerOperations.ownerDeleteTokens.selector;
		ownerOperationsFacetSelectors[4] = IOwnerOperations.ownerAddNewKYXProvider.selector;
		ownerOperationsFacetSelectors[5] = IOwnerOperations.ownerDeleteKYXProviders.selector;

		cuts[8] = IDiamondCut.FacetCut({
			facetAddress: ownerOperationsFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: ownerOperationsFacetSelectors
		});

		LibDiamond.diamondCut(cuts, address(0), "");
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
		require(facet != address(0), string(abi.encodePacked("Diamond: Function does not exist: ", msg.sig)));

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
