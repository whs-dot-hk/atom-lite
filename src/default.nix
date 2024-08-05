# to avoid excessive recursion that can lead to inefficiency or errors
# we cannot compose the individual pieces of the module composer as a regular module
# so instead we abstract them out here, into a manually specified "psuedo-module"
# to keep the core impelementation clean
let
  compose = import ../.;
  fix = import ../std/fix.nix;
  cond = import ../std/set/cond.nix;
  filterMap = scopedImport { std = builtins; } ../std/set/filterMap.nix;
  strToPath = scopedImport { std = builtins; } ../std/path/strToPath.nix;
  parse = scopedImport { std = builtins; } ../std/file/parse.nix;
  toLowerCase = scopedImport rec {
    std = builtins;
    mod = scopedImport { inherit std mod; } ../std/string/mod.nix;
  } ../std/string/toLowerCase.nix;
  stdFilter = import ./stdFilter.nix;
in
{
  inherit
    parse
    fix
    filterMap
    strToPath
    cond
    ;

  errors = import ./errors.nix;

  lowerKeys = filterMap (k: v: { ${toLowerCase k} = v; });

  collectPublic = filterMap (
    k: v:
    let
      s = toLowerCase k;
    in
    if s == k then null else { ${s} = v; }
  );

  rmNixSrcs = builtins.filterSource (
    path: type:
    let
      file = parse (baseNameOf path);
    in
    (type == "regular" && file.ext or null != "nix")
    || (type == "directory" && !builtins.pathExists "${path}/mod.nix")
  );

  composeStd = path: compose { } path // filterMap stdFilter builtins;

  modIsValid =
    mod: dir:
    builtins.isAttrs mod
    || throw ''
      The following module does not evaluate to a valid attribute set:
             ${toString dir}/mod.nix
    '';

  injectPrevious =
    pre: set:
    set
    // cond {
      _if = pre != null;
      inherit pre;
    };

  hasMod = contents: contents."mod.nix" or null == "regular";
}