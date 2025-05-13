from prefect import Flow, Parameter, flatten
from prefect.run_configs import DockerRun
from prefect.executors import LocalDaskExecutor
from modules import *


with Flow("graph_building") as flow:
    gene_filename = Parameter("gene_filename", default = "/input/base_wgcna.csv")

    wgcna_command = get_wgcna_command(gene_filename)
    wgcna_colors = build_wgcna(command=wgcna_command)
    wgcna_color_filenames = get_color_filenames(wgcna_colors)
    wgcna_data = extract_wgcna.map(wgcna_color_filenames)
    string_db = get_stringdb()
    string_data = extract_string_scores(flatten(wgcna_data), string_db)
    gene_interactions = filter_reliable_interactions(string_data)
    result_subgraphs = build_interaction_graph(gene_interactions)
    output = save_output(result_subgraphs)

flow.run_config = DockerRun(
    image="ghcr.io/biobd/sgwfc/gene:latest"
)
flow.executor = LocalDaskExecutor()
flow.register(project_name="sgwfc-gene")

if __name__ == "__main__":
    flow.run()