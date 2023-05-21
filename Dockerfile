FROM ubuntu:focal

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get -qq update && apt-get -qq upgrade -y \
  && apt-get -qq install -y --no-install-recommends \
      apt xz-utils unzip avahi-utils dbus \
      xserver-xorg-core libgl1-mesa-glx libgl1-mesa-dri libglu1-mesa xfonts-base \
      x11-session-utils x11-utils x11-xfs-utils x11-xserver-utils xauth x11-common \
      libgtk2.0-bin libgtk-3-bin gnome-icon-theme \
      gosu sudo curl gcc-avr avr-libc srecord \
  && apt-get -qq autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV MPLABX_VERSION 6.00

# Download and install MPLAB X IDE
# Use url: http://www.microchip.com/mplabx-ide-linux-installer to get the latest version
RUN curl -fSL -A "Mozilla/4.0" -o /tmp/mplabx-installer.tar "http://ww1.microchip.com/downloads/en/DeviceDoc/MPLABX-v${MPLABX_VERSION}-linux-installer.tar" \
    && tar xf /tmp/mplabx-installer.tar && rm /tmp/mplabx-installer.tar \
    && USER=root ./MPLABX-v${MPLABX_VERSION}-linux-installer.sh --nox11 \
        -- --unattendedmodeui none --mode unattended \
    && rm ./MPLABX-v${MPLABX_VERSION}-linux-installer.sh

# Set up for the user we will create at runtime
RUN mkdir -p /home/mplabx && chmod -R 777 /home/mplabx \
  && echo 'mplabx ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers \
  && echo '%mplabx ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers \
  && echo 'Defaults env_keep += "DIST"' >>/etc/sudoers

# Set bash profile
RUN echo 'alias ll="ls -Fhl --color=auto"' >/etc/profile.d/bash_profile.sh && \
    echo 'alias la="ls -AFhl --color=auto"' >>/etc/profile.d/bash_profile.sh && \
    echo 'alias less="less -FSRXc"' >>/etc/profile.d/bash_profile.sh && \
    chmod +x /etc/profile.d/bash_profile.sh

# Generate user entrypoint script
RUN echo '#!/bin/bash' >/entrypoint.sh \
  && echo 'if [[ -n "${LOCAL_UID}" ]]; then' >>/entrypoint.sh \
  && echo '    LOCAL_GID=${LOCAL_GID:-${LOCAL_UID}}' >>/entrypoint.sh \
  && echo '    if ! grep -q mplabx /etc/group; then' >>/entrypoint.sh \
  && echo '        groupadd -o --gid="${LOCAL_GID}" mplabx' >>/entrypoint.sh \
  && echo '        useradd -o --uid="${LOCAL_UID}" --gid="${LOCAL_GID}" -s /bin/bash mplabx' >>/entrypoint.sh \
  && echo '    fi' >>/entrypoint.sh \
  && echo '    exec gosu mplabx "$@"' >>/entrypoint.sh \
  && echo 'fi' >>/entrypoint.sh \
  && echo 'exec "$@"' >>/entrypoint.sh \
  && chmod +x /entrypoint.sh

VOLUME /workspace
WORKDIR /workspace

CMD ["bash"]
ENTRYPOINT ["/entrypoint.sh"]
