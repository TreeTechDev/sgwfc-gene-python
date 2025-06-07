.PHONY: install build notebook flow agent test


install:
	@unzip analysis/input/base_wgcna.csv.zip -d workflow/input/
	@pip install -r analysis/requirements.txt
	@pip install -r workflow/requirements.txt 

notebook:
	@jupyter-notebook

build:
	@docker build -t ghcr.io/treetechdev/sgwfc/gene:dev -f Dockerfile.dev .

flow:
	@prefect config set PREFECT_API_URL=http://127.0.0.1:4200/api
	@cd workflow && PREFECT__LOGGING__LEVEL=DEBUG python graph_builder.py

server:
	@prefect config set PREFECT_RESULTS_PERSIST_BY_DEFAULT=true
	@prefect config set PREFECT_LOCAL_STORAGE_PATH='/workflow/result'
	@prefect server start

agent:
	@bash start_agent.sh

test:
	@python test.py

pull:
	@docker pull ghcr.io/treetechdev/sgwfc/gene:latest

api:
	@uvicorn api:app --host 0.0.0.0 --port 5000 --reload
