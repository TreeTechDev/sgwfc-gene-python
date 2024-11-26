.PHONY: install build notebook flow agent test


install:
	@pip install -r requirements.txt
	@pip install -r workflow/requirements.txt

notebook:
	@jupyter-notebook

build:
	@docker build . -t prefect_agent:latest

flow:
	@prefect backend server
	@prefect create project sgwfc-gene
	@PREFECT__LOGGING__LEVEL=DEBUG python workflow/graph_builder.py

server:
	@prefect backend server
	@prefect server start

agent:
	@prefect backend server
	@bash start_agent.sh

test:
	@python test.py

pull:
	@docker pull ghcr.io/biobd/sgwfc/gene:latest

api:
	@uvicorn api:app --host 0.0.0.0 --port 5000 --reload