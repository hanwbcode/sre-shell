FROM debian:trixie
# python:3.14-trixie

ENV TZ=Asia/Shanghai

WORKDIR /opt

# Install base tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    tzdata \
    curl \
    gpg \
    apt-transport-https \
    ca-certificates \
    unzip \
    less \
    groff-base \
    pigz \
    zstd && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Database Backup & Client Tools (MySQL & PostgreSQL)
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /usr/share/keyrings/postgresql.gpg > /dev/null && \
    . /etc/os-release && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    default-mysql-client \
    mydumper \
    postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mysqldump --version && \
    mydumper --version && \
    pg_dump --version

# Install kubectl
RUN ARCH=$(dpkg --print-architecture) && \
    curl -LO --fail "https://dl.k8s.io/release/$(curl -L -s --fail https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    kubectl version --client && \
    rm -f /opt/kubectl

# Install Helm
RUN curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends helm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    helm version

# Install AWS CLI v2 (AWS S3 CLI)
RUN ARCH=$(uname -m) && \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "awscliv2.zip" && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip && \
    aws --version

# Install Aliyun ossutil v2
RUN OSSUTIL_VERSION=$(curl -fsSL https://gosspublic.alicdn.com/ossutil/v2/version.txt | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') && \
    ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://gosspublic.alicdn.com/ossutil/v2/${OSSUTIL_VERSION}/ossutil-${OSSUTIL_VERSION}-linux-${ARCH}.zip" -o "ossutil.zip" && \
    unzip -q -j ossutil.zip "*/ossutil" -d /usr/local/bin/ && \
    chmod 755 /usr/local/bin/ossutil && \
    rm -f ossutil.zip && \
    ossutil version

CMD ["/bin/bash"]