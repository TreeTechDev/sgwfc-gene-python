.PHONY: install notebook flow

install:
	@pip install -r requirements.txt
	@pip install -r workflow/requirements.txt
	@prefect backend server
	@prefect create project "sgwfc-gene"

notebook:
	@jupyter-notebook

flow:
	@PREFECT__LOGGING__LEVEL=DEBUG python workflow/graph_builder.py
