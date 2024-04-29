// This is a generated Motoko binding.
// Please use `import service "ic:canister_id"` instead to call canisters on the IC if possible.

module {

  public let CANISTER_ID = "shzfz-xiaaa-aaaah-abwza-cai";
  public type AccountIdentifier = Text;
  public type AccountIdentifier__1 = Text;
  public type Asset = { thumbnail : ?File; name : Text; payload : File };
  public type Balance = Nat;
  public type BalanceRequest = { token : TokenIdentifier; user : User };
  public type BalanceResponse = { #ok : Balance; #err : CommonError__1 };
  public type Balance__1 = Nat;
  public type CommonError = { #InvalidToken : TokenIdentifier; #Other : Text };
  public type CommonError__1 = {
    #InvalidToken : TokenIdentifier;
    #Other : Text;
  };
  public type Extension = Text;
  public type File = { data : [[Nat8]]; ctype : Text };
  public type HeaderField = (Text, Text);
  public type HttpRequest = {
    url : Text;
    method : Text;
    body : [Nat8];
    headers : [HeaderField];
  };
  public type HttpResponse = {
    body : [Nat8];
    headers : [HeaderField];
    streaming_strategy : ?HttpStreamingStrategy;
    status_code : Nat16;
  };
  public type HttpStreamingCallbackResponse = {
    token : ?HttpStreamingCallbackToken;
    body : [Nat8];
  };
  public type HttpStreamingCallbackToken = {
    key : Text;
    sha256 : ?[Nat8];
    index : Nat;
    content_encoding : Text;
  };
  public type HttpStreamingStrategy = {
    #Callback : {
      token : HttpStreamingCallbackToken;
      callback : shared query HttpStreamingCallbackToken -> async HttpStreamingCallbackResponse;
    };
  };
  public type ListRequest = {
    token : TokenIdentifier__1;
    from_subaccount : ?SubAccount__1;
    price : ?Nat64;
  };
  public type Listing = { locked : ?Time; seller : Principal; price : Nat64 };
  public type Memo = [Nat8];
  public type Metadata = {
    #fungible : {
      decimals : Nat8;
      metadata : ?[Nat8];
      name : Text;
      symbol : Text;
    };
    #nonfungible : { metadata : ?[Nat8] };
  };
  public type MintingRequest = { to : AccountIdentifier; asset : Nat32 };
  public type Result = {
    #ok : [(TokenIndex, ?Listing, ?[Nat8])];
    #err : CommonError;
  };
  public type Result_1 = { #ok : [TokenIndex]; #err : CommonError };
  public type Result_2 = { #ok : Balance__1; #err : CommonError };
  public type Result_3 = { #ok; #err : CommonError };
  public type Result_4 = { #ok : Metadata; #err : CommonError };
  public type Result_5 = { #ok : AccountIdentifier; #err : CommonError };
  public type Result_6 = {
    #ok : (AccountIdentifier, ?Listing);
    #err : CommonError;
  };
  public type Settlement = {
    subaccount : SubAccount__1;
    seller : Principal;
    buyer : AccountIdentifier;
    price : Nat64;
  };
  public type SubAccount = [Nat8];
  public type SubAccount__1 = [Nat8];
  public type Time = Int;
  public type TokenIdentifier = Text;
  public type TokenIdentifier__1 = Text;
  public type TokenIndex = Nat32;
  public type Transaction = {
    token : TokenIdentifier__1;
    time : Time;
    seller : Principal;
    buyer : AccountIdentifier;
    price : Nat64;
  };
  public type TransferRequest = {
    to : User;
    token : TokenIdentifier;
    notify : Bool;
    from : User;
    memo : Memo;
    subaccount : ?SubAccount;
    amount : Balance;
  };
  public type TransferResponse = {
    #ok : Balance;
    #err : {
      #CannotNotify : AccountIdentifier__1;
      #InsufficientBalance;
      #InvalidToken : TokenIdentifier;
      #Rejected;
      #Unauthorized : AccountIdentifier__1;
      #Other : Text;
    };
  };
  public type User = {
    #principal : Principal;
    #address : AccountIdentifier__1;
  };
  public type Self = actor {
    acceptCycles : shared () -> async ();
    addAsset : shared Asset -> async Nat;
    adminKillHeartbeat : shared () -> async ();
    adminStartHeartbeat : shared () -> async ();
    allPayments : shared query () -> async [(Principal, [SubAccount__1])];
    allSettlements : shared query () -> async [(TokenIndex, Settlement)];
    availableCycles : shared query () -> async Nat;
    balance : shared query BalanceRequest -> async BalanceResponse;
    bearer : shared query TokenIdentifier__1 -> async Result_5;
    clearPayments : shared (Principal, [SubAccount__1]) -> async ();
    cronCapEvents : shared () -> async ();
    cronDisbursements : shared () -> async ();
    cronSettlements : shared () -> async ();
    details : shared query TokenIdentifier__1 -> async Result_6;
    ext_InitAssets : shared Nat -> async ();
    ext_assetAdd : shared (Nat, Text, Text, [Nat8]) -> async Nat;
    ext_assetExists : shared query Text -> async Bool;
    ext_mintNFT : shared MintingRequest -> async Nat32;
    ext_mintNFTBatch : shared MintingRequest -> async ();
    ext_updateAssets : shared ([Nat], [Text], [Text], [[Nat8]]) -> async [Nat];
    ext_updateThumb : shared (Nat, Text, [Nat8]) -> async Nat;
    extensions : shared query () -> async [Extension];
    getAssetDetails : shared query Nat -> async Text;
    getMinter : shared query () -> async Principal;
    getRegistry : shared query () -> async [(TokenIndex, AccountIdentifier)];
    getTokens : shared query () -> async [(TokenIndex, Metadata)];
    historicExport : shared () -> async Bool;
    http_request : shared query HttpRequest -> async HttpResponse;
    http_request_streaming_callback : shared query HttpStreamingCallbackToken -> async HttpStreamingCallbackResponse;
    initCap : shared () -> async ();
    list : shared ListRequest -> async Result_3;
    list_bulk : shared [(TokenIndex, Nat64)] -> async [(TokenIndex, Nat64)];
    listings : shared query () -> async [(TokenIndex, Listing, Metadata)];
    lock : shared (
        TokenIdentifier__1,
        Nat64,
        AccountIdentifier,
        SubAccount__1,
      ) -> async Result_5;
    metadata : shared query TokenIdentifier__1 -> async Result_4;
    mintNFT : shared MintingRequest -> async TokenIndex;
    name : shared query () -> async Text;
    payments : shared query () -> async ?[SubAccount__1];
    setMinter : shared Principal -> async ();
    setSalesFee : shared [(AccountIdentifier, Nat64)] -> ();
    settle : shared TokenIdentifier__1 -> async Result_3;
    settlements : shared query () -> async [
        (TokenIndex, AccountIdentifier, Nat64)
      ];
    stats : shared query () -> async (
        Nat64,
        Nat64,
        Nat64,
        Nat64,
        Nat,
        Nat,
        Nat,
      );
    streamAsset : shared (Nat, Bool, [Nat8], Bool) -> async ();
    supply : shared query TokenIdentifier__1 -> async Result_2;
    symbol : shared query () -> async Text;
    tokens : shared query AccountIdentifier -> async Result_1;
    tokens_ext : shared query AccountIdentifier -> async Result;
    transactions : shared query () -> async [Transaction];
    transfer : shared TransferRequest -> async TransferResponse;
    transfer_bulk : shared [(TokenIndex, AccountIdentifier)] -> async [
        (TokenIndex, AccountIdentifier)
      ];
    updateThumb : shared (Text, File) -> async ?Nat;
    verifyAsset : shared query Text -> async Text;
  }
}