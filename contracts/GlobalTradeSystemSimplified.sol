pragma solidity 0.5.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract GlobalTradeSystem is ERC721Full {

     // ------------------------------------------------------------------------------------------ //
    // STRUCTS / ENUMS
    // ------------------------------------------------------------------------------------------ //


    enum TradeOfferState {
        PENDING,
        COMPLETED,
        CANCELLED
    }

    struct Asset {
        address emitter;
        uint tokenId;
    }

    struct TradeOffer {
        address sender;

        uint[] offeredURIs;
        uint[] wantedURIs;

        TradeOfferState state;
    }

    // ------------------------------------------------------------------------------------------ //
    // EVENTS
    // ------------------------------------------------------------------------------------------ //


    event AssetAssign (
        uint tokenId,
        address to,
        address by,
        string uri
    );

    event AssetBurn (
        uint tokenId
    );

    event TradeOfferRegistration (
        address indexed sender,
        uint[] indexed offerTokensIds,
        uint[] indexed wantedTokensIds,
        uint offerId
    );

    event TradeOfferModify (
        uint indexed id,      // id of modified offer 
        TradeOfferState state // new state of the offer
    );

    // ------------------------------------------------------------------------------------------ //
    // FIELDS
    // ------------------------------------------------------------------------------------------ //    

    mapping(uint => Asset) public assets;      // stores all Assets
    mapping(uint => TradeOffer) public offers; // stores all TradeOffers
    mapping(string => uint[]) tokenIds;        // stores tokens ids by theirs uris
    uint lastAssetId;                 // stores last Asset id
    uint lastOfferId;                 // stores last TradeOffer id

    // ------------------------------------------------------------------------------------------ //
    // MODIFIERS
    // ------------------------------------------------------------------------------------------ //


    modifier isOwnerOf(uint[] memory _tokenIds) {
        for(uint i = 0; i < _tokenIds.length; i++) {
            require(ERC721.ownerOf(_tokenIds[i]) == msg.sender, "In order to operate on some tokens you need to be theirs owner");
        }
        _;
    }

    // ------------------------------------------------------------------------------------------ //
    // EXTERNAL STATE-CHANGING FUNCTIONS
    // ------------------------------------------------------------------------------------------ //

    constructor() public ERC721Full("GlobalTradeSystem Token", "GTS") {}

    function assign(address _owner, string calldata _uri) external returns(uint) {
        ERC721._mint(_owner, lastAssetId);
        ERC721Metadata._setTokenURI(lastAssetId, _uri);
        tokenIds[_uri].push(lastAssetId);
        lastAssetId++;
        return lastAssetId - 1;
    }

    function burn(uint _assetId) external {
        require(
            assets[_assetId].emitter == msg.sender,
            "In order to burn an asset, you need to be the one who emitted it."
        );
        delete assets[_assetId];
        emit AssetBurn(_assetId);
    }

    function matchOffers(uint _bidOfferId, uint _askOfferId) external {
        require(_bidOfferId <= lastOfferId, "The given offer does not exist");
        require(_askOfferId <= lastOfferId, "The given offer does not exist");
        require(areOffersMatching(_bidOfferId, _askOfferId), "To match some offers they need to be matching");

        uint[] memory _bidOfferedItems =  offers[_bidOfferId].offeredURIs;
        uint[] memory _askOfferedItems =  offers[_askOfferId].offeredURIs;

        address _bidOfferCreator = offers[_bidOfferId].sender;
        address _askOfferCreator = offers[_askOfferId].sender;

        for(uint i = 0; i < _bidOfferedItems.length; i++) {
            ERC721._transferFrom(_bidOfferCreator, _askOfferCreator, _bidOfferedItems[i]);
        }

        for(uint i = 0; i < _askOfferedItems.length; i++) {
            ERC721._transferFrom(_askOfferCreator, _bidOfferCreator, _askOfferedItems[i]);
        }

        delete offers[_bidOfferId];
        delete offers[_askOfferId];
    }

    function postTradeOffer(uint[] calldata _offeredTokens, uint[] calldata _wantedTokens) external
    isOwnerOf(_offeredTokens)
    {
        TradeOffer memory _tradeOffer;
        _tradeOffer.sender = msg.sender;
        _tradeOffer.offeredURIs = _offeredTokens;
        _tradeOffer.wantedURIs = _wantedTokens;
        _tradeOffer.state = TradeOfferState.PENDING;

        offers[lastOfferId] = _tradeOffer;
        emit TradeOfferRegistration(
            msg.sender,
            _offeredTokens,
            _wantedTokens,
            lastOfferId
        );
        lastOfferId++;
    }

    // ------------------------------------------------------------------------------------------ //
    // EXTERNAL VIEW FUNCTIONS
    // ------------------------------------------------------------------------------------------ //

    function getTokensByURI(string memory _uri) public view returns(uint[] memory) {
        return tokenIds[_uri];
    }
 
    function areOffersMatching(uint _bidOfferId, uint _askOfferId) public view returns(bool) {
        uint[] memory _bidOfferedItems =  offers[_bidOfferId].offeredURIs;
        uint[] memory _bidWantedItems =  offers[_bidOfferId].wantedURIs;

        uint[] memory _askOfferedItems =  offers[_askOfferId].offeredURIs;
        uint[] memory _askWantedItems =  offers[_askOfferId].wantedURIs;

        bool areMatching = 
        (
            keccak256(abi.encodePacked(_bidOfferedItems)) == keccak256(abi.encodePacked(_askWantedItems))
            &&
            keccak256(abi.encodePacked(_askOfferedItems)) == keccak256(abi.encodePacked(_bidWantedItems))
        );
        return areMatching;
    }

}