// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {TokenBridgeRouter} from "../src/TokenBridgeRouter/TokenBridgeRouter.sol";
import {WarpMessengerTestMock} from "../src/mocks/WarpMessengerTestMock.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {ERC20TokenHome} from "../src/TokenHome/ERC20TokenHome.sol";
import {ERC20Mock} from "@openzeppelin/contracts@4.8.1/mocks/ERC20Mock.sol";
import "@openzeppelin/contracts@4.8.1/utils/math/SafeMath.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

contract TokenBridgeRouterErc20Test is Test {
    address private constant TOKEN_HOME =
        0x6D411e0A54382eD43F02410Ce1c7a7c122afA6E1;

    event BridgeERC20(
        address indexed tokenAddress,
        bytes32 indexed remoteBlockchainID,
        uint256 amount,
        address recipient
    );

    HelperConfig helperConfig = new HelperConfig(TOKEN_HOME);
    TokenBridgeRouter tokenBridgeRouter;
    uint256 deployerKey;
    uint256 primaryRelayerFeeBips;
    uint256 secondaryRelayerFeeBips;
    ERC20Mock erc20Token;
    ERC20TokenHome tokenHome;
    address tokenRemote;
    bytes32 homeChainID;
    bytes32 remoteChainID;
    address owner;
    address bridger;
    bytes32 messageId;
    address warpPrecompileAddress;
    uint256 requiredGasLimit = 10_000_000;
    WarpMessengerTestMock warpMessengerTestMock;

    uint256 constant STARTING_GAS_BALANCE = 10 ether;

    function setUp() external {
        (
            deployerKey,
            primaryRelayerFeeBips,
            secondaryRelayerFeeBips,
            erc20Token,
            ,
            tokenHome,
            ,
            tokenRemote,
            tokenBridgeRouter,
            homeChainID,
            remoteChainID,
            owner,
            bridger,
            messageId,
            warpPrecompileAddress,
            warpMessengerTestMock
        ) = helperConfig.activeNetworkConfigTest();
        vm.deal(bridger, STARTING_GAS_BALANCE);

        vm.etch(warpPrecompileAddress, address(warpMessengerTestMock).code);
    }

    modifier registerTokenBridge() {
        vm.startPrank(owner);
        tokenBridgeRouter.registerHomeTokenBridge(
            address(erc20Token),
            address(tokenHome)
        );
        tokenBridgeRouter.registerRemoteTokenBridge(
            address(erc20Token),
            remoteChainID,
            tokenRemote,
            requiredGasLimit,
            false
        );
        vm.stopPrank();
        _;
    }

    modifier fundBridgerAccount() {
        vm.startPrank(bridger);
        erc20Token.mint(bridger, 10 ether);
        vm.stopPrank();
        _;
    }

    function testBalanceBridgerWhenSendERC20Tokens()
        public
        registerTokenBridge
        fundBridgerAccount
    {
        vm.startPrank(bridger);
        uint256 balanceStart = erc20Token.balanceOf(bridger);

        uint256 amount = 1 ether;
        erc20Token.approve(address(tokenBridgeRouter), amount);
        tokenBridgeRouter.bridgeERC20(
            address(erc20Token),
            remoteChainID,
            amount,
            bridger,
            address(0)
        );

        uint256 balanceEnd = erc20Token.balanceOf(bridger);
        assert(balanceStart == balanceEnd + amount);
        vm.stopPrank();
    }

    function testBalanceBridgeWhenSendERC20Tokens()
        public
        registerTokenBridge
        fundBridgerAccount
    {
        vm.startPrank(bridger);
        uint256 balanceStart = erc20Token.balanceOf(address(tokenHome));
        assert(balanceStart == 0);

        uint256 amount = 1 ether;
        erc20Token.approve(address(tokenBridgeRouter), amount);
        tokenBridgeRouter.bridgeERC20(
            address(erc20Token),
            remoteChainID,
            amount,
            bridger,
            address(0)
        );

        uint256 feeAmount = SafeMath.div(
            SafeMath.mul(amount, primaryRelayerFeeBips),
            10_000
        );
        uint256 balanceEnd = erc20Token.balanceOf(address(tokenHome));
        assert(balanceEnd == amount - feeAmount);
        vm.stopPrank();
    }

    function testEmitsOnCallOfBridgeERC20Function()
        public
        registerTokenBridge
        fundBridgerAccount
    {
        vm.startPrank(bridger);
        uint256 amount = 1 ether;
        erc20Token.approve(address(tokenBridgeRouter), amount);

        vm.expectEmit(true, true, false, false, address(tokenBridgeRouter));
        emit BridgeERC20(address(erc20Token), remoteChainID, amount, bridger);
        tokenBridgeRouter.bridgeERC20(
            address(erc20Token),
            remoteChainID,
            amount,
            bridger,
            address(0)
        );

        vm.stopPrank();
    }
}
