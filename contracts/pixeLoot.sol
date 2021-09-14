// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./base64.sol";

contract pixeLoot is ERC721, ERC721Enumerable, ERC721URIStorage {
    using SafeMath for uint256;
    using Math for uint256;
    using Strings for uint256;

    uint16 public constant maxSupply = 512;

    constructor() ERC721("pixeLoot", "pxL") {}

    // Search for an unclaimed pxL with loot()...
    function loot(uint256 tokenId) public {
        require(
            tokenId <= (maxSupply - 1) && tokenId >= 0,
            "tokenId is invalid!"
        );
        require(!(_exists(tokenId)), "Already looted!");

        _safeMint(msg.sender, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "pxL does not exist.");
        return formatTokenURI(tokenId, maxSupply);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Helpers
    function generateColor(uint256 tokenId, uint16 maxNum)
        internal
        pure
        returns (uint256)
    {
        // 16777215 colors in the hex code color space.
        uint256 maxColor = 16777215 * 1000000000;
        uint256 color = (maxColor.ceilDiv((maxNum - 1)).mul(tokenId)).div(
            1000000000
        );

        return color;
    }

    function generateImageURI(uint256 color)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory colorString = bytes(generateColorString(color));

        bytes memory imagePrefix = "data:image/svg+xml;base64,";
        //
        bytes memory image = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="512" height="512" viewPort="0 0 0 0"> <rect width="10" height="10" x="calc(50% - 5px)" y="calc(50% - 5px)" style="fill: #',
            colorString,
            '"/></svg>'
        );

        return abi.encodePacked(imagePrefix, Base64.encode(string(image)));
    }

    function generateColorBytes(uint256 color)
        internal
        pure
        returns (bytes3 colorBytes)
    {
        return bytes3(abi.encodePacked(uint32(color) << 8));
    }

    function generateColorString(uint256 color)
        internal
        pure
        returns (string memory)
    {
        // Return representation of the color hex code as a string.
        // Grabbing first two chars of a hex string generated per byte because of edge cases with colors beginning with 0x00 (ie #008040 being returned as #804000).
        bytes3 colorBytes = generateColorBytes(color);
        bytes memory buffer;
        bytes memory byteBuffer;

        for (uint256 i = 0; i < 3; i++) {
            byteBuffer = bytes(
                abi.encodePacked(
                    uint256(bytes32(abi.encodePacked(colorBytes[i])))
                        .toHexString()
                )
            );
            buffer = abi.encodePacked(buffer, byteBuffer[2], byteBuffer[3]);
        }

        return string(buffer);
    }

    function formatTokenURI(uint256 tokenId, uint16 _maxSupply)
        internal
        pure
        returns (string memory)
    {
        uint256 color = generateColor(tokenId, _maxSupply);
        string memory imageURI = string(generateImageURI(color));

        string memory colorString = generateColorString(color);

        // Use a white background for most pxLs, except white.
        string memory backgroundColorString = "ffffff";
        if (
            keccak256(abi.encodePacked(colorString)) ==
            keccak256(abi.encodePacked("ffffff"))
        ) {
            backgroundColorString = "000000";
        }

        string memory fullURI = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    string(
                        abi.encodePacked(
                            '{"name": "pxL #',
                            (tokenId + 1).toString(),
                            '", "description": "A looted pxL!", "attributes": [{"trait_type": "color", "value": "#',
                            colorString,
                            '"}], "background_color": "',
                            backgroundColorString,
                            '", "image_data": "',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );

        return fullURI;
    }
}
