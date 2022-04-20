// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IAccount.sol";
import "../interfaces/IAccountFactory.sol";

contract MapleBase {
    address public admin;
    address public pendingAdmin;

    address public immutable accountFactory;

    event NewAdmin(address newAdmin, address oldAdmin);
    event NewPendingAdmin(address newPendingAdmin, address oldPendingAdmin);

    constructor(address _accountFacotry) {
        admin = msg.sender;
        emit NewAdmin(admin, address(0));
        accountFactory = _accountFacotry;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }


    function withdrawalNativeToken(uint256 _amount) external {
        address account = getAccount(msg.sender);
        require(_amount <= account.balance, "insufficient balance");
        IAccount(account).sendValue(payable(msg.sender), _amount);
    }

    function batchWithdrawalERC20Tokens(
        address[] calldata _erc20Tokens,
        uint256[] calldata _amounts
    )
        external
    {
        address account = getAccount(msg.sender);
        for (uint i = 0; i < _erc20Tokens.length; i++) {
            uint256 balance = IERC20(_erc20Tokens[i]).balanceOf(address(account));
            require(_amounts[i] <= balance, "insufficient balance");
            IAccount(account).functionCall(_erc20Tokens[i], abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                _amounts[i]
            ));
        }
    }

    function batchWithdrawalERC721Tokens(
        address _erc721Token,
        uint256[] calldata _tokenIds
    )
        external
    {
        address account = getAccount(msg.sender);
        for (uint i = 0; i < _tokenIds.length; i++) {
            address owner = IERC721(_erc721Token).ownerOf(_tokenIds[i]);
            require(owner == account, "not owner");
            IAccount(account).functionCall(_erc721Token, abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                account,
                msg.sender,
                _tokenIds[i]
            ));
        }
    }

    function setPendingAdmin(address _newPendingAdmin) external onlyAdmin {
        require(
            _newPendingAdmin != admin && _newPendingAdmin != address(0),
            "invalid address"
        );
        if (pendingAdmin != _newPendingAdmin) {
            address oldPendingAdmin = pendingAdmin;
            pendingAdmin = _newPendingAdmin;
            emit NewPendingAdmin(pendingAdmin, oldPendingAdmin);
        }
    }

    function acceptAdmin() external {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "not pending admin"
        );
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit NewAdmin(admin, oldAdmin);
        emit NewPendingAdmin(pendingAdmin, oldPendingAdmin);
    }

    function tryGetAccount(address user) public view returns (address) {
        return IAccountFactory(accountFactory).accounts(user);
    }

    function getAccount(address user) public view returns (address) {
        address account = tryGetAccount(user);
        require(account != address(0), "no account");
        return account;
    }

    function hasAccount(address user) public view returns (bool) {
        return tryGetAccount(user) != address(0);
    }
}
