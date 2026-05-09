FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf automake autotools-dev bc bison build-essential ca-certificates \
    ccache cmake curl file flex gawk gperf git libexpat1-dev libglib2.0-dev \
    libgmp-dev libmpc-dev libmpfr-dev libpixman-1-dev libslirp-dev libssl-dev \
    libtool meson ninja-build patchutils pkg-config python3 rsync texinfo time \
    unzip wget xz-utils zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

ARG USER=builder
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} ${USER} \
  && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER}

ENV WORK=/work/ndsrvp-opencv-pr28915
ENV RISCV=/work/ndsrvp-opencv-pr28915/opt/andes
ENV PATH=/work/ndsrvp-opencv-pr28915/opt/andes/bin:${PATH}

RUN mkdir -p /opt/ndsrvp-scripts /work && chown -R ${USER}:${USER} /work /opt/ndsrvp-scripts
COPY --chown=${USER}:${USER} build-toolchain.sh build-opencv.sh run-imgproc-qemu.sh \
  /opt/ndsrvp-scripts/
COPY --chown=${USER}:${USER} patches /opt/ndsrvp-scripts/patches
RUN chmod +x /opt/ndsrvp-scripts/*.sh

USER ${USER}
WORKDIR /work

CMD ["/bin/bash"]
