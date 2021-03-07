FROM rocker/tidyverse:4.0.3

RUN apt update && apt install -y python3-pip build-essential libssl-dev libffi-dev python3-dev libbz2-dev liblzma-dev tcl-dev tk-dev

ADD workflow/ /workflow

WORKDIR /workflow

RUN Rscript init.R \
    && pip3 install -r requirements.txt