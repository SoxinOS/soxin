{ lib }:

overlaysAttrs: pkgs:
let
  overlayDrvs = lib.mapAttrs (_: v: v pkgs pkgs) overlaysAttrs;

  # some derivations fail to evaluate, simply remove them so we can move on
  filterDrvs = lib.filterAttrsRecursive
    (_: v: (builtins.tryEval v).success)
    overlayDrvs;

  drvs = lib.collect (lib.isDerivation) filterDrvs;

  # don't bother exporting a package if it's platform isn't supported
  systemDrvs = builtins.filter
    (drv: builtins.elem
      pkgs.system
      (drv.meta.platforms or [ ]))
    drvs;

  nvPairs = map
    (drv: lib.nameValuePair (lib.getName drv) drv)
    systemDrvs;
in
builtins.listToAttrs nvPairs
