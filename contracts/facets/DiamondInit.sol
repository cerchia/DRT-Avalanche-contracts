// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";

import { LibDiamond } from "../libraries/LibDiamond.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

/**
 * @title  CerchiaDRT and Oracle Diamonds DiamondInit Implementation
 */
contract DiamondInit {
	// You can add parameters to this function in order to pass in
	// data to set your own state variables

	/**
	 * @dev     Currently called from any of our Diamonds' constructors
	 * @dev     Initializes storage with the correct interfaces supported
	 */
	function init() external {
		// adding ERC165 data
		LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
		ds.supportedInterfaces[type(IERC165).interfaceId] = true;
		ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;

		// add your own state variables
		// EIP-2535 specifies that the `diamondCut` function takes two optional
		// arguments: address _init and bytes calldata _calldata
		// These arguments are used to execute an arbitrary function using delegatecall
		// in order to set state variables in the diamond during deployment or an upgrade
		// More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
	}
}
