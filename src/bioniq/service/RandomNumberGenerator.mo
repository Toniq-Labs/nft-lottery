import Fuzz "mo:fuzz";
import Time "mo:base/Time";
import Result "mo:base/Result";
import IC "IC";
import Principal "mo:base/Principal";
import ExtCore "/motoko/ext/Core";


actor class NumGen(init_owner: Principal) = this {


    type Time = Time.Time;

    let MAX_VALUE : Nat32 = 9999;

    private stable var data_generatedNumber : Nat32 = MAX_VALUE+1;
    private stable var data_initTime : Time = 0;

    let ic: IC.ICActor = actor("aaaaa-aa");

  public shared func drawRandomNumber() : async  Result.Result<(Nat32, Text), Text> {
    if (data_initTime <= 0) return #err("Init time not set yet.");
    if (Time.now() < data_initTime) return #err("Too early, starts at: " # debug_show(data_initTime));
    if (data_generatedNumber > MAX_VALUE)
    {
        let blob = await ic.raw_rand();
        let fuzz = Fuzz.fromBlob(blob);
        let randNat32 = fuzz.nat32.randomRange(0, MAX_VALUE);
        data_generatedNumber := randNat32;
    };
    #ok(data_generatedNumber, ExtCore.TokenIdentifier.fromPrincipal(Principal.fromText("bk5uo-miaaa-aaaal-qiulq-cai"),data_generatedNumber ) );
  };

  public shared({caller}) func init() : async Result.Result<Time, Text> {
    if (caller == init_owner)
    {        
        data_initTime := Time.now() + 1 * 60 * 60 * 1000000000;

        await ic.update_settings({
            canister_id = Principal.fromActor(this);
            settings =
            {
                controllers = ?[Principal.fromText("e3mmv-5qaaa-aaaah-aadma-cai")];
                compute_allocation = null;
                memory_allocation  = null;
                freezing_threshold  = null;
            };

        });

        return #ok(data_initTime);
    };
    return #err("Only init owner can set Time")

  };

};