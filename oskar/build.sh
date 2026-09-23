#!/bin/sh
set -eux

echo "CC=${CC}"
echo "CXX=${CXX}"
"${CC}" --version
"${CXX}" --version

# GPU architectures: conda-forge's cuda-nvcc exports CUDAARCHS on activation (5.0 to 12.1,
# incl. Hopper 90a and Blackwell, plus PTX for forward compatibility), and CMake takes it over
# OSKAR's own CUDA_ARCH option, so that list is what gets built. (OSKAR still prints its default
# list during configure; the check at the end looks at what is actually in the library.)
cmake \
    -DFIND_CUDA=ON \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_C_COMPILER="${CC}" \
    -DCMAKE_CXX_COMPILER="${CXX}" \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON \
    .

make -j"${CPU_COUNT:-2}" install

# OSKAR's find_package(CUDAToolkit) is optional: without it the build silently becomes CPU-only.
# Fail unless the library links the CUDA runtime and carries Hopper (sm_90) machine code.
"${READELF:-readelf}" -d "${PREFIX}/lib/liboskar.so" | grep libcudart
cuobjdump --list-elf "${PREFIX}/lib/liboskar.so" | grep sm_90
