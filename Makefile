.PHONY: install notebook flow

install:
	@pip install -r requirements.txt
	@pip install -r workflow/requirements.txt

notebook:
	@jupyter-notebook

flow:
	@cd workflow && python graph_builder.py