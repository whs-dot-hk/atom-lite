let
  l = builtins;
in
{
  /**
    `parse featureSet features` processes a set of features and resolves dependencies to return a sorted, deduplicated list of all required features.

    This function is useful for managing feature sets with dependencies, ensuring that each feature and its dependencies are included in a consistent order.

    **Relation to Dependency Resolution**

    This section explains `parse` by demonstrating how it resolves dependencies and ensures a stable order of features.

    For context, when dealing with feature sets in Nix, you might have features that depend on other features. The `parse` function helps in resolving these dependencies and provides a final list where each feature appears only once and is ordered such that dependencies are satisfied.

    ```nix
    let
      featureSet = {
        featureA = [ "featureB" ];
        featureB = [ "featureC" ];
        featureC = [ ];
      };
    in
    parse featureSet [ "featureA" ]
    ```

    This example will return a list: `[ "featureC", "featureB", "featureA" ]`, ensuring that each feature's dependencies are resolved and ordered correctly.

    The function uses a recursive approach to achieve this, similar to how fixed-point computations work, by repeatedly sorting and deduplicating until no further changes occur.

    # Inputs

    `featureSet`

    : 1\. Attribute set where each attribute represents a feature and maps to a list of its dependencies.

    `features`

    : 2\. List with selected features.

    # Type

    ```
    parse :: { a: [a] } -> [a]
    ```

    # Examples
    :::{.example}
    ## `parse` usage example

    ```nix
    let
      featureSet = {
        featureA = [ "featureB" ];
        featureB = [ "featureC" ];
        featureC = [ ];
      };
    in
    parse featureSet [ "featureA" ]
    => [ "featureC", "featureB", "featureA" ]

    let
      featureSet = {
        featureX = [ "featureY", "featureZ" ];
        featureY = [ ];
        featureZ = [ "featureY" ];
      };
    in
    parse featureSet [ "featureX" ]
    => [ "featureY", "featureZ", "featureX" ]
    ```

    :::
  */
  parse =
    featureSet:
    let
      fold = l.foldl' (
        acc: x:
        acc ++ l.filter (y: !l.elem y acc) featureSet.${x} or [ ] ++ (if l.elem x acc then [ ] else [ x ])
      ) [ ];
      fixed =
        xs:
        let
          xs' = l.sort l.lessThan xs;
          next = l.sort l.lessThan (fold xs');
        in
        if next == xs' then xs' else fixed next;
    in
    fixed;
}
