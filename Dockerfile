# llama.cpp SYCL — Intel iGPU
# Based on: github.com/ggml-org/llama.cpp/.devops/intel.Dockerfile

ARG ONEAPI_VERSION=2025.2.2-0-devel-ubuntu24.04

# Build
FROM intel/deep-learning-essentials:${ONEAPI_VERSION} AS build

ARG LLAMA_CPP_COMMIT=34ba7b5a
ARG GGML_SYCL_F16=OFF

RUN apt-get update && \
    apt-get install -y --no-install-recommends git libssl-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone https://github.com/ggml-org/llama.cpp.git . && \
    git checkout ${LLAMA_CPP_COMMIT}

RUN cmake -B build \
    -DGGML_SYCL=ON \
    -DCMAKE_C_COMPILER=icx \
    -DCMAKE_CXX_COMPILER=icpx \
    -DGGML_NATIVE=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DGGML_SYCL_F16=${GGML_SYCL_F16} && \
    cmake --build build --config Release -j$(nproc)

RUN mkdir -p /app/bin && \
    cp build/bin/llama-server /app/bin/ && \
    cp build/bin/llama-cli    /app/bin/

# Runtime
FROM intel/deep-learning-essentials:${ONEAPI_VERSION} AS runtime

LABEL org.opencontainers.image.title="llama-cpp-sycl" \
    org.opencontainers.image.description="llama.cpp with SYCL backend for Intel iGPUs" \
    org.opencontainers.image.source="https://github.com/richardvenneman/llama-cpp-sycl"

RUN apt-get update && \
    apt-get install -y --no-install-recommends libgomp1 curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r llama && \
    useradd -r -g llama -d /home/llama -m -s /bin/bash llama

COPY --from=build /app/bin/llama-server /usr/local/bin/
COPY --from=build /app/bin/llama-cli    /usr/local/bin/
ENV ZES_ENABLE_SYSMAN=1

RUN mkdir -p /models && chown llama:llama /models
VOLUME /models

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER llama
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["curl", "-sf", "http://localhost:8080/health"]

ENTRYPOINT ["entrypoint.sh"]
