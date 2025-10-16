// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract DeployToken is Script {
    uint256 constant INITIAL_SUPPLY = 1000 ether;

    function run() external returns (MyToken) {
        vm.startBroadcast();
        MyToken mt = new MyToken(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return mt;
    }
}
