FROM docker.io/library/golang:1.19.9 as download

WORKDIR /tmp
ENV KUBECTL_VERSION="v1.26.3"

RUN curl --fail -Lo kubectl https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    ./kubectl version --short --client

FROM docker.io/library/golang:1.19.9

COPY --from=download /tmp/kubectl /usr/local/bin/

RUN apt-get update && \
    apt-get install -y \
        git \
        curl \
    && rm -rf /var/lib/apt/lists/*

