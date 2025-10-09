ARG GO_VERSION

FROM --platform=${TARGETPLATFORM} docker.io/library/golang:${GO_VERSION} as download

    # the Kubernetes version that is used to determine which kubectl to install.
ENV KUBECTL_VERSION=1.32.7 \
    # the kind version installed into this image.
    # https://github.com/kubernetes-sigs/kind/releases
    KIND_VERSION=0.30.0 \
    # the Helm version installed into this image.
    # https://github.com/helm/helm/releases
    HELM_VERSION=3.18.5 \
    # the kubeconform version installed into this image.
    # https://github.com/yannh/kubeconform/releases
    KUBECONFORM_VERSION=0.7.0

WORKDIR /tmp

# Do not _run_ these tools during build because when emulating with qemu,
# running them will fail: https://github.com/golang/go/issues/69255

RUN curl --fail -L https://get.helm.sh/helm-v${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz | tar -xzO linux-$(dpkg --print-architecture)/helm > helm && \
    chmod +x helm

RUN curl --fail -Lo kubectl https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl && \
    chmod +x kubectl

RUN curl --fail -Lo kind https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-$(dpkg --print-architecture) && \
    chmod +x kind

RUN curl --fail -L https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-$(dpkg --print-architecture).tar.gz | tar -xzO kubeconform > kubeconform && \
    chmod +x kubeconform

FROM --platform=${TARGETPLATFORM} docker.io/library/golang:${GO_VERSION}

# this is used by docker as data root
VOLUME /docker-graph

COPY --from=download /tmp/kubectl /usr/local/bin/
COPY --from=download /tmp/kind /usr/local/bin/
COPY --from=download /tmp/helm /usr/local/bin/
COPY --from=download /tmp/kubeconform /usr/local/bin/

COPY start-docker.sh /usr/local/bin/
# this pre-loads the kindest/node image so it can be loaded via docker
# when starting a container based on this image
COPY kindest.tar /kindest.tar

RUN apt-get update && \
    apt-get install -y \
        git \
        curl \
        jq \
        buildah \
    && rm -rf /var/lib/apt/lists/*

# install Docker (and socat for tunneling the docker registry later)
RUN curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | gpg --dearmor > /usr/share/keyrings/docker.com.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.com.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce=5:28.5.* socat && \
    sed -i 's/cgroupfs_mount$/#cgroupfs_mount\n/' /etc/init.d/docker && \
    sed -i 's/ulimit -Hn/#ulimit -Hn/g' /etc/init.d/docker && \
    mkdir -p /etc/docker && \
    echo '{"data-root":"/docker-graph"}' | jq '.' > /etc/docker/daemon.json && \
    rm -rf /var/lib/apt/lists/*
