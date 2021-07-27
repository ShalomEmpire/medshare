// Library: StringsAndBytes
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title StringsAndBytes Converts Strings to Bytes and Bytes32 and Vice-versa
 * @dev Converting Bytes and Strings into one another
 */
library StringsAndBytes {
  
  function stringToBytes32(string memory _source) public pure returns (bytes32 result) {
    // String have to be max 32 chars
    // https://ethereum.stackexchange.com/questions/9603/understanding-mload-assembly-function
    // http://solidity.readthedocs.io/en/latest/assembly.html
    assembly {
      result := mload(add(_source, 0x20))
    }
  }

  function bytes32ToBytes(bytes32 _bytes32) public pure returns (bytes memory) {
    // bytes32 (fixed-size array) to bytes (dynamically-sized array)
    // string memory str = string(_bytes32);
    // TypeError: Explicit type conversion not allowed from "bytes32" to "string storage pointer"    
    bytes memory bytesArray = new bytes(32);
    for (uint256 i; i < 32; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return bytesArray;
  }

  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    // https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string
    // https://ethereum.stackexchange.com/questions/1081/how-to-concatenate-a-bytes32-array-to-a-string
    bytes memory bytesArray = bytes32ToBytes(_bytes32);
    return string(bytesArray);
  }
}

