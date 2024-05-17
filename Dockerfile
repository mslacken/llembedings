FROM registry.opensuse.org/opensuse/tumbleweed:latest as builder

RUN zypper ar --no-gpgcheck https://download.opensuse.org/repositories/home:/mslacken:/ml/openSUSE_Tumbleweed/home:mslacken:ml.repo && \
    zypper ref  && \
    zypper install -y python311-gpt4all python311-pypdf python311-faiss python311-langchain python311-orjson libopenblas_openmp0 && \
    update-alternatives --set libblas.so.3_x86_64 /usr/lib64/openblas-openmp/libopenblas.so.0 && \
    update-alternatives --set libcblas.so.3_x86_64 /usr/lib64/openblas-openmp/libopenblas.so.0 && \
    update-alternatives --set liblapack.so.3_x86_64 /usr/lib64/openblas-openmp/libopenblas.so.0

WORKDIR /build

COPY pdfs /build/pdfs
RUN mkdir -p /root/.cache/gpt4all
COPY all-MiniLM-L6-v2-f16.gguf /root/.cache/gpt4all/

COPY generate_index.py /build/
RUN python3 generate_index.py

FROM registry.opensuse.org/opensuse/tumbleweed:latest

RUN zypper ar --no-gpgcheck https://download.opensuse.org/repositories/home:/mslacken:/ml/openSUSE_Tumbleweed/home:mslacken:ml.repo && \
    zypper ref  && \
    zypper install -y python311-gpt4all python311-pypdf python311-faiss python311-langchain python311-Flask python311-orjson

COPY --from=builder /build/faiss .

COPY --from=builder /root/.cache/gpt4all/ /root/.cache/gpt4all/

RUN mkdir -p /models
COPY mistral-7b-openorca.gguf2.Q4_0.gguf /models/

COPY templates /templates
COPY main.py .

ENTRYPOINT [ "python3", "main.py" ]
