FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    adb \
    sudo \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add the official Cuttlefish apt repository from Google Artifact Registry
RUN curl -fsSL https://us-apt.pkg.dev/doc/repo-signing-key.gpg | apt-key add - && \
    echo "deb https://us-apt.pkg.dev/projects/android-cuttlefish-artifacts android-cuttlefish main" \
    > /etc/apt/sources.list.d/cuttlefish.list

# Install Cuttlefish packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuttlefish-base \
    cuttlefish-user \
    && rm -rf /var/lib/apt/lists/*

# Verify installation
RUN echo "=== Checking installations ===" && \
    which launch_cvd && echo "launch_cvd found at $(which launch_cvd)" || echo "launch_cvd not found" && \
    which cvd && echo "cvd found at $(which cvd)" || echo "cvd not found" && \
    dpkg -l | grep -i cuttlefish

# Create user and add to required groups
RUN useradd -m -s /bin/bash vsoc-01 && \
    usermod -aG kvm vsoc-01 2>/dev/null || true && \
    usermod -aG cvdnetwork vsoc-01 2>/dev/null || true

# Create directories
RUN mkdir -p /home/vsoc-01/android && \
    mkdir -p /home/vsoc-01/cuttlefish_runtime && \
    chown -R vsoc-01:vsoc-01 /home/vsoc-01

WORKDIR /home/vsoc-01

EXPOSE 8443 6520 6444 15550

COPY start-cuttlefish.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-cuttlefish.sh

USER vsoc-01
ENTRYPOINT ["/usr/local/bin/start-cuttlefish.sh"]
