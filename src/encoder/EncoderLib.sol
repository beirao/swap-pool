// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ops } from "../Ops.sol";

/// @title EncoderLib
/// @notice Library for encoding operations
/// @author KONFeature <https://github.com/KONFeature>
/// @author Modified from (hhttps://github.com/Philogy/singleton-swapper/blob/main/src/utils/EncoderLib.sol) by Philogy
library EncoderLib {
    /* -------------------------------------------------------------------------- */
    /*                 Init and finishup of the encoded operations                */
    /* -------------------------------------------------------------------------- */

    /// @notice Init a new program with the given size
    /// @dev This function is used to initialize a new program
    /// @dev The done function should absoletely be called to set the free mem pointer after the program creation
    /// @param hashMapSize The size of the hashmap to use for our program
    function init(uint256 hashMapSize) internal pure returns (bytes memory program) {
        require(hashMapSize <= 0xffff);
        assembly ("memory-safe") {
            program := mload(0x40)
            mstore(0x40, add(program, 0x22))
            mstore(add(program, 2), hashMapSize)
            mstore(program, 2)
        }
    }

    /// @notice This function is used to return a value from a function
    /// @dev It will set the free memory pointer to the end of the value
    /// @dev Not optimized for gas efficiency, only for security purposes
    /// @param self The value to return
    /// @return The value to return
    function done(bytes memory self) internal pure returns (bytes memory) {
        assembly ("memory-safe") {
            let freeMem := mload(0x40)
            mstore(0x40, add(freeMem, mload(self)))
        }
        return self;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Swap related Ops                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Appends a swap operations in the pool with 'token' for 'amount' and 'zeroForOne' direction
     * @param self The encoded operations
     * @param zeroForOne The direction of the swap
     * @param amount The amount to swap
     * @return The updated encoded operations
     */
    function appendSwap(bytes memory self, bool zeroForOne, uint256 amount) internal pure returns (bytes memory) {
        uint256 op = Ops.SWAP | (zeroForOne ? Ops.SWAP_DIR : 0);
        assembly ("memory-safe") {
            let length := mload(self)
            mstore(self, add(length, 17))
            let initialOffset := add(add(self, 0x20), length)

            mstore(initialOffset, shl(248, op))
            mstore(add(initialOffset, 1), shl(128, amount))
        }

        return self;
    }

    /* -------------------------------------------------------------------------- */
    /*                            Liquidity related Ops                           */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Appends the add liquidity operation to the encoded operations
     * @param self The encoded operations
     * @param to The recipient of the liquidity tokens
     * @param maxAmount0 The maximum amount of baseToken to add
     * @param maxAmount1 The maximum amount of targetToken to add
     * @return The updated encoded operations
     */
    function appendAddLiquidity(
        bytes memory self,
        address to,
        uint256 maxAmount0,
        uint256 maxAmount1
    )
        internal
        pure
        returns (bytes memory)
    {
        // 73 = 1 byte for the op code + 2 addresses + 2 uint256s
        uint256 op = Ops.ADD_LIQ;
        assembly ("memory-safe") {
            // Increase the length of the bytes array by 73 bytes
            let length := mload(self)
            mstore(self, add(length, 53))
            // Get the address of the start of the new bytes
            let initialOffset := add(add(self, 0x20), length)

            // Write the add liquidity operation to the new bytes
            mstore(initialOffset, shl(248, op))
            mstore(add(initialOffset, 1), shl(96, to))
            mstore(add(initialOffset, 21), shl(128, maxAmount0))
            mstore(add(initialOffset, 37), shl(128, maxAmount1))
        }

        return self;
    }

    /**
     * @notice Appends the remove liquidity operation to the encoded operations
     * @param self The encoded operations
     * @param liquidity The amount of liquidity to remove
     * @return The updated encoded operations
     */
    function appendRemoveLiquidity(bytes memory self, uint256 liquidity) internal pure returns (bytes memory) {
        uint256 op = Ops.RM_LIQ;

        assembly ("memory-safe") {
            let length := mload(self)
            mstore(self, add(length, 33))
            let initialOffset := add(add(self, 0x20), length)

            mstore(initialOffset, shl(248, op))
            mstore(add(initialOffset, 1), liquidity)
        }

        return self;
    }

    /**
     * @notice Appends the claim all fees operation to the encoded operations
     * @param self The encoded operations
     * @return The updated encoded operations
     */
    function appendClaimFees(bytes memory self) internal pure returns (bytes memory) {
        uint256 op = Ops.CLAIM_ALL_FEES;
        assembly ("memory-safe") {
            let length := mload(self)
            mstore(self, add(length, 1))
            let initialOffset := add(add(self, 0x20), length)

            mstore(initialOffset, shl(248, op))
        }

        return self;
    }

    /* -------------------------------------------------------------------------- */
    /*                 Send token related Ops (from pool to user)                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Appends the send operation to the encoded operations
     * @dev Will ask the user to send his `token` to the pool defined by the token
     * @param self The encoded operations
     * @param isToken0 Is the token 0 the target of the send operation
     * @param to The recipient of the tokens
     * @param amount The amount of tokens to send
     * @return The updated encoded operations
     */
    function appendSend(
        bytes memory self,
        bool isToken0,
        address to,
        uint256 amount
    )
        internal
        pure
        returns (bytes memory)
    {
        uint256 op = Ops.SEND;
        assembly ("memory-safe") {
            let length := mload(self)
            mstore(self, add(length, 38))
            let initialOffset := add(add(self, 0x20), length)

            mstore(initialOffset, shl(248, op))
            mstore(add(initialOffset, 1), shl(248, isToken0))
            mstore(add(initialOffset, 2), shl(96, to))
            mstore(add(initialOffset, 22), shl(128, amount))
        }

        return self;
    }

    /**
     * @notice Appends the send all operation to the encoded operations
     * @param self The encoded operations
     * @param isToken0 Is the token 0 the target of the send operation
     * @param to The recipient of the tokens
     * @return The updated encoded operations
     */
    function appendSendAll(bytes memory self, bool isToken0, address to) internal pure returns (bytes memory) {
        uint256 op = Ops.SEND_ALL;
        assembly ("memory-safe") {
            let length := mload(self)
            mstore(self, add(length, 22))
            let initialOffset := add(add(self, 0x20), length)

            mstore(initialOffset, shl(248, op))
            mstore(add(initialOffset, 1), shl(248, isToken0))
            mstore(add(initialOffset, 2), shl(96, to))
        }

        return self;
    }

    /**
     * @notice Appends the send all operation to the encoded operations
     * @param self The encoded operations
     * @param isToken0 Is the token 0 the target of the send operation
     * @param to The recipient of the tokens
     * @param minAmount The min amount of token to send
     * @param maxAmount The max amount of token to send
     * @return The updated encoded operations
     */
    function appendSendAllWithLimit(
        bytes memory self,
        bool isToken0,
        address to,
        uint256 minAmount,
        uint256 maxAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        uint256 op = Ops.SEND_ALL + Ops.ALL_MIN_BOUND + Ops.ALL_MAX_BOUND;
        assembly ("memory-safe") {
            let length := mload(self)
            mstore(self, add(length, 54))
            let initialOffset := add(add(self, 0x20), length)

            mstore(initialOffset, shl(248, op))
            mstore(add(initialOffset, 1), shl(248, isToken0)) // bool -> bytes1
            mstore(add(initialOffset, 2), shl(128, minAmount)) // uint128 -> bytes16
            mstore(add(initialOffset, 18), shl(128, maxAmount)) // uint128 -> bytes16
            mstore(add(initialOffset, 34), shl(96, to)) // address -> bytes20
        }

        return self;
    }

    /* -------------------------------------------------------------------------- */
    /*                   Receive related Ops (from user to pool)                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Appends the receive operation to the encoded operations
     * @param self The encoded operations
     * @param isToken0 Is the token 0 the target of the send operation
     * @param amount The amount of tokens to receive
     * @return The updated encoded operations
     */
    function appendReceive(bytes memory self, bool isToken0, uint256 amount) internal pure returns (bytes memory) {
        uint256 op = Ops.RECEIVE;
        assembly ("memory-safe") {
            let length := mload(self)
            mstore(self, add(length, 18))
            let initialOffset := add(add(self, 0x20), length)

            mstore(initialOffset, shl(248, op))
            mstore(add(initialOffset, 1), shl(248, isToken0))
            mstore(add(initialOffset, 2), shl(128, amount))
        }

        return self;
    }

    /**
     * @notice Appends the receive all operation to the encoded operations
     * @param self The encoded operations
     * @param isToken0 Is the token 0 the target of the send operation
     * @return The updated encoded operations
     */
    function appendReceiveAll(bytes memory self, bool isToken0) internal pure returns (bytes memory) {
        uint256 op = Ops.RECEIVE_ALL;
        assembly ("memory-safe") {
            let length := mload(self)
            mstore(self, add(length, 2))
            let initialOffset := add(add(self, 0x20), length)

            mstore(initialOffset, shl(248, op))
            mstore(add(initialOffset, 1), shl(248, isToken0))
        }

        return self;
    }

    /**
     * @notice Appends a allowance via a EIP-2612 permit signature to the encoded operations
     * @param self The encoded operations
     * @param isToken0 Is the token 0 the target of the send operation
     * @param amount The amount that need to be allowed (uint128)
     * @param deadline The deadline for the permit signature (uint48 behind the scene, max possible value for a
     * realistic seconds timestamp)
     * @param v The v value of the permit signature (uint8)
     * @param r The r value of the permit signature (bytes32)
     * @param s The s value of the permit signature (bytes32)
     * @return The updated encoded operations
     */
    function appendPermitViaSig(
        bytes memory self,
        bool isToken0,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
        pure
        returns (bytes memory)
    {
        uint256 op = Ops.PERMIT_WITHDRAW_VIA_SIG;
        assembly ("memory-safe") {
            let length := mload(self)
            mstore(self, add(length, 89))
            let initialOffset := add(add(self, 0x20), length)

            mstore(initialOffset, shl(248, op))
            mstore(add(initialOffset, 1), shl(248, isToken0)) // bool -> bytes1
            mstore(add(initialOffset, 2), shl(128, amount)) // uint128 -> bytes16
            mstore(add(initialOffset, 18), shl(208, deadline)) // uint48 -> bytes6
            mstore(add(initialOffset, 24), shl(248, v)) // uint8 -> bytes1
            mstore(add(initialOffset, 25), r) // bytes32
            mstore(add(initialOffset, 57), s) // bytes32
        }

        return self;
    }
}