# External AnoCrypto-C Boundary

This directory is documentation-only and contains no AnoCrypto-C source,
headers, binaries, archives, or package contents.

AnoCrypto-C is managed in its own repository and is supplied separately under
its own release and license terms. The expected installed CMake contract is:

```cmake
find_package(AnoCryptoC CONFIG REQUIRED)
target_link_libraries(<private-adapter> PRIVATE AnoCryptoC::AnoCryptoC)
```

Do not add a local `CMakeLists.txt` or source-tree fallback here. The proprietary
C++ provider adapter belongs to Enterprise-owned source outside this placeholder
boundary.
