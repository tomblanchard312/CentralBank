// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import "../src/Permissioning.sol";
import "../src/DigitalToken.sol";

contract TokenHandler is Test {
    DigitalToken public token;
    address public authority;
    address[3] public actors;

    constructor(DigitalToken _token, address _authority, address[3] memory _actors) {
        token = _token;
        authority = _authority;
        actors = _actors;
    }

    function mint(uint256 actorSeed, uint256 amount, bytes32 key) external {
        address actor = actors[actorSeed % actors.length];
        amount = bound(amount, 1, 1_000_000);
        bytes32 scopedKey = keccak256(abi.encode("mint", key, actor, amount));
        vm.prank(authority);
        try token.mint(actor, amount, scopedKey) { } catch { }
    }

    function burn(uint256 actorSeed, uint256 amount, bytes32 key) external {
        address actor = actors[actorSeed % actors.length];
        uint256 balance = token.balanceOf(actor);
        if (balance == 0) return;
        amount = bound(amount, 1, balance);
        bytes32 scopedKey = keccak256(abi.encode("burn", key, actor, amount));
        vm.prank(authority);
        try token.burn(actor, amount, scopedKey) { } catch { }
    }

    function escrow(uint256 actorSeed, uint256 amount) external {
        address actor = actors[actorSeed % actors.length];
        uint256 balance = token.balanceOf(actor);
        if (balance == 0 || token.escrowTotals(actor) != 0) return;
        amount = bound(amount, 1, balance);
        vm.prank(authority);
        try token.escrowFunds(actor, amount, "case-ref", 0) { } catch { }
    }

    function release(uint256 actorSeed, uint256 recipientSeed) external {
        address actor = actors[actorSeed % actors.length];
        address recipient = actors[recipientSeed % actors.length];
        if (token.escrowTotals(actor) == 0) return;
        vm.prank(authority);
        try token.releaseEscrowedFunds(actor, recipient) { } catch { }
    }

    function burnEscrow(uint256 actorSeed) external {
        address actor = actors[actorSeed % actors.length];
        if (token.escrowTotals(actor) == 0) return;
        vm.prank(authority);
        try token.burnEscrowedFunds(actor) { } catch { }
    }
}

contract DigitalTokenInvariantTest is StdInvariant, Test {
    Permissioning internal permissioning;
    DigitalToken internal token;
    TokenHandler internal handler;
    address internal admin = makeAddr("admin");
    address internal authority = makeAddr("authority");
    address[3] internal actors;

    function setUp() public {
        actors = [makeAddr("alice"), makeAddr("bob"), makeAddr("merchant")];
        permissioning = new Permissioning(admin);
        vm.startPrank(admin);
        permissioning.grantRole(permissioning.ECB_ROLE(), authority);
        permissioning.grantRole(permissioning.MINTER_ROLE(), authority);
        permissioning.grantRole(permissioning.BURNER_ROLE(), authority);
        vm.stopPrank();
        token = new DigitalToken(address(permissioning));
        handler = new TokenHandler(token, authority, actors);
        targetContract(address(handler));
    }

    function invariant_TotalSupplyEqualsTrackedBalancesAndEscrows() public view {
        uint256 accounted;
        for (uint256 i = 0; i < actors.length; i++) {
            accounted += token.balanceOf(actors[i]);
            accounted += token.escrowTotals(actors[i]);
        }
        assertEq(token.totalSupply(), accounted);
    }

    function invariant_EscrowRecordMatchesEscrowTotal() public view {
        for (uint256 i = 0; i < actors.length; i++) {
            (uint256 amount,,) = token.escrowedBalances(actors[i]);
            assertEq(amount, token.escrowTotals(actors[i]));
        }
    }
}
