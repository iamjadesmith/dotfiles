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
  running = fetchApp "running" "f38ca63e1650bffa40fd63589c9cccabaca5039b" "sha256-AxDOtnsAPHN5zFUZDYImvTAE5Hk61XZuR5Ytj1v3p2s=";
  workoutRust = fetchApp "workout_rust" "3af35c8ea6a2c713902344486bf5c13b1a3095fe" "sha256-YBJyQevJZyy2Tkee646nOB6cPAO5rJYzZ8Jufbu2FSc=";
  stock = fetchApp "stock" "78af7f0fdf308b8bab5512928e63082ca8061edb" "sha256-optrcT9mFEJ4DGBflHk3qFyVsSnxAyF0mK6WnWIfXWk=";
}
