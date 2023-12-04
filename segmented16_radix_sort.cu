// MIT License
//
// Copyright (c) 2020 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include "common_benchmark_header.cuh"

// CUDA API
#include <cub/cub.cuh>

#ifndef DEFAULT_N
const size_t DEFAULT_N = 1024 * 1024 * 32;
#endif

const unsigned int batch_size = 4;
const unsigned int warmup_size = 2;

constexpr bool Ascending = false;
constexpr bool Descending = true;

// template <class Key>
// void run_sort_keys_benchmark(benchmark::State &state, size_t
// desired_segments,
//                              cudaStream_t stream, size_t size,
//                              bool descending = false) {
//   using offset_type = int;
//   using key_type = Key;
//   typedef cudaError_t (*sort_func)(void *, size_t &, const key_type *,
//                                   key_type *, int, int, offset_type *,
//                                   offset_type *, int, int, cudaStream_t,
//                                   bool);

//   sort_func func_ascending =
//       &cub::DeviceSegmentedRadixSort::SortKeys<key_type, offset_type *>;
//   sort_func func_descending =
//       &cub::DeviceSegmentedRadixSort::SortKeysDescending<key_type,
//                                                             offset_type *>;

//   sort_func sorting = descending ? func_descending : func_ascending;

//   // Generate data
//   std::vector<offset_type> offsets;

//   const double avg_segment_length =
//       static_cast<double>(size) / desired_segments;

//   const unsigned int seed = 123;
//   std::default_random_engine gen(seed);

//   std::uniform_real_distribution<double> segment_length_dis(
//       0, avg_segment_length * 2);

//   unsigned int segments_count = 0;
//   size_t offset = 0;
//   while (offset < size) {
//     const size_t segment_length = std::round(segment_length_dis(gen));
//     offsets.push_back(offset);
//     segments_count++;
//     offset += segment_length;
//   }
//   offsets.push_back(size);

//   std::vector<key_type> keys_input;
//   if (std::is_floating_point<key_type>::value) {
//     keys_input = benchmark_utils::get_random_data<key_type>(
//         size, (key_type)-1000, (key_type) + 1000);
//   } else {
//     keys_input = benchmark_utils::get_random_data<key_type>(
//         size, std::numeric_limits<key_type>::min(),
//         std::numeric_limits<key_type>::max());
//   }

//   offset_type *d_offsets;
//   CUDA_CHECK(cudaMalloc(&d_offsets, (segments_count + 1) *
//   sizeof(offset_type))); CUDA_CHECK(cudaMemcpy(d_offsets, offsets.data(),
//                       (segments_count + 1) * sizeof(offset_type),
//                       cudaMemcpyHostToDevice));

//   key_type *d_keys_input;
//   key_type *d_keys_output;
//   CUDA_CHECK(cudaMalloc(&d_keys_input, size * sizeof(key_type)));
//   CUDA_CHECK(cudaMalloc(&d_keys_output, size * sizeof(key_type)));
//   CUDA_CHECK(cudaMemcpy(d_keys_input, keys_input.data(), size *
//   sizeof(key_type),
//                       cudaMemcpyHostToDevice));

//   void *d_temporary_storage = nullptr;
//   size_t temporary_storage_bytes = 0;
//   CUDA_CHECK(sorting(d_temporary_storage, temporary_storage_bytes,
//   d_keys_input,
//                     d_keys_output, size, segments_count, d_offsets,
//                     d_offsets + 1, 0, sizeof(key_type) * 8, stream, false));

//   CUDA_CHECK(cudaMalloc(&d_temporary_storage, temporary_storage_bytes));
//   CUDA_CHECK(cudaDeviceSynchronize());

//   // Warm-up
//   for (size_t i = 0; i < warmup_size; i++) {
//     CUDA_CHECK(sorting(d_temporary_storage, temporary_storage_bytes,
//                       d_keys_input, d_keys_output, size, segments_count,
//                       d_offsets, d_offsets + 1, 0, sizeof(key_type) * 8,
//                       stream, false));
//   }
//   CUDA_CHECK(cudaDeviceSynchronize());

//   for (auto _ : state) {
//     auto start = std::chrono::high_resolution_clock::now();

//     for (size_t i = 0; i < batch_size; i++) {
//       CUDA_CHECK(sorting(d_temporary_storage, temporary_storage_bytes,
//                         d_keys_input, d_keys_output, size, segments_count,
//                         d_offsets, d_offsets + 1, 0, sizeof(key_type) * 8,
//                         stream, false));
//     }
//     CUDA_CHECK(cudaDeviceSynchronize());

//     auto end = std::chrono::high_resolution_clock::now();
//     auto elapsed_seconds =
//         std::chrono::duration_cast<std::chrono::duration<double>>(end -
//         start);
//     state.SetIterationTime(elapsed_seconds.count());
//   }
//   state.SetBytesProcessed(state.iterations() * batch_size * size *
//                           sizeof(key_type));
//   state.SetItemsProcessed(state.iterations() * batch_size * size);

//   CUDA_CHECK(cudaFree(d_temporary_storage));
//   CUDA_CHECK(cudaFree(d_offsets));
//   CUDA_CHECK(cudaFree(d_keys_input));
//   CUDA_CHECK(cudaFree(d_keys_output));
// }

template <class Key, class Value>
void run_sort_pairs_benchmark(benchmark::State &state, size_t desired_segments,
                              cudaStream_t stream, size_t size,
                              bool descending = false) {
  using offset_type = int;
  using key_type = Key;
  using value_type = Value;
  typedef cudaError_t (*sort_func)(void *, size_t &, const key_type *,
                                   key_type *, const value_type *, value_type *,
                                   int, int, offset_type *, offset_type *, int,
                                   int, cudaStream_t, bool);

  //   sort_func func_ascending =
  //       &cub::DeviceSegmentedRadixSort::SortPairs<key_type, value_type,
  //                                                    offset_type *>;
  sort_func func_descending =
      &cub::DeviceSegmentedRadixSort::SortPairsDescending<key_type, value_type,
                                                          offset_type *>;

  sort_func sorting = func_descending;

  // Generate data
  std::vector<offset_type> offsets;

  const double avg_segment_length =
      static_cast<double>(size) / desired_segments;

  const unsigned int seed = 123;
  std::default_random_engine gen(seed);

  std::uniform_real_distribution<double> segment_length_dis(
      0, avg_segment_length * 2);

  unsigned int segments_count = 0;
  size_t offset = 0;
  while (offset < size) {
    const size_t segment_length = std::round(segment_length_dis(gen));
    offsets.push_back(offset);
    segments_count++;
    offset += segment_length;
  }
  offsets.push_back(size);

  std::vector<key_type> keys_input;
  if (std::is_floating_point<key_type>::value) {
    keys_input = benchmark_utils::get_random_data<key_type>(
        size, (key_type)-1000, (key_type) + 1000);
  } else {
    keys_input = benchmark_utils::get_random_data<key_type>(
        size, std::numeric_limits<key_type>::min(),
        std::numeric_limits<key_type>::max());
  }

  std::vector<value_type> values_input(size);
  std::iota(values_input.begin(), values_input.end(), 0);

  offset_type *d_offsets;
  CUDA_CHECK(
      cudaMalloc(&d_offsets, (segments_count + 1) * sizeof(offset_type)));
  CUDA_CHECK(cudaMemcpy(d_offsets, offsets.data(),
                        (segments_count + 1) * sizeof(offset_type),
                        cudaMemcpyHostToDevice));

  key_type *d_keys_input;
  key_type *d_keys_output;
  CUDA_CHECK(cudaMalloc(&d_keys_input, size * sizeof(key_type)));
  CUDA_CHECK(cudaMalloc(&d_keys_output, size * sizeof(key_type)));
  CUDA_CHECK(cudaMemcpy(d_keys_input, keys_input.data(),
                        size * sizeof(key_type), cudaMemcpyHostToDevice));

  value_type *d_values_input;
  value_type *d_values_output;
  CUDA_CHECK(cudaMalloc(&d_values_input, size * sizeof(value_type)));
  CUDA_CHECK(cudaMalloc(&d_values_output, size * sizeof(value_type)));
  CUDA_CHECK(cudaMemcpy(d_values_input, values_input.data(),
                        size * sizeof(value_type), cudaMemcpyHostToDevice));

  void *d_temporary_storage = nullptr;
  size_t temporary_storage_bytes = 0;
  CUDA_CHECK(sorting(d_temporary_storage, temporary_storage_bytes, d_keys_input,
                     d_keys_output, d_values_input, d_values_output, size,
                     segments_count, d_offsets, d_offsets + 1, 0,
                     sizeof(key_type) * 8, stream, false));

  CUDA_CHECK(cudaMalloc(&d_temporary_storage, temporary_storage_bytes));
  CUDA_CHECK(cudaDeviceSynchronize());

  // Warm-up
  for (size_t i = 0; i < warmup_size; i++) {
    CUDA_CHECK(sorting(d_temporary_storage, temporary_storage_bytes,
                       d_keys_input, d_keys_output, d_values_input,
                       d_values_output, size, segments_count, d_offsets,
                       d_offsets + 1, 0, sizeof(key_type) * 8, stream, false));
  }
  CUDA_CHECK(cudaDeviceSynchronize());

  for (auto _ : state) {
    auto start = std::chrono::high_resolution_clock::now();

    for (size_t i = 0; i < batch_size; i++) {
      CUDA_CHECK(sorting(
          d_temporary_storage, temporary_storage_bytes, d_keys_input,
          d_keys_output, d_values_input, d_values_output, size, segments_count,
          d_offsets, d_offsets + 1, 0, sizeof(key_type) * 8, stream, false));
    }
    CUDA_CHECK(cudaDeviceSynchronize());

    auto end = std::chrono::high_resolution_clock::now();
    auto elapsed_seconds =
        std::chrono::duration_cast<std::chrono::duration<double>>(end - start);
    state.SetIterationTime(elapsed_seconds.count());
  }
  state.SetBytesProcessed(state.iterations() * batch_size * size *
                          (sizeof(key_type) + sizeof(value_type)));
  state.SetItemsProcessed(state.iterations() * batch_size * size);

  CUDA_CHECK(cudaFree(d_temporary_storage));
  CUDA_CHECK(cudaFree(d_offsets));
  CUDA_CHECK(cudaFree(d_keys_input));
  CUDA_CHECK(cudaFree(d_keys_output));
  CUDA_CHECK(cudaFree(d_values_input));
  CUDA_CHECK(cudaFree(d_values_output));
}

#define CREATE_SORT_PAIRS_DESCENDING_BENCHMARK(Key, Value, SEGMENTS)           \
  benchmark::RegisterBenchmark(                                                \
      (std::string("sort_pairs") + "<" #Key ", " #Value ">" + "(~" +           \
       std::to_string(SEGMENTS) + " segments), descending")                    \
          .c_str(),                                                            \
      [=](benchmark::State &state) {                                           \
        run_sort_pairs_benchmark<Key, Value>(state, SEGMENTS, stream, size,    \
                                             Descending);                      \
      })

#define BENCHMARK_PAIR_TYPE(type, value)                                       \
  CREATE_SORT_PAIRS_DESCENDING_BENCHMARK(type, value, 16)

void add_sort_pairs_benchmarks(
    std::vector<benchmark::internal::Benchmark *> &benchmarks,
    cudaStream_t stream, size_t size) {
  using custom_float2 = benchmark_utils::custom_type<float, float>;
  using custom_double2 = benchmark_utils::custom_type<double, double>;

  std::vector<benchmark::internal::Benchmark *> bs = {
      BENCHMARK_PAIR_TYPE(float, int),
  };
  benchmarks.insert(benchmarks.end(), bs.begin(), bs.end());
}

int main(int argc, char *argv[]) {
  cli::Parser parser(argc, argv);
  parser.set_optional<size_t>("size", "size", DEFAULT_N, "number of values");
  parser.set_optional<int>("trials", "trials", -1, "number of iterations");
  parser.run_and_exit_if_error();

  // Parse argv
  benchmark::Initialize(&argc, argv);
  const size_t size = parser.get<size_t>("size");
  const int trials = parser.get<int>("trials");

  std::cout << "benchmark_device_segmented_radix_sort" << std::endl;

  // CUDA
  cudaStream_t stream = 0; // default
  cudaDeviceProp devProp;
  int device_id = 0;
  CUDA_CHECK(cudaGetDevice(&device_id));
  CUDA_CHECK(cudaGetDeviceProperties(&devProp, device_id));
  std::cout << "[CUDA] Device name: " << devProp.name << std::endl;

  // Add benchmarks
  std::vector<benchmark::internal::Benchmark *> benchmarks;
  // add_sort_keys_benchmarks(benchmarks, stream, size);
  add_sort_pairs_benchmarks(benchmarks, stream, size);

  // Use manual timing
  for (auto &b : benchmarks) {
    b->UseManualTime();
    b->Unit(benchmark::kMillisecond);
  }

  // Force number of iterations
  if (trials > 0) {
    for (auto &b : benchmarks) {
      b->Iterations(trials);
    }
  }

  // Run benchmarks
  benchmark::RunSpecifiedBenchmarks();
  return 0;
}
