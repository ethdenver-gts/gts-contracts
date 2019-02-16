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

    enum TradeOfferType {
        ASSET_FOR_ASSET,
        ASSET_FOR_ERC20,
        ASSET_FOR_ETHER,
        ERC20_FOR_ASSET,
        ETHER_FOR_ASSET
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

    modifier enoughDepositedERC20Tokens(address _ERC20Address, address _who, uint _minimalAmount) {
        ERC20 erc20 = ERC20(_ERC20Address);
        uint _balance = erc20.balanceOf(_who);
        require(erc20.transferFrom(msg.sender, address(this), _minimalAmount), "To call this function your erc20 balance must be above the minimal amount");
        _;
    }

    modifier enoughtEther(uint _minimalAmount) {
        require(msg.value >= _minimalAmount);
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

    function postERC20ForAssetTradeOffer(address _ERC20Address, uint _quantity, uint[] memory _wantedTokens) public
    enoughDepositedERC20Tokens(_ERC20Address, msg.sender, _quantity)
    returns(uint)
    {
        TradeOffer memory _tradeOffer;
        _tradeOffer.sender = msg.sender;
        string memory _offeredAssetURI = string(abi.encode(_ERC20Address));
        _tradeOffer.offeredAssetURI = _offeredAssetURI;
        _tradeOffer.offeredAssetsQuantity = _quantity;
        _tradeOffer.wantedTokensIds = _wantedTokens;
        
        _tradeOffer.state = TradeOfferState.PENDING;
        _tradeOffer.offerType = TradeOfferType.ERC20_FOR_ASSET;
        offers[lastOfferId] = _tradeOffer;

        uint[] memory _offeredTokens;

        emit TradeOfferRegistration(
            lastOfferId,
            msg.sender,
            _offeredTokens,
            _offeredAssetURI,
            _tradeOffer.offeredAssetsQuantity,
            _wantedTokens,
            "",
            0,
            TradeOfferType.ERC20_FOR_ASSET
        );
        return lastOfferId++;
    }

    function postEtherForAssetTradeOffer(uint _weiAmount, uint[] memory _wantedTokens) public payable
    enoughtEther(_weiAmount)
    returns(uint)
    {
        TradeOffer memory _tradeOffer;
        _tradeOffer.sender = msg.sender;
        string memory _offeredAssetURI = string(abi.encode(address(0)));
        _tradeOffer.offeredAssetURI = _offeredAssetURI;
        _tradeOffer.offeredAssetsQuantity = _weiAmount;
        _tradeOffer.wantedTokensIds = _wantedTokens;
        
        _tradeOffer.state = TradeOfferState.PENDING;
        _tradeOffer.offerType = TradeOfferType.ETHER_FOR_ASSET;
        offers[lastOfferId] = _tradeOffer;

        uint[] memory _offeredTokens;

        emit TradeOfferRegistration(
            lastOfferId,
            msg.sender,
            _offeredTokens,
            _offeredAssetURI,
            _tradeOffer.offeredAssetsQuantity,
            _wantedTokens,
            "",
            0,
            TradeOfferType.ETHER_FOR_ASSET
        );
        return lastOfferId++;
    }

    // ------------------------------------------------------------------------------------------ //
    // EXTERNAL VIEW FUNCTIONS
    // ------------------------------------------------------------------------------------------ //

    function areOffersMatching(uint _bidOfferId, uint _askOfferId) public view returns(bool) {
        uint[] memory _offeredTokens = offers[_bidOfferId].offeredTokensIds;
        string memory _offeredAssetURI = offers[_bidOfferId].offeredAssetURI;
        uint _offeredAssetsQuantity = offers[_bidOfferId].offeredAssetsQuantity;

        uint[] memory _wantedTokens = offers[_askOfferId].wantedTokensIds;
        string memory _wantedAssetURI = offers[_askOfferId].wantedAssetURI;
        uint _wantedAssetsQuantity = offers[_askOfferId].wantedAssetsQuantity;

        bool _areOffersMatching = (
                    keccak256(abi.encodePacked(_offeredTokens)) == keccak256(abi.encodePacked(_wantedTokens))
                    &&
                    keccak256(abi.encodePacked(_offeredAssetURI)) == keccak256(abi.encodePacked(_wantedAssetURI))
                    &&
                    _offeredAssetsQuantity == _wantedAssetsQuantity
                );
        return _areOffersMatching;
    }


}