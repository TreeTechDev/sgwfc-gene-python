.PHONY: install notebook flow agent test

install:
	@pip install -r requirements.txt
	@pip install -r workflow/requirements.txt

notebook:
	@jupyter-notebook

flow:
	@PREFECT__LOGGING__LEVEL=DEBUG python workflow/graph_builder.py

server:
	@prefect backend server
	@prefect server start

agent:
	@prefect backend server
	@prefect create project sgwfc-gene
	@prefect agent local start --api http://localhost:4200

test:
	@python test.py