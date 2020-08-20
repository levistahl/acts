// This file is part of the Acts project.
//
// Copyright (C) 2020 CERN for the benefit of the Acts project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// CUDA plugin include(s).
#include "Acts/Plugins/Cuda/Seeding2/Details/Types.hpp"
#include "Acts/Plugins/Cuda/Utilities/Arrays.hpp"
#include "../Utilities/ErrorCheck.cuh"

// CUDA include(s).
#include <cuda_runtime.h>

namespace Acts {
namespace Cuda {
namespace Details {

void DeviceArrayDeleter::operator()(void* ptr) {
  // Ignore null-pointers.
  if (ptr == nullptr) {
    return;
  }

  // Free the pinned host memory.
  ACTS_CUDA_ERROR_CHECK(cudaFree(ptr));
  return;
}

void HostArrayDeleter::operator()(void* ptr) {
  // Ignore null-pointers.
  if (ptr == nullptr) {
    return;
  }

  // Free the pinned host memory.
  ACTS_CUDA_ERROR_CHECK(cudaFreeHost(ptr));
  return;
}

}  // namespace Details

template <typename T>
device_array<T> make_device_array(std::size_t size) {
  // Allocate the memory.
  T* ptr = nullptr;
  if (size != 0) {
    ACTS_CUDA_ERROR_CHECK(cudaMalloc(&ptr, size * sizeof(T)));
  }
  // Create the smart pointer.
  return device_array<T>(ptr);
}

template <typename T>
host_array<T> make_host_array(std::size_t size) {
  // Allocate the memory.
  T* ptr = nullptr;
  if (size != 0) {
    ACTS_CUDA_ERROR_CHECK(cudaMallocHost(&ptr, size * sizeof(T)));
  }
  // Create the smart pointer.
  return host_array<T>(ptr);
}

template <typename T>
void copyToDevice(device_array<T>& dev, const host_array<T>& host,
                  std::size_t arraySize) {
  ACTS_CUDA_ERROR_CHECK(cudaMemcpy(dev.get(), host.get(), arraySize * sizeof(T),
                                   cudaMemcpyHostToDevice));
  return;
}

template <typename T>
void copyToHost(host_array<T>& host, const device_array<T>& dev,
                std::size_t arraySize) {
  ACTS_CUDA_ERROR_CHECK(cudaMemcpy(host.get(), dev.get(), arraySize * sizeof(T),
                                   cudaMemcpyDeviceToHost));
  return;
}

}  // namespace Cuda
}  // namespace Acts

/// Helper macro for instantiating the template code for a given type
///
/// Note that nvcc (at least as of CUDA version 11.0.2) does not allow us to
/// instantiate our custom unique pointer types through their typedef'd names.
/// That's why the following expressions are as long as they are.
///
#define INST_ARRAY_FOR_TYPE(TYPE)                                              \
  template class std::unique_ptr<TYPE,                                         \
                                 Acts::Cuda::Details::DeviceArrayDeleter>;     \
  template std::unique_ptr<TYPE, Acts::Cuda::Details::DeviceArrayDeleter>      \
      Acts::Cuda::make_device_array<TYPE>(std::size_t);                        \
  template class std::unique_ptr<TYPE, Acts::Cuda::Details::HostArrayDeleter>; \
  template std::unique_ptr<TYPE, Acts::Cuda::Details::HostArrayDeleter>        \
      Acts::Cuda::make_host_array<TYPE>(std::size_t);                          \
  template void Acts::Cuda::copyToDevice<TYPE>(                                \
      std::unique_ptr<TYPE, Acts::Cuda::Details::DeviceArrayDeleter>&,         \
      const std::unique_ptr<TYPE, Acts::Cuda::Details::HostArrayDeleter>&,     \
      std::size_t);                                                            \
  template void Acts::Cuda::copyToHost<TYPE>(                                  \
      std::unique_ptr<TYPE, Acts::Cuda::Details::HostArrayDeleter>&,           \
      const std::unique_ptr<TYPE, Acts::Cuda::Details::DeviceArrayDeleter>&,   \
      std::size_t)

// Instantiate the templated functions for all primitive types.
INST_ARRAY_FOR_TYPE(char);
INST_ARRAY_FOR_TYPE(unsigned char);
INST_ARRAY_FOR_TYPE(short);
INST_ARRAY_FOR_TYPE(unsigned short);
INST_ARRAY_FOR_TYPE(int);
INST_ARRAY_FOR_TYPE(unsigned int);
INST_ARRAY_FOR_TYPE(long);
INST_ARRAY_FOR_TYPE(unsigned long);
INST_ARRAY_FOR_TYPE(long long);
INST_ARRAY_FOR_TYPE(unsigned long long);
INST_ARRAY_FOR_TYPE(float);
INST_ARRAY_FOR_TYPE(double);

// Instantiate them for any necessary custom type(s) as well.
INST_ARRAY_FOR_TYPE(Acts::Cuda::Details::SpacePoint);
INST_ARRAY_FOR_TYPE(Acts::Cuda::Details::DubletCounts);
INST_ARRAY_FOR_TYPE(Acts::Cuda::Details::LinCircle);
INST_ARRAY_FOR_TYPE(Acts::Cuda::Details::Triplet);

// Clean up.
#undef INST_ARRAY_FOR_TYPE
