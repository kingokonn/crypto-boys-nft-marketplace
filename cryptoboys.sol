// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

// import ERC721 iterface
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// CryptoBoys smart contract inherits ERC721 interface
contract CryptoBoys is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
	// total number of crypto boys minted
	uint256 public cryptoBoyCounter;

	// crypto boy struct
	struct CryptoBoy {
		uint256 tokenId;
		string tokenName;
		string tokenURI;
		address payable mintedBy;
		address payable currentOwner;
		address previousOwner;
		uint256 price;
		uint256 numberOfTransfers;
		bool forSale;
	}

	// maps cryptoboy's token id to Struct CryptoBoy
	mapping(uint256 => CryptoBoy) public allCryptoBoys;
	// records all token's names that exist
	mapping(string => bool) public tokenNameExists;
	// records all colors that exist
	mapping(string => bool) public colorExists;
	// records all token URIs that exist
	mapping(string => bool) public tokenURIExists;

	constructor() ERC721("Crypto Boys Collection", "CB") {}

    // mints a new crypto boy
    function mintCryptoBoy(string memory _name, string memory _tokenURI, uint256 _price, string[] calldata _colors) external isValidCaller {
		require(bytes(_name).length > 0, "Enter a valid name");
        require(bytes(_tokenURI).length > 7, "Enter a valid uri"); // URIs using ipfs starts with "ipfs://"
        require(_price > 0, "Enter a valid price");
        require(_colors.length > 0, "please do not enter an empty colors array");
        uint id = cryptoBoyCounter;
		cryptoBoyCounter ++;
		// check if a token exists with id already exists
		require(!_exists(id), "NFT already exists");

		// loops through the colors passed and check if each color already exists or not
		for(uint i=0; i<_colors.length; i++) {
            require(bytes(_colors[i]).length > 0, "Empty string in colors array");
		    require(!colorExists[_colors[i]], "One of your colors already exists");
        
		}
		// check if the token URI already exists or not
		require(!tokenURIExists[_tokenURI], "NFT with this tokenURI already exists");
		// check if the token name already exists or not
		require(!tokenNameExists[_name], "NFT with this name already exists");

		// mint the token
		_mint(msg.sender, id);
		// set token URI (bind token id with the passed in token URI)
		_setTokenURI(id, _tokenURI);

		// loop through the colors passed and make each of the colors as exists since the token is already minted
		for (uint i=0; i<_colors.length; i++) {
		colorExists[_colors[i]] = true;
		}
		// make passed token URI as exists
		tokenURIExists[_tokenURI] = true;
		// make token name passed as exists
		tokenNameExists[_name] = true;

		// creat a new crypto boy (struct) and pass in new values
		CryptoBoy memory newCryptoBoy = CryptoBoy(
		id,
		_name,
		_tokenURI,
		payable(msg.sender),
		payable(msg.sender),
		address(0),
		_price,
		0,
		true);
		// add the token id and it's crypto boy to all crypto boys mapping
		allCryptoBoys[id] = newCryptoBoy;
	}

	function buyToken(uint256 _tokenId) public payable isValidCaller verifyExists(_tokenId) {
		require(msg.sender != ownerOf(_tokenId), "You can't buy your own NFT");
		CryptoBoy memory cryptoboy = allCryptoBoys[_tokenId];
		require(msg.value == cryptoboy.price, "You need to match the price of the NFT");
		// token should be for sale
		require(cryptoboy.forSale, "NFT isn't for sale");
		// transfer the token from owner to the caller of the function (buyer)
		_transfer(ownerOf(_tokenId), msg.sender, _tokenId);
		address payable sendTo = cryptoboy.currentOwner;
		cryptoboy.previousOwner = cryptoboy.currentOwner;
		cryptoboy.currentOwner = payable(msg.sender);
		// update the number of times token has been traded
		cryptoboy.numberOfTransfers += 1;
		allCryptoBoys[_tokenId] = cryptoboy;
		(bool success,) = sendTo.call{value: msg.value}("");
		require(success, "Transfer of payment for NFT failed");
	}

	function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) public isValidCaller verifyExists(_tokenId) checkNftOwner(_tokenId) {
		require(_newPrice > 0, "Enter a valid price");
		CryptoBoy memory cryptoboy = allCryptoBoys[_tokenId];
		// update token's price with new price
		cryptoboy.price = _newPrice;
		// set and update that token in the mapping
		allCryptoBoys[_tokenId] = cryptoboy;
	}

	// switch between set for sale and set not for sale
	function toggleForSale(uint256 _tokenId) public verifyExists(_tokenId) checkNftOwner(_tokenId) {
		CryptoBoy memory cryptoboy = allCryptoBoys[_tokenId];
		// if token's forSale is false make it true and vice versa
		if(cryptoboy.forSale) {
		cryptoboy.forSale = false;
		} else {
		cryptoboy.forSale = true;
		}
		// set and update the token in the mapping
		allCryptoBoys[_tokenId] = cryptoboy;
	}

    modifier isValidCaller {
        // require caller of the function is not an empty address
		require(msg.sender != address(0), "Enter a valid address");
		_;
    }

    modifier checkNftOwner(uint _tokenId) {
      	// check that token's owner should be equal to the caller of the function
		require(ownerOf(_tokenId) == msg.sender, "You are not the NFT owner");
		_;
    }

    modifier verifyExists(uint _tokenId){
        // require that token should exist
		require(_exists(_tokenId), "NFT doesn't exist");
		_;
    }	

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //    destroys an NFT
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    //    returns IPFS url of NFT metadata
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
