FROM rocker/r-ver:4.3.2

# Sistem asılılıqları
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# R paketləri
RUN R -e "install.packages(c('shiny','shinydashboard','DT','httr','jsonlite','plotly'), repos='https://cloud.r-project.org')"

# Binder tələbləri - istifadəçi
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER=${NB_USER} HOME=/home/${NB_USER}

RUN useradd -m -s /bin/bash -u ${NB_UID} ${NB_USER} || true

# App kopyala
COPY --chown=${NB_USER}:${NB_USER} r_shiny/app/ ${HOME}/app/

USER ${NB_USER}
WORKDIR ${HOME}

EXPOSE 8888

CMD ["R", "-e", "shiny::runApp('app/', host='0.0.0.0', port=8888)"]
