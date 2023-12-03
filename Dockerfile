# see https://hub.docker.com/r/nvidia/cuda/tags?page=1&name=cudnn8-devel-ubuntu22.0
FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04 AS base

ARG DEBIAN_FRONTEND=noninteractive
ENV DEB_PYTHON_INSTALL_LAYOUT=deb_system
RUN apt-get update && \
    # Upgrade system
    apt-get full-upgrade -y && \
    # Local Timezone: Berlin
    apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    # Tesseract
    apt-get install -y packagekit software-properties-common && \
    add-apt-repository -y ppa:alex-p/tesseract-ocr5 && \
    apt-get update && \
    apt-get install -y libgl1-mesa-glx tesseract-ocr-eng tesseract-ocr-deu tesseract-ocr-por tesseract-ocr-spa tesseract-ocr-rus tesseract-ocr-fra libtesseract-dev libleptonica-dev pkg-config && \
    # Ghostscript
    apt-get install -y ghostscript && \
    # Other stuff
    apt-get install -y libmagic1 && \
    # Curl, Git, Python & Pip
    apt-get install -y curl git python3-pip && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Update Pip & install Poetry
ENV POETRY_VIRTUALENVS_CREATE=false
RUN pip install --upgrade pip setuptools poetry && \
    poetry config installer.max-workers 10

WORKDIR /opt/marker
COPY pyproject.toml poetry.lock README.md ./
COPY marker ./marker

EXPOSE 8200

FROM base AS dev
RUN poetry install --with dev

FROM base AS local
COPY LICENSE .
RUN poetry build && \
    poetry install dist/marker-0.1.0-py3-none-any.whl
# VOLUME /opt/marker/data
CMD ["uvicorn", "marker.service:app", "--host", "0.0.0.0", "--port", "8200", "--log-level", "warning"]
HEALTHCHECK --interval=5s --timeout=5s --retries=5 CMD curl --include --request GET http://localhost:8200/health || exit 1
