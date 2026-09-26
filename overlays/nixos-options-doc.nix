{
  lib,
  path,
  nixosOptionsDoc,
}:
let
  nixpkgsPath = builtins.unsafeDiscardStringContext (toString path);

  normalizeDeclaration =
    declaration:
    if builtins.isString declaration || builtins.isPath declaration then
      let
        declarationPath = builtins.unsafeDiscardStringContext (toString declaration);
      in
      if lib.hasPrefix "${nixpkgsPath}/" declarationPath then
        builtins.unsafeDiscardStringContext ("<nixpkgs${lib.removePrefix nixpkgsPath declarationPath}>")
      else
        declaration
    else
      declaration;

in
args:
nixosOptionsDoc (
  args
  // {
    transformOptions =
      option:
      let
        transformed = (args.transformOptions or lib.id) option;
      in
      transformed
      // {
        declarations = map normalizeDeclaration transformed.declarations;
      };
  }
)
