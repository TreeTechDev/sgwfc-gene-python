from prefect import flow
# from prefect.run_configs import DockerRun
# from prefect.executors import LocalDaskExecutor
from prefect.docker import DockerImage
from modules import *
import os


os.environ["PREFECT_API_URL"] = "http://127.0.0.1:4200/api"


@flow
def graph_building(gene_filename: str = "/input/base_wgcna.csv") -> List[dict]:
    wgcna_command = get_wgcna_command(gene_filename)
    wgcna_colors = build_wgcna(command=wgcna_command)
    wgcna_color_filenames = get_color_filenames(wgcna_colors)
    wgcna_data = extract_wgcna.map(wgcna_color_filenames)
    string_db = get_stringdb()
    string_data = extract_string_scores(wgcna_data, string_db)    
    gene_interactions = filter_reliable_interactions(string_data)
    result_subgraphs = build_interaction_graph(gene_interactions)
    output = save_output(result_subgraphs)
    return output





# flow.run_config = DockerRun(
#     image="ghcr.io/biobd/sgwfc/gene:latest"
# )
# flow.executor = LocalDaskExecutor()
# flow.register(project_name="sgwfc-gene")

if __name__ == "__main__":
    graph_building.deploy(
        name="sgwfc-gene",
        registry_url="ghcr.io",
        image_name="biobd/sgwfc-gene",
        image_tag="latest",
        add_default_labels=False
    )