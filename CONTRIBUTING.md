Cupcake is developed on the `develop` branch.
In this branch, the version string in `conanfile.py` is `alpha`.
The version string in `CMakeLists.txt` is `0.0.0`
only because `alpha` is not [allowed][2].

The `develop` branch is a submodule of [project-template-cpp][]
at path `/cupcake/`.
That repository contains the tests for Cupcake.
See their [instructions][1].

When Cupcake is ready for release,
the `develop` branch is merged into `master`,
the version strings are changed,
and the commit is tagged.
This way, the version strings in the `develop` branch are never changed.

```
git checkout master
git pull --no-ff origin develop
version=...
sed -i "s/x.y.z/${version}/" conanfile.py README.md CMakeLists.txt
git commit --all --message "Bump version to ${version}"
git tag $version
git push
git push --tag
conan export .
conan upload --remote github cupcake/${version}@github/thejohnfreeman
```


[project-template-cpp]: https://github.com/thejohnfreeman/project-template-cpp
[1]: https://github.com/thejohnfreeman/project-template-cpp/blob/master/CONTRIBUTING.md
[2]: https://gitlab.kitware.com/cmake/cmake/-/issues/16716
