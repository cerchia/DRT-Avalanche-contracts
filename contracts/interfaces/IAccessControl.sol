// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Since we are using DiamondPattern, one can no longer directly inherit AccessControl from Openzeppelin.
// This happens because DiamondPattern implies a different storage structure,
// but AccessControl handles memory internally.
// Following is the OpenZeppelin work, slightly changed to fit our use-case and needs.
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/IAccessControl.sol

/**
 * @title  CerchiaDRT Diamond Access Control Interface
 * @notice Used to control what functions an address can call
 */
interface IAccessControl {
	/**
	 * @notice  Emitted when `account` is granted `role`.
	 * @dev     Emitted when `account` is granted `role`.
	 * @dev     `sender` is the account that originated the contract call, an admin role
	 *          bearer except when using {AccessControl-_setupRole}.
	 */
	event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

	/**
	 * @notice  Emitted when `sender` (owner) sets `feeAddress`.
	 * @dev     Emitted when `sender` (owner) sets `feeAddress`.
	 * @dev     `sender` is the account that originated the contract call, an admin role
	 *          bearer except when using {AccessControl-_setupRole}.
	 */
	event FeeAddressSet(address indexed feeAddress, address indexed sender);

	/**
	 * @notice  Emitted when `sender` (owner) sets `oracleAddress`.
	 * @dev     Emitted when `sender` (owner) sets `oracleAddress`.
	 * @dev     `sender` is the account that originated the contract call, an admin role
	 *          bearer except when using {AccessControl-_setupRole}.
	 */
	event OracleAddressSet(address indexed oracleAddress, address indexed sender);

	/**
	 * @param  owners  The 3 addresses to have the OWNER_ROLE role
	 * @param  operators  The 3 addresses to have the OPERATOR_ROLE role
	 * @param  feeAddress  Address to send fees to
	 * @param  oracleAddress  Address of the Oracle Diamond
	 */
	function initAccessControlFacet(
		address[3] memory owners,
		address[3] memory operators,
		address feeAddress,
		address oracleAddress
	) external;

	/**
	 * @notice  For owners, to deactivate all functions except user claimback
	 */
	function ownerDeactivateAllFunctions() external;

	/**
	 * @notice  For owners, to deactivate user functions except user claimback
	 */
	function ownerDeactivateUserFunctions() external;

	/**
	 * @notice  For owners, to deactivate operator functions
	 */
	function ownerDeactivateOperatorFunctions() external;

	/**
	 * @notice  For owners, to activate operator functions
	 */
	function ownerActivateOperatorFunctions() external;

	/**
	 * @notice  Returns fee address
	 */
	function getFeeAddress() external view returns (address);

	/**
	 * @notice  Returns oracle's address
	 */
	function getOracleAddress() external view returns (address);

	/**
	 * @notice Returns `true` if `account` has been granted `role`.
	 * @dev Returns `true` if `account` has been granted `role`.
	 */
	function hasRole(bytes32 role, address account) external view returns (bool);

	function isKYXProvider(address caller) external view returns (bool);

	function isUser(address caller) external view returns (bool);
}
