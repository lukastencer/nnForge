/*
 *  Copyright 2011-2013 Maxim Milakov
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include "rectified_linear_layer_hessian_cuda.h"

#include <cuda_runtime.h>

#include "util_cuda.h"

__global__ void rectified_linear_hess_kernel(
	const float4 * __restrict input,
	float4 * __restrict output,
	int elem_count)
{
	int elem_id = blockDim.x * (blockIdx.y * gridDim.x + blockIdx.x) + threadIdx.x;
	if (elem_id < elem_count)
	{
		float4 val = input[elem_id];
		val.x = max(0.0F, val.x);
		val.y = max(0.0F, val.y);
		val.z = max(0.0F, val.z);
		val.w = max(0.0F, val.w);
		output[elem_id] = val;
	}
}

__global__ void rectified_linear_square_deriviative_hess_kernel(
	float4 * __restrict errors,
	const float4 * __restrict output_neurons,
	int elem_count)
{
	int elem_id = blockDim.x * (blockIdx.y * gridDim.x + blockIdx.x) + threadIdx.x;
	if (elem_id < elem_count)
	{
		float4 val = output_neurons[elem_id];
		float4 current_error = errors[elem_id];
		if (val.x == 0.0F)
			current_error.x = 0.0F;
		if (val.y == 0.0F)
			current_error.y = 0.0F;
		if (val.z == 0.0F)
			current_error.z = 0.0F;
		if (val.w == 0.0F)
			current_error.w = 0.0F;
		errors[elem_id] = current_error;
	}
}

namespace nnforge
{
	namespace cuda
	{
		rectified_linear_layer_hessian_cuda::rectified_linear_layer_hessian_cuda()
		{
		}

		rectified_linear_layer_hessian_cuda::~rectified_linear_layer_hessian_cuda()
		{
		}

		void rectified_linear_layer_hessian_cuda::enqueue_test(
			cudaStream_t stream_id,
			const std::vector<const_cuda_linear_buffer_device_smart_ptr>& schema_data,
			const std::vector<const_cuda_linear_buffer_device_smart_ptr>& data,
			const_cuda_linear_buffer_device_smart_ptr input_neurons_buffer,
			cuda_linear_buffer_device_smart_ptr output_neurons_buffer,
			const std::vector<cuda_linear_buffer_device_smart_ptr>& additional_buffers,
			unsigned int entry_count)
		{
			int elem_count = (input_elem_count_per_entry * entry_count + 3) / 4;
			std::pair<dim3, dim3> kernel_dims = cuda_util::get_grid_and_threadblock_sizes_sequential_access(
				*cuda_config,
				elem_count);
			rectified_linear_hess_kernel<<<kernel_dims.first, kernel_dims.second, 0, stream_id>>>(
				*input_neurons_buffer,
				*output_neurons_buffer,
				elem_count);
		}

		void rectified_linear_layer_hessian_cuda::enqueue_backprop(
			cudaStream_t stream_id,
			const std::vector<const_cuda_linear_buffer_device_smart_ptr>& schema_data,
			const std::vector<const_cuda_linear_buffer_device_smart_ptr>& data,
			const_cuda_linear_buffer_device_smart_ptr output_neurons_buffer,
			cuda_linear_buffer_device_smart_ptr output_errors_buffer,
			cuda_linear_buffer_device_smart_ptr input_errors_buffer,
			const std::vector<cuda_linear_buffer_device_smart_ptr>& additional_buffers,
			unsigned int entry_count)
		{
			int elem_count = (input_elem_count_per_entry * entry_count + 3) / 4;
			std::pair<dim3, dim3> kernel_dims = cuda_util::get_grid_and_threadblock_sizes_sequential_access(
				*cuda_config,
				elem_count);
			rectified_linear_square_deriviative_hess_kernel<<<kernel_dims.first, kernel_dims.second, 0, stream_id>>>(
				*output_errors_buffer,
				*output_neurons_buffer,
				elem_count);
		}

		bool rectified_linear_layer_hessian_cuda::is_in_place_backprop() const
		{
			return true;
		}
	}
}
