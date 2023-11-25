## Test

The tests for this package
are the project templates in [project-template-cpp][].

Development on this package generally follows
an iteration cycle after initial setup:

1. Bump the version of this package, `cupcake`.
    ```
    # in cupcake
    sed -i 's/0\.4\.1/0.4.2/' CMakeLists.txt conanfile.py README.md
    ```
2. Bump the version depended in project-template-cpp.
    ```
    # in project-template-cpp
    sed -i 's#cupcake/0.4.1#cupcake/0.4.2#' */conanfile.py */conanfile.txt
    ```

3. Make changes to `cupcake`.
4. Export a new revision of `cupcake`
    under the new version number
    to the local Conan cache.
    ```
    # in cupcake
    conan export .
    ```
4. Execute the tests in project-template-cpp.
    ```
    # in project-template-cpp
    GENERATOR=Ninja SHARED=OFF FLAVOR=release poetry run pytest
    ```
    (Passing all 96 configurations sequentially takes about 11 minutes.)
5. Loop back to step 3.


## Publish

Once development has finished, publish a new version of `cupcake`:

```
# in cupcake
tag = ...
git tag $tag
git push
git push --tag
conan export .
conan upload --remote github cupcake/$tag@github/thejohnfreeman
```

Don't forget to update the tests:

```
# in project-template-cpp
pushd cupcake
git pull origin $tag
popd
git add cupcake
git commit
git push
```


[project-template-cpp]: https://github.com/thejohnfreeman/project-template-cpp
