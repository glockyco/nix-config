{
  lib,
  pkgs,
  ...
}:

let
  personalOmp = pkgs.personal-omp;
in

{
  home.packages = [
    personalOmp
    personalOmp.devUpdate
    personalOmp.verifyPersonalOmp
    pkgs.openspec
  ];

  # Source preparation is explicit. Activation reconciles Herdr without
  # preparing or launching OMP, and leaves source selection unchanged.
  home.activation.reconcileHerdrOmp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe personalOmp.reconcileHerdrOmp}
  '';
}
