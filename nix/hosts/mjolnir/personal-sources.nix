let
  forgejo = "http://joejadserver.joejad.lan:3000/jade";

  fetchApp =
    name: rev: narHash:
    builtins.fetchTree {
      type = "git";
      url = "${forgejo}/${name}.git";
      ref = "main";
      inherit rev narHash;
    };
in
{
  budget = fetchApp "budget" "879ef776fec6ab61d63d5afae5589413b2950b51" "sha256-bjMzdO4micdq38X+2Xb8raHAmSnLnnqEOGJ+RPShFFg=";
  foodLog = fetchApp "food_log" "af0b6e07177ebdab3e39074929bf69dc36667f3a" "sha256-BS6M+ywpcSI/plXM15LzeE+C1pMIGqhyyuGTPfNrG0k=";
  golfRust = fetchApp "golf_rust" "ce8d24653f4a4bb6f24c076bb6831177bc0a1499" "sha256-ORwmlAkpr+N/8klsOWXEMEwRugx9h5XbyJZjrwGBVPE=";
  receipt = fetchApp "receipt" "435a56e861a7b63fc949721952d18d060ad16b01" "sha256-fnemQWj6adXnP5kbwgRJgXJj81shPWn+cOrMOHTMzg0=";
  running = fetchApp "running" "3ad7233939389a0f7aaf72b89d451c0db70e6236" "sha256-iPENz3DFH4KZsNPZWKad5/IJiSYRdp/kGra49v2cl7Y=";
  workoutRust = fetchApp "workout_rust" "9bf231cb1a024d6342d0ed7f1ec787811a950d04" "sha256-vtm3CEwP8TbpjgHlZVCQonzifSpouiU76uSASs1/roM=";
  stock = fetchApp "stock" "78af7f0fdf308b8bab5512928e63082ca8061edb" "sha256-optrcT9mFEJ4DGBflHk3qFyVsSnxAyF0mK6WnWIfXWk=";
}
