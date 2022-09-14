ARG ROOT_CONTAINER=nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

FROM  $ROOT_CONTAINER

ARG USER_NAME="ubuntu"

ENV \
    CONDA_DIR="/opt/conda" \
    DEBIAN_FRONTEND="noninteractive"  \
    DISPLAY=":1" \
    USER_GID="100" \
    SHELL="/bin/bash" \
    TERM="xterm" 

USER root

RUN \
    apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    apt-utils \
    build-essential \
    bzip2 \
    ca-certificates \
    cmake \
    curl \
    fonts-liberation \
    git \
    git-extras \
    git-flow \
    libjpeg-dev \
    libpng-dev \
    locales \
    openssh-client \
    openssh-server \
    pandoc \
    sudo \
    tini \
    vim \
    wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    apt-get clean

ENV \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8"

ENV \
    PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${USER_NAME}"

COPY fix-permissions.sh start.sh /usr/local/bin/
RUN chmod a+rx /usr/local/bin/fix-permissions.sh && chmod a+rx /usr/local/bin/start.sh

# Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
RUN \
    sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
    echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# Create USER_NAME with name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s "/bin/bash" -N "${USER_NAME}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${USER_NAME}:${USER_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    fix-permissions.sh "${HOME}" && \
    fix-permissions.sh "${CONDA_DIR}"

RUN echo "${USER_NAME} ALL=NOPASSWD: ALL" >> /etc/sudoers

ARG PASSWORD="P@ssw0rd1"
RUN echo "${USER_NAME}:${PASSWORD}" | chpasswd

RUN env > /etc/environment

USER ${USER_NAME}

# Pin python version here, or set it to "default"
ARG PYTHON_VERSION=3.8

COPY --chown="${USER_NAME}:${USER_GID}" initial-condarc "${CONDA_DIR}/.condarc"

WORKDIR /tmp

RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        arch="64"; \
    fi && \
    wget -qO /tmp/micromamba.tar.bz2 \
        "https://micromamba.snakepit.net/api/micromamba/linux-${arch}/latest" && \
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2 && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    # Install the packages
    ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        "${PYTHON_SPECIFIER}" \
        'mamba' \
        'notebook' \
        'jupyterhub' \
        'jupyterlab'  && \
    rm micromamba && \
    # Pin major.minor version of python
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    mamba clean --all -f -y && \
    rm -rf "/home/${USER_NAME}/.cache/yarn" && \
    fix-permissions.sh "${CONDA_DIR}" && \
    fix-permissions.sh "/home/${USER_NAME}"

RUN mamba install --quiet --yes -c pytorch \
    'pytorch' \
    'torchvision' \
    'torchaudio'  \
    'cudatoolkit=11.3' && \
    mamba clean --all -f -y && \
    fix-permissions.sh "${CONDA_DIR}" && \
    fix-permissions.sh "/home/${USER_NAME}"

RUN mamba install --quiet --yes \
    'transformers' \
    'accelerate' \
    'diffusers' && \
    mamba clean --all -f -y && \
    fix-permissions.sh "${CONDA_DIR}" && \
    fix-permissions.sh "/home/${USER_NAME}"

EXPOSE 8888

WORKDIR "${HOME}"
RUN sudo mkdir -p /run/sshd
RUN sudo ssh-keygen -A

ENTRYPOINT ["tini", "-g", "--"]

CMD ["start.sh"]