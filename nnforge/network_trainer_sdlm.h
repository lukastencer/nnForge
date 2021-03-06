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

#pragma once

#include "network_trainer.h"
#include "hessian_calculator.h"
#include "network_updater.h"

#include <vector>
#include <string>

// http://yann.lecun.com/exdb/lenet/index.html Y. LeCun, L. Bottou, Y. Bengio, and P. Haffner. "Gradient-based learning applied to document recognition"
// http://yann.lecun.com/exdb/publis/pdf/lecun-98b.pdf Y. LeCun, L. Bottou, G. Orr, and K. Muller, "Efficient BackProp"
namespace nnforge
{
	// Stochastic Diagonal Levenberg Marquardt
	class network_trainer_sdlm : public network_trainer
	{
	public:
		network_trainer_sdlm(
			network_schema_smart_ptr schema,
			hessian_calculator_smart_ptr hessian_calc,
			network_updater_smart_ptr updater);

		virtual ~network_trainer_sdlm();

		float hessian_entry_to_process_ratio;
		float max_mu;
		float mu_increase_factor;
		float speed;
		float eta_degradation;

	protected:
		// The method should add testing result to the training history of each element
		virtual void train_step(
			supervised_data_reader& reader,
			std::vector<training_task_state>& task_list);

		virtual void initialize_train(supervised_data_reader& reader);

		virtual unsigned int get_max_batch_size() const;

	private:
		class hessian_transform
		{
		public:
			hessian_transform(float mu, float eta);
			
			float operator() (float in);

		private:
			float mu;
			float eta;
		};

		static const unsigned int min_hessian_entry_to_process_count;

		hessian_calculator_smart_ptr hessian_calc;
		network_updater_smart_ptr updater;

		float get_mu(
			network_data_smart_ptr hessian,
			const std::vector<testing_result_smart_ptr>& history,
			std::vector<std::vector<float> >& original_mu_list) const;

		float get_eta(
			float mu,
			const std::vector<testing_result_smart_ptr>& history) const;

		void convert_hessian_to_training_vector(
			network_data_smart_ptr hessian,
			float mu,
			float eta) const;

		std::string convert_hessian_to_training_vector(
			network_data_smart_ptr hessian,
			const std::vector<testing_result_smart_ptr>& history) const;
	};
}
