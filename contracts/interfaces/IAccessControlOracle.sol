// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title  Oracle Diamond Access Control Interface
 * @notice Used to control what functions an address can call
 */
interface IAccessControlOracle {
	/**
	 * @notice Emitted when ownership was transfered to someone else
	 */
	event OwnershipTransfered(address indexed previousOwner, address indexed newOwner);

	/**
	 * @notice Emitted when a new owner was proposed
	 */
	event RequestOwnershipTransfer(address indexed owner, address indexed proposedNewOwner);

	/**
	 * @notice Emitted when a new owner proposal was canceled
	 */
	event CancelOwnershipTransfer(address indexed owner, address indexed canceledProposedNewOwner);

	/**
	 * @param  owner  Address to be the owner of the Oracle Diamond
	 * @param  cerchiaDRT  Address of the CerchiaDRT Diamond
	 */
	function initAccessControlFacet(address owner, address cerchiaDRT) external;

	/**
	 * @notice  For owner, to propose a new owner
	 */
	function requestOwnershipTransfer(address newOwner) external;

	/**
	 * @notice  For proposed new owner, to accept ownership
	 */
	function confirmOwnershipTransfer() external;

	/**
	 * @notice  For owner, to cancel the new owner proposal
	 */
	function cancelOwnershipTransfer() external;

	/**
	 * @notice Returns address of owner
	 */
	function getOwner() external view returns (address);

	/**
	 * @notice Returns address of proposed new owner
	 */
	function getProposedNewOwner() external view returns (address);

	/**
	 * @notice Returns address of CerchiaDRT
	 */
	function getCerchiaDRTAddress() external view returns (address);
}
