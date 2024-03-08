# Build an image that can do inference in SageMaker
# This is a Python 2 image that uses the nginx, gunicorn, flask stack

FROM public.ecr.aws/lts/ubuntu:22.04_stable
# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8
ARG PYTHON=python3
		 
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" TZ="America/New_York" apt-get install -y tzdata

RUN apt-get -y update && apt-get install -y --no-install-recommends --fix-missing \
         wget \
         nginx \
         ca-certificates \
         build-essential \
         git \
         curl \
         ${PYTHON} \
         ${PYTHON}-pip \
         google-perftools \
         libjemalloc-dev \
         numactl &&\
         rm -rf /var/lib/apt/lists/*


RUN apt-get clean

ENV PYTHON_VERSION=3.10

RUN pip install ipykernel && \
    ${PYTHON} -m ipykernel install --sys-prefix

RUN ${PYTHON} -m pip --no-cache-dir install --upgrade \
    pip \
    psutil \
    setuptools \
    boto3 \
    sagemaker \
    transformers \
    datasets \
    awscli

# Some TF tools expect a "python" binary
RUN ln -s $(which ${PYTHON}) /usr/local/bin/python
ARG IPEX_VERSION=2.2.0
ARG PYTORCH_VERSION=2.2.0+cpu
ARG TORCHAUDIO_VERSION=2.2.0
ARG TORCHVISION_VERSION=0.17.0+cpu
ARG TORCH_CPU_URL=https://download.pytorch.org/whl/torch_stable.html

RUN ${PYTHON} -m pip install --upgrade pip --no-cache-dir \
    intel-openmp \
    torch==${PYTORCH_VERSION} torchvision==${TORCHVISION_VERSION} torchaudio==${TORCHAUDIO_VERSION} -f ${TORCH_CPU_URL} && \
    ${PYTHON} -m pip install --no-cache-dir \
    intel_extension_for_pytorch==${IPEX_VERSION}

RUN ln -sf /usr/lib/x86_64-linux-gnu/libjemalloc.so /usr/lib/x86_64-linux-gnu/libtcmalloc.so
ENV LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libjemalloc.so:/usr/local/lib/libiomp5.so:/usr/lib/x86_64-linux-gnu/libtcmalloc.so":${LD_PRELOAD}

# Here we install the extra python packages to run the inference code
RUN pip install flask gevent gunicorn && \
        rm -rf /root/.cache

# Set some environment variables. PYTHONUNBUFFERED keeps Python from buffering our standard
# output stream, which means that logs can be delivered to the user quickly. PYTHONDONTWRITEBYTECODE
# keeps Python from writing the .pyc files which are unnecessary in this case. We also update
# PATH so that the train and serve programs are found when the container is invoked.

ENV PYTHONUNBUFFERED=TRUE
ENV PYTHONDONTWRITEBYTECODE=TRUE
ENV PATH="/opt/program:${PATH}"
ENV SM_MODEL_DIR="/opt/program/model"

# Set up the program in the image
COPY bert_flask /opt/program

RUN chmod 755 /opt/program
WORKDIR /opt/program
RUN chmod 755 serve
ENV KMP_BLOCKTIME=1
ENV KMP_AFFINITY=granularity=fine,compact,1,0