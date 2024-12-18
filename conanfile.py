from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain

class Cupcake(ConanFile):
    name = 'cupcake.cmake'
    version = '1.2.2'
    user = 'github'
    channel = 'thejohnfreeman'

    license = 'ISC'
    author = 'John Freeman <jfreeman08@gmail.com>'
    url = 'https://github.com/thejohnfreeman/cupcake.cmake'
    description = 'CMake boilerplate for an opinionated project structure.'

    # TODO: The CMake helper requires the build_type setting to run its build
    # or install methods.
    settings = ['build_type']
    options = {}

    exports_sources = 'CMakeLists.txt', 'config.cmake.in', 'cmake/*'
    # For out-of-source build.
    # https://docs.conan.io/en/latest/reference/build_helpers/cmake.html#configure
    no_copy_source = True
    generators = 'CMakeToolchain'

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        # No build. Just configure and install.

    def package(self):
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        module = 'share/cupcake.cmake/cupcake.cmake-config.cmake'
        for generator in ('cmake_find_package', 'cmake_find_package_multi'):
            self.cpp_info.build_modules[generator].append(module)
        import os.path
        self.cpp_info.set_property(
            'cmake_build_modules',
            [os.path.join(self.package_folder, module)]
        )
