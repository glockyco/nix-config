{
  openspec,
  personalOmp,
  symlinkJoin,
}:

symlinkJoin {
  name = "personal-omp-wsl";
  paths = [
    personalOmp
    openspec
    personalOmp.reconcileHerdrOmp
    personalOmp.verifyPersonalOmp
  ];

  passthru = {
    inherit openspec personalOmp;
  };
}
