#ifndef CML_UTILS_CUH_
#define CML_UTILS_CUH_

#include <cublas_v2.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/iterator/transform_iterator.h>
#include <thrust/iterator/permutation_iterator.h>

#include <cstdio>

#include "cml_defs.cuh"

#define CudaCheckError(val) __CudaCE((val), __func__, __FILE__, __LINE__)
#define CublasCheckError(val) __CublasCE((val), __func__, __FILE__, __LINE__)

namespace cml {

static const char* cublasGetErrorString(cublasStatus_t error);

template<typename T>
void __CudaCE(T err, const char* const func, const char* const file,
              const int line) {
  if (err != cudaSuccess) {
    fprintf(stderr, "CUDA error at: %s : %d\n", file, line);
    fprintf(stderr, "%s %s\n", cudaGetErrorString(err), func);
  }
}

template<typename T>
void __CublasCE(T err, const char* const func, const char* const file,
                const int line) {
  if (err != CUBLAS_STATUS_SUCCESS) {
    fprintf(stderr, "CUBLAS error at: %s : %d\n", file, line);
    fprintf(stderr, "%s %s\n", cublasGetErrorString(err), func);
  }
}

static const char* cublasGetErrorString(cublasStatus_t error) {
  switch (error) {
    case CUBLAS_STATUS_SUCCESS:
      return "CUBLAS_STATUS_SUCCESS";
    case CUBLAS_STATUS_NOT_INITIALIZED:
      return "CUBLAS_STATUS_NOT_INITIALIZED";
    case CUBLAS_STATUS_ALLOC_FAILED:
      return "CUBLAS_STATUS_ALLOC_FAILED";
    case CUBLAS_STATUS_INVALID_VALUE:
      return "CUBLAS_STATUS_INVALID_VALUE";
    case CUBLAS_STATUS_ARCH_MISMATCH:
      return "CUBLAS_STATUS_ARCH_MISMATCH";
    case CUBLAS_STATUS_MAPPING_ERROR:
      return "CUBLAS_STATUS_MAPPING_ERROR";
    case CUBLAS_STATUS_EXECUTION_FAILED:
      return "CUBLAS_STATUS_EXECUTION_FAILED";
    case CUBLAS_STATUS_INTERNAL_ERROR:
      return "CUBLAS_STATUS_INTERNAL_ERROR";
    default:
      return "<unknown>";
  }
}

inline uint calc_grid_dim(size_t size, uint block_size) {
  return std::min<uint>((size + block_size - 1u) / block_size, kMaxGridSize);
}

// From thrust examples.
template <typename It>
class strided_range {
 public:
  typedef typename thrust::iterator_difference<It>::type diff_t;

  struct StrideF : public thrust::unary_function<diff_t, diff_t> {
    diff_t stride;
    StrideF(diff_t stride) : stride(stride) { }
    __host__ __device__
    diff_t operator()(const diff_t& i) const { 
      return stride * i;
    }
  };

  typedef typename thrust::counting_iterator<diff_t> CountingIt;
  typedef typename thrust::transform_iterator<StrideF, CountingIt> TransformIt;
  typedef typename thrust::permutation_iterator<It, TransformIt> PermutationIt;
  typedef PermutationIt strided_iterator_t;

  // Construct strided_range for the range [first,last).
  strided_range(It first, It last, diff_t stride)
      : first(first), last(last), stride(stride) { }
 
  strided_iterator_t begin() const {
    return PermutationIt(first, TransformIt(CountingIt(0), StrideF(stride)));
  }

  strided_iterator_t end() const {
    return begin() + ((last - first) + (stride - 1)) / stride;
  }
  
 protected:
  It first;
  It last;
  diff_t stride;
};

}  // namespace

#endif  // CML_UTILS_CUH_

