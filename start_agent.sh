#!/usr/bin/env bash

prefect config set PREFECT_API_URL=http://127.0.0.1:4200/api
prefect work-pool create --overwrite --type docker sgwfc-gene
prefect worker start --pool sgwfc-gene
