import Prim "mo:prim";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Bool "mo:base/Bool";
import Nat64 "mo:base/Nat64";
import Int64 "mo:base/Int64";
import Text "mo:base/Text";
import Map "mo:base/HashMap";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Time "mo:base/Time";

import Hmac "motokoBitcoin/src/Hmac";
import Base58 "motokoBitcoin/src/Base58";

import UUID "mo:uuid/UUID";
import Source "mo:uuid/Source";
import AsyncSource "mo:uuid/async/SourceV4";
import XorShift "mo:rand/XorShift";

import AID "./motoko/util/AccountIdentifier";
import Hex "./motoko/util/Hex";
import ExtCore "./motoko/ext/Core";

import Utils "./Utils";
import Fliphouse "./Fliphouse";
import Ledger "./Ledger";
import NFTLedger "./NFTLedger";
import LedgerCandid "./LedgerCandid";
import LedgerArchiveNode "./ICArchiveNode";

actor class Canister() = this {

  // types
  type AccountIdentifier = Text;
  type Token = Text;
  type LoginResponse = {
    token: Token;
    nonce: Text;
    user: Principal;
    account: AccountIdentifier;
    message: Text;
  };
  public type TransactionError = {
    #Other : Text;
  };
  type Transaction = {
    transactionId: Text;
    amount: Nat64;
  };
  type TransactionResponse = Result.Result<Transaction, TransactionError>;
  type ICPTS = Nat64;
  type DepositTransaction = {
    user: AccountIdentifier;
    amount: ICPTS;
  };
    
  // initialize params for token generation
  private let ae = AsyncSource.Source();
  private let rr = XorShift.toReader(XorShift.XorShift64(null));
  private stable var originId : [Nat8] = [0, 0, 0, 0, 0, 0];
  private let se = Source.Source(rr, originId);
  // wallets
  private let HOUSEWALLET_SUBACCOUNT : [Nat8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
  private let REVENUE_SUBACCOUNT : [Nat8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1];
  // App params
  private stable var _userCount : Nat = 0;
  private stable var identityAdmin : Principal = Principal.fromText("jxauo-25pce-rbgiq-f3zzj-maa7x-y45sw-rm34s-ocait-i7tf7-dj3mr-jqe");
  private stable var _userAccountState : [(AccountIdentifier, Nat)] = [];
  private stable var _userTokenState : [(AccountIdentifier, Token)] = [];
  private stable var _userDeposits : [DepositTransaction] = [];  
  // User data
  private var userTokens : Map.HashMap<AccountIdentifier, Token> = Map.fromIter(_userTokenState.vals(), 0, Text.equal, Text.hash);
  private var userAccounts : Map.HashMap<AccountIdentifier, Nat> = Map.fromIter(_userAccountState.vals(), 0, Text.equal, Text.hash);
  let userDeposits : Buffer.Buffer<DepositTransaction> = Buffer.Buffer<DepositTransaction>(_userDeposits.size());
  for (v in _userDeposits.vals()) {
      userDeposits.add(v);
  };
  // ledger operations
  private let ledger  : Ledger.Interface  = actor(Ledger.CANISTER_ID);
  private let nft_ledger : NFTLedger.Self = actor(NFTLedger.CANISTER_ID);
  // game variables &  types
  type FlipResponse = Int;
  type GameId = Int;
  type GameState = {
    playTime : Int;
    status : Text;
    bet : Nat64;
    won : Nat64;
    gameStatus : Text;
    playerPid : Principal;
    playerAid : AccountIdentifier;
    blockIndex : ?Nat64;
  };
  type GameStats = {
    total_games : Int;
    total_volume : Nat64;
    total_rewards : Nat64;
  };
  
  private stable var MAX_GAMES : Int = 5;
  private stable var GAME_TIMEOUT : Int = 0;
  private stable var last_game_time : Int = 0;
  private stable var last_revenue_distributed : Int = 0;
  private stable var FLIP_HEAD : FlipResponse = 0;
  private stable var FLIP_TAIL : FlipResponse = 1;
  private stable var _games : [(GameId, GameState)] = [];
  private stable var _completed_games : [(GameId, GameState)] = [];
  private stable var _nft_snapshot : [(Text, Nat64)] = [];
  private stable var _temp_snapshot : [(Text, Nat64)] = [];
  private stable var total_games = 0;
  private stable var total_volume : Nat64 = 0;
  private stable var total_rewards : Nat64 = 0;
  private stable var current_games = 0;
  private stable var houseWalletICP : Nat64 = 10000000000;
  private stable var revenueWalletICP : Nat64 = 0;
  // heartbeat controls
  private stable var _runHeartbeat : Bool = true;
  private stable var _orderProcessing : Bool = false;

  private var games : Map.HashMap<GameId, GameState> = Map.fromIter(_games.vals(), 0, Int.equal, Int.hash);  
  private var completed_games : Map.HashMap<GameId, GameState> = Map.fromIter(_completed_games.vals(), 0, Int.equal, Int.hash);  
  private stable var isNFTRevenueDistributeScheduled : Bool = false;
  private stable var lastNFTRevenueDistributeStatus : Text = "none";
  private stable var lastNFTRevenueDistributeTime : Int = 0;
  private var nft_snapshot : Map.HashMap<Text, Nat64> = Map.fromIter(_nft_snapshot.vals(), 0, Text.equal, Text.hash);
  private var temp_snapshot : Map.HashMap<Text, Nat64> = Map.fromIter(_temp_snapshot.vals(), 0, Text.equal, Text.hash);

  private let ledgerCandid : LedgerCandid.Interface = actor("nexk7-dqaaa-aaaah-aby6q-cai");
  private let ledgerArchiveNode : LedgerArchiveNode.Self = actor("qjdve-lqaaa-aaaaa-aaaeq-cai");

  // game logic
  system func heartbeat() : async () {
    var it : Nat = 0;
    if (_runHeartbeat == true){
        if(isNFTRevenueDistributeScheduled) {
          _runHeartbeat := false;
          lastNFTRevenueDistributeStatus := "started";
          var nftIt : Nat = 0;
          for(snap in nft_snapshot.entries()) {
            let account = snap.0;
            let revenue = snap.1;
            if(nftIt > 10) {
              _runHeartbeat := true;
              lastNFTRevenueDistributeStatus := "paused";
              return;
            };
            if(revenue > 0) {
              // let res = await transferFromRevenueWallet(account, revenue - 10000);
              temp_snapshot.put(account, revenue - 10000);
              nft_snapshot.delete(account);
              lastNFTRevenueDistributeTime := Time.now();
            };
            nftIt += 1;

          };
          isNFTRevenueDistributeScheduled := false;
          lastNFTRevenueDistributeStatus := "finished";
        };
        if((last_revenue_distributed > 0) or (revenueWalletICP > 50000000)){
          let tdiff = Time.now() - last_revenue_distributed;
          if((tdiff > 1800000000000) and (revenueWalletICP > 50000000)){
            _runHeartbeat := false;
            _orderProcessing := true;
            let amountToTransfer: Nat64 = Int64.toNat64(Int64.fromNat64(revenueWalletICP));
            let _res = await transferToRevenueWallet(amountToTransfer - 10000);
            last_revenue_distributed := Time.now();
            revenueWalletICP -= amountToTransfer;
            _runHeartbeat := true;
            _orderProcessing := false;
          };
        };
        for (entry in games.entries()) {
            let k = entry.0;
            let v = entry.1;
            if(it > 10){
              _runHeartbeat := true;
              _orderProcessing := false;
              return;
            };
            if(_runHeartbeat){
                _orderProcessing := true;
                _runHeartbeat := false;
            };
            if(v.status == "processing") {
              if (v.bet > 0) {
                var won : Nat64 = v.bet * 2;
                var wonRealized : Nat64 = won - 10000;
                let feePrecentage : Nat64 = 10000;
                var fee : Nat64 = wonRealized * feePrecentage / 100000;
                let res = await transferFromHouseWallet(v.playerAid, wonRealized - fee);
                houseWalletICP -= won;
                revenueWalletICP += fee;
                total_rewards += ((wonRealized - fee) + 10000);
                total_volume += v.bet;
                games.put(k, {
                      bet = v.bet;
                      playTime = v.playTime;
                      playerAid = v.playerAid;
                      playerPid = v.playerPid;
                      status = "completed";
                      won = won;
                      gameStatus = v.gameStatus;
                      blockIndex = v.blockIndex;
                });
              };
              it += 1;
            } else if(v.status == "created" and ((Time.now() - v.playTime) >= 60000000000) ) {
                completed_games.put(k, v);
                games.delete(k);
            } else if(v.status == "completed"){
                completed_games.put(k, v);
                games.delete(k);
            };
        };
        _runHeartbeat := true;
        _orderProcessing := false;
    };
    return;
  };

  func nextGameId() : GameId {
    total_games += 1;
    return total_games + 200;
  };

  func flipAcoin() : FlipResponse {
    return FLIP_HEAD;
  };

  func _flipAcoin() : async FlipResponse {
    let c = await Fliphouse.getEntropyKey();
    switch (c) {
      case (?b) {
        if (b % 2 == 0) {
          return FLIP_HEAD;
        };
      };
      case (_){};
    };
    return FLIP_TAIL;
  };

  func _createGame(user : Principal, userAid : AccountIdentifier, bet : Nat64) : GameId {
    var gameId = nextGameId();
    games.put(gameId, 
      { 
        playTime = Time.now();
        status = "created";
        playerPid = user;
        playerAid = userAid;
        won = 0;
        bet = bet;
        gameStatus = "none";
        blockIndex = null;
      }
    );
    return gameId;
  };

  func _verifyICP(blockIndex: Nat64, amount : Nat64) : Bool {
    return false;
  };

  //System functions
  system func preupgrade() {
     _userTokenState := Iter.toArray(userTokens.entries());
     _userAccountState := Iter.toArray(userAccounts.entries());
     _userDeposits := userDeposits.toArray();
     _games := Iter.toArray(games.entries());
     _completed_games := Iter.toArray(completed_games.entries());
     _nft_snapshot := Iter.toArray(nft_snapshot.entries());
     _temp_snapshot := Iter.toArray(temp_snapshot.entries());
  };

  system func postupgrade() {
     _userTokenState := [];
     _userAccountState := [];
     _userDeposits := [];
     _games := [];
     _completed_games := [];
     _nft_snapshot := [];
     _temp_snapshot := [];
  };

  // helpers
  func p2a(p: Principal, subAccount: Nat) : Text {
      Utils.accountToText(Utils.principalToAccount(p, subAccount))
  };

  public shared(msg) func setAdmin(admin : Principal): async () {
      assert(msg.caller == identityAdmin);
      identityAdmin := admin;
  };

  public shared(msg) func getAdmin(): async Principal {
      return identityAdmin;
  };

  public query func availableCycles() : async Nat {
    return Cycles.balance();
  };

  /*
  public shared(msg) func fundWallet() : async Text {
    assert(msg.caller == identityAdmin);
    // use p2a here for old fund account
    return formatAccountExt(Principal.fromActor(this), 0);
  };

  public shared(msg) func houseWallet(): async Text {
    assert(msg.caller == identityAdmin);
    return formatAccountExt(Principal.fromActor(this), 0);
  };

  public shared(msg) func revenueWallet() : async Text {
    assert(msg.caller == identityAdmin);
    return formatAccountExt(Principal.fromActor(this), 3);
  };
  public shared(msg) func me() : async Principal {
     return Principal.fromActor(this);
  };
 */
  
  func formatAccountExt(principal : Principal, index : Nat8) : Text {
    return AID.fromPrincipal(principal, ?[
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        index
    ]);
  };

  func transferToRevenueWallet(fund : Nat64) : async Ledger.BlockIndex {
      await transferFromHouseWallet(formatAccountExt(Principal.fromActor(this), 1), fund);
  };

 func transferFromRevenueWallet(toAid : Text, fund : Nat64) : async Ledger.BlockIndex {
      await ledger.send_dfx({
          to              = toAid;
          fee             = { e8s = 10_000 };
          memo            = 1;
          from_subaccount = ?Blob.fromArray(REVENUE_SUBACCOUNT);
          created_at_time = null;
          amount          = { e8s = fund };
      });
  };

  func transferFromHouseWallet(toAid : Text, fund : Nat64) : async Ledger.BlockIndex {
      await ledger.send_dfx({
          to              = toAid;
          fee             = { e8s = 10_000 };
          memo            = 0;
          from_subaccount = ?Blob.fromArray(HOUSEWALLET_SUBACCOUNT);
          created_at_time = null;
          amount          = { e8s = fund };
      });
  };

  func toICP(amount : Nat64) : Nat64 {
    return amount * 100000000;
  };

  func fetchNFTSnapshot(total_balance : Nat64) : async Bool {
    let registry = await nft_ledger.getRegistry();
    let supply = 1111.0; // nft_ledger.supply();
    let _total_balance = Float.fromInt64(Int64.fromNat64(total_balance));
    let nft_holders_share = Float.toInt64(_total_balance * 0.7);
    let nft_per_holder_share = Int64.toNat64(Float.toInt64(Float.fromInt64(nft_holders_share)/supply));
    let maker_share = total_balance - Int64.toNat64(nft_holders_share);
    let registryArray = registry.vals();
    for(tokenData in registryArray) {
        let token = tokenData.0;
        let account = tokenData.1;
        switch(nft_snapshot.get(account)) {
          case(?snap){
            nft_snapshot.put(account, snap + nft_per_holder_share);
          };
          case(_){
            nft_snapshot.put(account, nft_per_holder_share);
          };
        };
    };
    if(nft_snapshot.size() > 0) {
      let makerAccount = formatAccountExt(Principal.fromText("zl7r2-ng2rb-mhd73-jz6wt-czb37-5zqwj-jyrzn-zbnmx-femij-yreba-7ae"), 0);
      switch(nft_snapshot.get(makerAccount)) {
        case(?snap){
            nft_snapshot.put(makerAccount, snap + maker_share);
        };
        case(_){
            nft_snapshot.put(makerAccount, maker_share);
        };
      };
      return true;
    };
    return false;
  };

  public shared(msg) func lastNFTRevenueDistributionSnap() : async [(Text, Nat64)] {
    return Iter.toArray(temp_snapshot.entries());
  };
  public shared(msg) func scheduleNFTRevenueDistribution() : async Text {
    assert(msg.caller == identityAdmin);
    if(isNFTRevenueDistributeScheduled){
      return "already scheduled";
    };
    let revenue_account_address = formatAccountExt(Principal.fromActor(this), 1);
    let balance : Ledger.ICP = await ledger.account_balance_dfx({
      account = revenue_account_address
    });
    if(balance.e8s >= 5000000000){
      nft_snapshot := Map.fromIter([].vals(), 0, Text.equal, Text.hash);
      temp_snapshot := Map.fromIter([].vals(), 0, Text.equal, Text.hash);
      if(await fetchNFTSnapshot(balance.e8s)){
 
        isNFTRevenueDistributeScheduled := true;

        return "scheduled";
      }
    };
    return "threshold not reached";
  };

  public query func gameStats() : async GameStats {
    return {
     total_games = total_games;
     total_rewards = total_rewards;
     total_volume = total_volume;
    };
  };

  public query func plays() : async [(GameId, GameState)] {
    let countFilter = (completed_games.size() + 200) - 20;
    let map2 =
      Map.mapFilter<GameId, GameState, GameState>(
        completed_games,
        Int.equal,
        Int.hash,
        func (k, v) = if (k < countFilter) { null } else { ?(v)}
    );
    return Iter.toArray(map2.entries());
  };

  public shared(msg) func createGame2(bet : Nat64) : async GameId{

    if((last_game_time + GAME_TIMEOUT) < Time.now()) {
      current_games := 0;
      last_game_time := Time.now();
    } else if (current_games >= 5) {
      return -1;
    };
    current_games += 1;
    last_game_time := Time.now();
    return _createGame(msg.caller, formatAccountExt(msg.caller, 0), bet);
  };

  func flippedResponse(choice : Int) : FlipResponse {
    if (choice == FLIP_HEAD) {
      return FLIP_TAIL;
    }; 
    return FLIP_HEAD;
  };
  // name fallacy to prevent plug from showing prompt everytime
  public shared(msg) func mintNFT(gameId: Int, blockIndex: Nat64, choice: Int) : async FlipResponse{
    
    switch(games.get(gameId)){
      case(?game){
        if(game.status == "created"){

          let paymentCheck : Bool = await Fliphouse.paymentCheck(msg.caller, blockIndex);
          assert(paymentCheck == true);
          let flip = await _flipAcoin();
          var status = "created";
          var gameStatus = "none";
          let won : Nat64 = 0;
          if (flip == choice){
            // user won the game
            if (Fliphouse.checkForCheating(blockIndex, houseWalletICP)){
              gameStatus := "lost";
              games.put(gameId, {
                status = status;
                playTime = game.playTime;
                playerPid = game.playerPid;
                playerAid = game.playerAid;
                won = won;
                bet = game.bet;
                gameStatus = gameStatus;
                blockIndex = ?blockIndex;
              });
              houseWalletICP += game.bet;
              return flippedResponse(choice);
            } else {
                houseWalletICP += game.bet;
                status := "processing";
                gameStatus := "won";
            };
          } else {
            houseWalletICP += game.bet;
            status := "created";
          };
          games.put(gameId, {
              status = status;
              playTime = game.playTime;
              playerPid = game.playerPid;
              playerAid = game.playerAid;
              won = won;
              bet = game.bet;
              gameStatus = gameStatus;
              blockIndex = ?blockIndex;
          });
          return flip;
        } else {
          return -1;
        };
      };
      case(_){};
    };

    return -1;
  };

  public shared(msg) func gamesCount() : async Nat {
    return games.size();
  };

};


