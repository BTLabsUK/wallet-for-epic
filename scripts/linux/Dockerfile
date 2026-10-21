# Linux release build environment. Ubuntu 22.04 on purpose: a binary links against the glibc it is
# built with, so building on the oldest supported distro gives a build that starts on it and on
# every newer one. Never build Linux releases on the host. Driven by scripts/build-linux.sh.
FROM ubuntu:22.04

ARG FLUTTER_VERSION=3.47.5
ARG RUST_VERSION=1.99.0
ARG APPIMAGETOOL_URL=https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage
ARG APPIMAGETOOL_SHA256=ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
ARG RUNTIME_URL=https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64
ARG RUNTIME_SHA256=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils zip file \
      clang cmake ninja-build pkg-config build-essential \
      libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev \
      squashfs-tools desktop-file-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && git config --system --add safe.directory '*'

# Flutter SDK at the version the app pins. World-writable so the build can run as the host user.
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter \
    && /opt/flutter/bin/flutter config --no-analytics --enable-linux-desktop >/dev/null \
    && /opt/flutter/bin/flutter precache --linux \
    && chmod -R a+rwX /opt/flutter

# Rust: rustup with just the pinned toolchain (RUSTUP_TOOLCHAIN overrides the repo's
# rust-toolchain.toml so the Android/iOS targets are not downloaded). CARGO_HOME is a named volume.
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain ${RUST_VERSION} \
    && chmod -R a+rwX /opt/rustup /opt/cargo

# AppImage tooling: extracted, because a container has no FUSE. Pinned and checksummed.
RUN curl -fsSL -o /tmp/at ${APPIMAGETOOL_URL} && echo "${APPIMAGETOOL_SHA256}  /tmp/at" | sha256sum -c - \
    && chmod +x /tmp/at && cd /tmp && ./at --appimage-extract >/dev/null && mv squashfs-root /opt/appimagetool \
    && rm /tmp/at \
    && curl -fsSL -o /opt/runtime-x86_64 ${RUNTIME_URL} && echo "${RUNTIME_SHA256}  /opt/runtime-x86_64" | sha256sum -c -

ENV PATH=/opt/flutter/bin:/opt/cargo/bin:$PATH \
    RUSTUP_TOOLCHAIN=${RUST_VERSION} \
    PUB_CACHE=/cache/pub \
    HOME=/cache/home \
    FLUTTER_SUPPRESS_ANALYTICS=true CI=true
RUN mkdir -p /cache/pub /cache/home /work && chmod -R a+rwx /cache
WORKDIR /work
