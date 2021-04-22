.PHONY: install build notebook flow agent test

install:
	@pip install -r requirements.txt
	@pip install -r workflow/requirements.txt
	@bash download.sh

notebook:
	@jupyter-notebook

build:
	@docker build . -t sgwfc/gene:latest

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