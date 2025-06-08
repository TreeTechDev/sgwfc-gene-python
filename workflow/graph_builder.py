import os
from prefect import flow
from prefect.deployments import DeploymentImage
from modules import *


@flow(log_prints=True)
def graph_building(gene_filename: str):

    wgcna_colors = build_wgcna(gene_filename)
    wgcna_color_filenames = get_color_filenames(wgcna_colors)
    wgcna_data = extract_wgcna.map(wgcna_color_filenames)
    string_db = get_stringdb()
    string_data = extract_string_scores(sum([wgcna.wait().result() for wgcna in wgcna_data], []), string_db)
    gene_interactions = filter_reliable_interactions(string_data)
    result_subgraphs = build_interaction_graph(gene_interactions)
    output = save_output(result_subgraphs)


if __name__ == "__main__":
    image = 'ghcr.io/treetechdev/sgwfc/gene:2.0'
    image = DeploymentImage(
            name="ghcr.io/treetechdev/sgwfc/gene",
            tag="dev",
            dockerfile="Dockerfile.dev"
        )
    path = os.path.dirname(os.path.realpath(__file__))
    graph_building.deploy(name="sgwfc-gene", work_pool_name="sgwfc-gene", image=image, build=False, push=False,  parameters=dict(gene_filename="/input/base_wgcna.csv"), job_variables={"volumes": [f"{path}:/workflow"]})
