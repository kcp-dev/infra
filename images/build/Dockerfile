ARG GO_VERSION

FROM docker.io/library/golang:${GO_VERSION} as download

# this needs to be separate from the GO_VERSION arg above because otherwise
# it is not in scope for usage in the RUN instructions below.
ARG K8S_VERSION

WORKDIR /tmp

RUN curl --fail -Lo kubectl https://dl.k8s.io/release/v${K8S_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    ./kubectl version --short --client

FROM docker.io/library/golang:${GO_VERSION}

COPY --from=download /tmp/kubectl /usr/local/bin/

RUN apt-get update && \
    apt-get install -y \
        git \
        curl \
    && rm -rf /var/lib/apt/lists/*

