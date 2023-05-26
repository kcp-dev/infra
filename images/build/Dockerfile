ARG GO_VERSION
ARG K8S_VERSION

FROM docker.io/library/golang:${GO_VERSION} as download

WORKDIR /tmp

RUN curl --fail -Lo kubectl https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    ./kubectl version --short --client

FROM docker.io/library/golang:${GO_VERSION}

COPY --from=download /tmp/kubectl /usr/local/bin/

RUN apt-get update && \
    apt-get install -y \
        git \
        curl \
    && rm -rf /var/lib/apt/lists/*

