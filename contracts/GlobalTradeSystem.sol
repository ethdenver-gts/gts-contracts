pragma solidity 0.5.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";

contract GlobalTradeSystem is ERC721Full {

    // ------------------------------------------------------------------------------------------ //
    // STRUCTS / ENUMS
    // ------------------------------------------------------------------------------------------ //

    enum TradeOfferState {
        PENDING,
        COMPLETED,
        CANCELLED
    }

    enum TradeOfferType {
        ASSET_FOR_ASSET,
        ASSET_FOR_ERC20,
        ASSET_FOR_ETHER
    }

    struct Asset {
        address emitter;
        uint tokenId;
    }

    struct TradeOffer {
        address sender;

        uint[] offeredTokensIds;

        string offeredAssetURI;
        uint offeredAssetsQuantity;


        uint[] wantedTokensIds;

        string wantedAssetURI;
        uint wantedAssetsQuantity;

        TradeOfferState state;

        TradeOfferType offerType;
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
        uint offerId,
        address indexed sender,

        uint[] indexed offerTokensIds,

        string offeredAssetURI,
        uint offeredAssetsQuantity,      


        uint[] indexed wantedTokensIds,

        string wantedAssetURI,
        uint wantedAssetsQuantity,

        TradeOfferType offerType
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
    uint lastAssetId;                 // stores last Asset id
    uint lastOfferId;                 // stores last TradeOffer id

    constructor() public ERC721Full("GlobalTradeSystem Token", "GTS") {}

    // ------------------------------------------------------------------------------------------ //
    // MODIFIERS
    // ------------------------------------------------------------------------------------------ //

    modifier offerUnitialized(uint _offerId) {
        require(offers[_offerId].state != TradeOfferState.PENDING, "Initialized offers can be only cancelled or completed");
        _;
    }

    modifier isOwnerOf(uint[] memory _tokenIds) {
        for(uint i = 0; i < _tokenIds.length; i++) {
            require(ERC721.ownerOf(_tokenIds[i]) == msg.sender, "In order to operate on some tokens you need to be theirs owner");
        }
        _;
    }

    // ------------------------------------------------------------------------------------------ //
    // EXTERNAL STATE-CHANGING FUNCTIONS
    // ------------------------------------------------------------------------------------------ //

    function assign(address _owner, string calldata _uri) external returns(uint) {
        ERC721._mint(_owner, lastAssetId);
        ERC721Metadata._setTokenURI(lastAssetId, _uri);
        lastAssetId++;
        return lastAssetId - 1;
    }

    function burn(uint _assetId) public {
        require(
            assets[_assetId].emitter == msg.sender,
            "In order to burn an asset, you need to be the one who emitted it."
        );
        delete assets[_assetId];
        emit AssetBurn(_assetId);
    }

    function postAssetForAssetTradeOffer(uint[] memory _offeredTokens, uint[] memory _wantedTokens) public 
    isOwnerOf(_offeredTokens)
    returns(uint)
    {
        TradeOffer memory _tradeOffer;
        _tradeOffer.sender = msg.sender;
        _tradeOffer.offeredTokensIds = _offeredTokens;
        _tradeOffer.wantedTokensIds = _wantedTokens;
        _tradeOffer.state = TradeOfferState.PENDING;
        _tradeOffer.offerType = TradeOfferType.ASSET_FOR_ASSET;
        offers[lastOfferId] = _tradeOffer;
        emit TradeOfferRegistration(
            lastOfferId,
            msg.sender,
            _offeredTokens,
            "",
            0,
            _wantedTokens,
            "",
            0,
            TradeOfferType.ASSET_FOR_ASSET
        );
        return lastOfferId++;

    }

    function postAssetForERC20TradeOffer(uint[] memory _offeredTokens, address ERC20Address, uint quantity) public
    isOwnerOf(_offeredTokens)
    returns(uint)
    {
        TradeOffer memory _tradeOffer;
        _tradeOffer.sender = msg.sender;
        _tradeOffer.offeredTokensIds = _offeredTokens;
        string memory _wantedAssetURI = string(abi.encode(ERC20Address));
        _tradeOffer.wantedAssetURI = _wantedAssetURI;
        _tradeOffer.wantedAssetsQuantity = quantity;
        _tradeOffer.state = TradeOfferState.PENDING;
        _tradeOffer.offerType = TradeOfferType.ASSET_FOR_ERC20;
        offers[lastOfferId] = _tradeOffer;

        uint[] memory _wantedTokens;

        emit TradeOfferRegistration(
            lastOfferId,
            msg.sender,
            _offeredTokens,
            "",
            0,
            _wantedTokens,
            _wantedAssetURI,
            quantity,
            TradeOfferType.ASSET_FOR_ERC20
        );
        return lastOfferId++;

    }

    function postAssetForEtherTradeOffer(uint[] memory _offeredTokens, uint _weiAmount) public
    isOwnerOf(_offeredTokens)
    returns(uint) {
        TradeOffer memory _tradeOffer;
        _tradeOffer.sender = msg.sender;
        _tradeOffer.offeredTokensIds = _offeredTokens;
        string memory _wantedAssetURI = string(abi.encode(address(0)));
        _tradeOffer.wantedAssetURI = _wantedAssetURI;
        _tradeOffer.wantedAssetsQuantity = _weiAmount;
        _tradeOffer.state = TradeOfferState.PENDING;
        _tradeOffer.offerType = TradeOfferType.ASSET_FOR_ERC20;
        offers[lastOfferId] = _tradeOffer;

        uint[] memory _wantedTokens;

        emit TradeOfferRegistration(
            lastOfferId,
            msg.sender,
            _offeredTokens,
            "",
            0,
            _wantedTokens,
            _wantedAssetURI,
            _weiAmount,
            TradeOfferType.ASSET_FOR_ETHER
        );
        return lastOfferId++;
    }




}