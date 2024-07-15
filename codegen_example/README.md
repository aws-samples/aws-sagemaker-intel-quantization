# Deploy optimized LLM model with Intel® Extension for PyTorch (IPEX) and Torchserve on AWS Sagemaker

## Description
This sample provide code to deploy a LLM model with Intel® Extension for PyTorch (IPEX) with Torchserve on AWS Sagemaker on instances supporting 4th Gen Intel® Xeon® Scalable Processors. The notebook provided builds a Docker container, pushes it to AWS ECR, creates a torchserve file and puts in on AWS S3 bucket and creates and invokes an AWS Sagemaker endpoint. The pipeline was tested on [Codegen model](https://huggingface.co/Salesforce/codegen25-7b-multi_P).

## Execution
In order to run the example on your AWS Sagemaker account, check out following tutorial on how to set up notebook instance with a Git repository: [Associate Git Repositories with SageMaker Notebook Instances](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-git-repo.html).

Please refer to [E2E-LLM-Sagemaker-IPEX.ipynb](E2E-LLM-Sagemaker-IPEX.ipynb) for more information. Remember, modify [model/model-config.yaml](model/model-config.yaml) and put `model_name` of a model you'd like to run, e.g. `Salesforce/codegen25-7b-multi`.

## Human Rights Disclaimer
Intel is committed to respecting human rights and avoiding causing or directly contributing to adverse impacts on human rights. See [Intel's Global Human Rights Policy](https://www.intel.com/content/www/us/en/policy/policy-human-rights.html "Intel's Global Human Rights Policy"). The software licensed from Intel is intended for socially responsible applications and should not be used to cause or contribute to a violation of internationally recognized human rights.

&copy;Intel Corporation
