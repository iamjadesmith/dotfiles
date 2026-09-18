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
  golfRust = fetchApp "golf_rust" "72468d414fb551405127ac31164396a40b72e8c6" "sha256-13+l/7z1lk5Z/dL5ZE2IwTzYDfXOWvFprPZhS/94sFg=";
  receipt = fetchApp "receipt" "435a56e861a7b63fc949721952d18d060ad16b01" "sha256-fnemQWj6adXnP5kbwgRJgXJj81shPWn+cOrMOHTMzg0=";
  running = fetchApp "running" "3ad7233939389a0f7aaf72b89d451c0db70e6236" "sha256-iPENz3DFH4KZsNPZWKad5/IJiSYRdp/kGra49v2cl7Y=";
  workoutRust = fetchApp "workout_rust" "c7eb3ae7db5265cd9469b9b86ee4bf753405874f" "sha256-ToruefirlDzk/373k3pqtOLdQhpkw7iJbRMPHDkLchM=";
  stock = fetchApp "stock" "78af7f0fdf308b8bab5512928e63082ca8061edb" "sha256-optrcT9mFEJ4DGBflHk3qFyVsSnxAyF0mK6WnWIfXWk=";
}
