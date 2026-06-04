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
  budget = fetchApp "budget" "eb5c25f9b1333d4aa7290cff5a699cfbfc21e80c" "sha256-TqR9QIcd7FoF0opqLWzJpcGTNt4N9AMCDgstTO9oM4A=";
  foodLog = fetchApp "food_log" "30b771384d8e5285ec48f98c5f28088533a46a0d" "sha256-n3xOvAeZU++yCCOiPNL8NE+d/vupxtWaEA2lrfvht6A=";
  golfRust = fetchApp "golf_rust" "7410fc2e7cb6165dd2e2627d8c0d6d682f6bf5b6" "sha256-SsjBxJYLp6G9QSBZ9ZnmtYhCGF8NA0qbU9KUYvVDr1E=";
  receipt = fetchApp "receipt" "d52b04bc320fff72b94aed35713ff2e3cfbbc0e7" "sha256-ZOoBbCjGBuhL/ztR/v+Y+gCuiuiU62haMnPQsm01TIA=";
  running = fetchApp "running" "e3b17ffae97c127f76a212b838254ab6308ac297" "sha256-ygLVrxlIJuFDknoyFQyv1HHAt9PgCrLUhMwGgj0IJWI=";
  workoutRust = fetchApp "workout_rust" "1a13e0ea8f592e16c1fa4e743a10fb486f938ded" "sha256-z08slp7xc3MYH00Qdk6jqsUoVmEXy9V3pe2mLWEcOTM=";
}
