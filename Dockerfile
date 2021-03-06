FROM dynainstrumentsoss/build-env:centos7

LABEL maintainer="linuxer (at) quantentunnel.de"

# create a non-root user (ptxdist refuses to run as root) and create the home tree
RUN useradd -m -U -s /bin/bash -u 4000 ptxdist && chgrp ptxdist /opt && chmod g+w /opt
USER ptxdist
WORKDIR /home/ptxdist
RUN \
    mkdir -p /home/ptxdist/{build,bin,lib,distfiles,.ptxdist} \
 && echo -e 'test -n "$http_proxy" && test -n "$https_proxy" || export https_proxy="$http_proxy"' >>/home/ptxdist/.bashrc \
 && echo -e 'test -n "$http_proxy" && test -n "$ftp_proxy" || export ftp_proxy="$http_proxy"' >>/home/ptxdist/.bashrc \
 && true

# configure ptxdist with DYNA defaults
COPY dot_ptxdist /home/ptxdist/.ptxdist/

# the build tree shall not be part of the image
VOLUME /home/ptxdist/build

# the normal distfiles storage shall not be part of the image
VOLUME /home/ptxdist/distfiles

# correct the ownership
USER root
RUN chown -R ptxdist:ptxdist /home/ptxdist

# build the tool chain (gcc & co) relying on an older ptxdist
RUN su - ptxdist -c "\
    export http_proxy=$http_proxy; \
    export https_proxy=$http_proxy; \
    export ftp_proxy=$http_proxy; \
    cd /home/ptxdist/distfiles \
 && test -f ptxdist-2016.06.1.tar.bz2.md5 \
 || wget http://public.pengutronix.de/software/ptxdist/ptxdist-2016.06.1.tar.bz2.md5 \
 && test -f ptxdist-2016.06.1.tar.bz2 \
 || wget http://public.pengutronix.de/software/ptxdist/ptxdist-2016.06.1.tar.bz2 \
 && md5sum -c ptxdist-2016.06.1.tar.bz2.md5 \
 && test -f OSELAS.Toolchain-2016.06.1.tar.bz2.md5 \
 || wget http://public.pengutronix.de/oselas/toolchain/OSELAS.Toolchain-2016.06.1.tar.bz2.md5 \
 && test -f OSELAS.Toolchain-2016.06.1.tar.bz2 \
 || wget http://public.pengutronix.de/oselas/toolchain/OSELAS.Toolchain-2016.06.1.tar.bz2 \
 && md5sum -c OSELAS.Toolchain-2016.06.1.tar.bz2.md5 \
 && tar -axf ptxdist-2016.06.1.tar.bz2 -C /home/ptxdist/build \
 && cd /home/ptxdist/build/ptxdist-2016.06.1 \
 && ./configure --prefix=/home/ptxdist --without-bash-completion \
 && make -j$(( $(/usr/bin/getconf _NPROCESSORS_ONLN) * 2)) \
 && make install \
 && cd /home/ptxdist/distfiles \
 && tar -axf OSELAS.Toolchain-2016.06.1.tar.bz2 -C /home/ptxdist/build \
 && cd /home/ptxdist/build/OSELAS.Toolchain-2016.06.1 \
 && /home/ptxdist/bin/ptxdist select ptxconfigs/arm-v5te-linux-gnueabi_gcc-5.4.0_glibc-2.23_binutils-2.26_kernel-4.6-sanitized.ptxconfig \
 && /home/ptxdist/bin/ptxdist oldconfig \
 && /home/ptxdist/bin/ptxdist go \
 && chmod -R a-w /opt/OSELAS.Toolchain-2016.06.1 \
 && cd /home/ptxdist/build \
 && rm -rf ptxdist-2016.06.1 OSELAS.Toolchain-2016.06.1 \
"

# build our primary ptxdist
RUN su - ptxdist -c "\
    export http_proxy=$http_proxy; \
    export https_proxy=$http_proxy; \
    export ftp_proxy=$http_proxy; \
    cd /home/ptxdist/distfiles \
 && test -f ptxdist-2017.09.0.tar.bz2.md5 \
 || wget http://public.pengutronix.de/software/ptxdist/ptxdist-2017.09.0.tar.bz2.md5 \
 && test -f ptxdist-2017.09.0.tar.bz2 \
 || wget http://public.pengutronix.de/software/ptxdist/ptxdist-2017.09.0.tar.bz2 \
 && md5sum -c ptxdist-2017.09.0.tar.bz2.md5 \
 && tar -axf ptxdist-2017.09.0.tar.bz2 -C /home/ptxdist/build \
 && cd /home/ptxdist/build/ptxdist-2017.09.0 \
 && ./configure --prefix=/home/ptxdist --without-bash-completion \
 && make -j$(( $(/usr/bin/getconf _NPROCESSORS_ONLN) * 2)) \
 && make install \
 && cd /home/ptxdist/build \
 && rm -rf ptxdist-2017.09.0 \
"

USER ptxdist
CMD /bin/bash -il
