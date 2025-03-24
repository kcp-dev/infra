ARG GO_VERSION

FROM --platform=${BUILDPLATFORM} docker.io/library/golang:${GO_VERSION} as download

    # the Kubernetes version that is used to determine which kubectl to install.
ENV KUBECTL_VERSION=1.32.3 \
    # the kind version installed into this image.
    # https://github.com/kubernetes-sigs/kind/releases
    KIND_VERSION=0.27.0 \
    # the Helm version installed into this image.
    # https://github.com/helm/helm/releases
    HELM_VERSION=3.17.2 \
    # the kubeconform version installed into this image.
    # https://github.com/yannh/kubeconform/releases
    KUBECONFORM_VERSION=0.6.7

WORKDIR /tmp

RUN curl --fail -L https://get.helm.sh/helm-v${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz | tar -xzO linux-$(dpkg --print-architecture)/helm > helm && \
    chmod +x helm && \
    ./helm version --short

RUN curl --fail -Lo kubectl https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl && \
    chmod +x kubectl && \
    ./kubectl version --client

RUN curl --fail -Lo kind https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-$(dpkg --print-architecture) && \
    chmod +x kind && \
    ./kind version

RUN curl --fail -L https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-$(dpkg --print-architecture).tar.gz | tar -xzO kubeconform > kubeconform && \
    chmod +x kubeconform && \
    ./kubeconform -v

FROM docker.io/library/golang:${GO_VERSION}

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
    apt-get install -y --no-install-recommends docker-ce=5:27.3.* socat && \
    sed -i 's/cgroupfs_mount$/#cgroupfs_mount\n/' /etc/init.d/docker && \
    sed -i 's/ulimit -Hn/#ulimit -Hn/g' /etc/init.d/docker && \
    mkdir -p /etc/docker && \
    echo '{"data-root":"/docker-graph"}' | jq '.' > /etc/docker/daemon.json && \
    rm -rf /var/lib/apt/lists/*
