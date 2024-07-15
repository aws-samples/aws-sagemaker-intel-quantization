# Running Bert Flask with Intel optimizations on AWS Sagemaker

### Overview

This example demonstrates the deployment of a BERT (Bidirectional Encoder Representations from Transformers) model using Flask on AWS SageMaker with leveraging Intel based optimizations to enhance inference performance and efficiency.

<span style="color:red"> **Attention:** </span> BF16 is only supported on C7i instances with 4th Gen Intel® Xeon® Scalable Processors.

### Prerequisites

1. Launch an EC2 instance with C6i instance type and Ubuntu 20.04 Linux AMI.
2. SSH into the EC2 C6i/C7i instance. Remember to later initialize Sagemaker endpoint with same instance type. (All subsequent steps are to be executed from within the EC2 instance.)
3. Git clone the SageMaker samples repository.
   ```bash
   git clone https://github.com/aws-samples/amazon-sagemaker-custom-container.git 
   ```
4. Install Docker. (Refer to AWS CLI documentation for ECR and Docker usage [here](https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html))
   ```bash
   sudo apt install docker.io 
   ```
5. Install AWS CLI.
   ```bash
   sudo apt install awscli 
   ```
6. Set following environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID=<your ACCESS KEY>
   export AWS_SECRET_ACCESS_KEY=<your SECRET ACCESS KEY>
   ```

### Instructions

1. Execute the command to create the Docker image that will handle quantization and model generation, pushing it to ECR.
   ```bash
   bash build_and_push.sh bert_intel
   ```
2. Run the Docker image and execute the following command:
   ```bash
   sudo docker run --rm -it -p 8080:8080 -p 8081:8081 -p 8082:8082 -p 7070:7070 -p 7071:7071 -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY bert_intel
   ```
3. Inside the Docker container, run the provided Python script to generate both FP32, BF16 and INT8 models. (This process may vary in duration based on the C6i/C7i instance size). <span style="color:red"> **Attention:** </span> BF16 is only supported on C7i instances with 4th Gen Intel® Xeon® Scalable Processors.
   ```bash
   python quantize_with_ds_ep.py 
   ```
4. The Python script generates model artifacts required for the SageMaker endpoint. This step involves creating and uploading the model tar gzip file to an AWS S3 bucket.
   ```bash
   tar -czf bert_intel_model.tar.gz model_int8.pt model_bf16.pt model_fp32.pt tokenizer.json vocab.txt special_tokens_map.json tokenizer_config.json

   aws s3 cp bert_intel_model.tar.gz s3://<s3 bucket name>/
   ```
5. Exit the container.

### Create SageMaker model and endpoint
1. Register the model in Sagemaker: 
```bash
aws sagemaker create-model --model-name bert-intel-inference --execution-role-arn "<your role name>" --primary-container '{
  "ContainerHostname": "BertMainContainer1Hostname",
  "Image": "<you ACCOUNT ID>.dkr.ecr.<your REGION>.amazonaws.com/bert_intel:latest",
  "ModelDataUrl": "https://<s3 bucket name>.s3.amazonaws.com/bert_intel_model.tar.gz",
  "Environment" : {
         "SAGEMAKER_CONTAINER_LOG_LEVEL": "20",
         "SAGEMAKER_REGION": "<your REGION>"
         }
 }'

aws sagemaker create-model --model-name bert-intel-inference --execution-role-arn "arn:aws:iam::205130860845:role/sagemaker_fullaccess" --primary-container '{
  "ContainerHostname": "BertMainContainer1Hostname",
  "Image": "205130860845.dkr.ecr.us-west-2.amazonaws.com/bert_intel:latest",
  "ModelDataUrl": "https://intel-sagemaker.s3.us-west-2.amazonaws.com/bert_intel_model.tar.gz",
  "Environment" : {
         "SAGEMAKER_CONTAINER_LOG_LEVEL": "20",
         "SAGEMAKER_REGION": "us-west-2"
         }
 }'
``` 
2. Register the inference endpoint configuration for the endpoint referencing the model name and ec2 instance class. Remember to pick correct instance type (C6i instances doesn't support BF16)
```bash
aws sagemaker create-endpoint-config --endpoint-config-name bert-intel-inference --production-variants '[
{
  "VariantName" : "TestVariant1",
  "ModelName" : "bert-intel-inference",
  "InitialInstanceCount" : 1,
  "InstanceType" : "ml.c6i.4xlarge"
 }
]'
```
3. Register the endpoint referencing the endpoint config name.
```bash
aws sagemaker create-endpoint --endpoint-name bert-intel-inference-2 --endpoint-config-name bert-intel-inference
```
4. Check the status of the endpoint to confirm that it is InService. 
5. To test the FP32 model, execute the following script:
` python src/invoke-FP32.py `
6. To test the BF16 model, execute the following script:
` python src/invoke-BF16.py `
7. To test the INT8 model, execute the following script:
` python src/invoke-INT8.py `
8. Validate the response and check the answer.
 
Remember to shutdown and cleanup the AWS services and artifacts created as part of this exercise.
Make sure that you save any code or artifacts that you may want for future reference, before you run the cleanup steps. 

### Steps for cleanup
1. Run the following commands to delete the SageMaker model and endpoint. 
``` 
aws sagemaker delete-endpoint --endpoint-name bert-intel-inference
aws sagemaker delete-endpoint-config --endpoint-config-name bert-intel-inference
aws sagemaker delete-model --model-name bert-intel-inference
```
2. Delete the S3 objects created during this exercise.
3. Delete the IAM roles and policies created during this exercise.
4. Delete the docker image from ECR
```bash
aws ecr batch-delete-image \
      --repository-name bert_intel \
      --image-ids imageTag=latest \
      --region $REGION
```