from prefect import Flow, Parameter
from prefect.run_configs import DockerRun
from modules import *


with Flow("graph_building") as flow:
    gene_filename = Parameter("gene_filename", default = "input/WGCNA/module_yellow.txt")
    wgcna_data = extract_wgcna(gene_filename)
    string_db = get_stringdb()
    string_data = extract_string_scores(wgcna_data, string_db)
    gene_interactions = filter_reliable_interactions(string_data)
    result_graph = build_interaction_graph(gene_interactions)
    output = save_output(result_graph)

flow.run_config = DockerRun(
    image="sgwfc/gene:latest"
)
flow.register(project_name="sgwfc-gene", idempotency_key=flow.serialized_hash())
