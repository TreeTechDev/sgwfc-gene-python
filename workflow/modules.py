import pandas
import networkx
import datetime
import requests
import logging
import prefect
from networkx.algorithms import community
from typing import List
from prefect import task
from prefect.engine.results import LocalResult
from prefect.tasks.shell import ShellTask

RESULT_DIR = "result"

build_wgcna = ShellTask(
    name="build_wgcna",
    checkpoint=True,
    stream_output=logging.INFO,
    log_stdout=True,
    log_stderr=True,
    result=LocalResult(dir=RESULT_DIR),
    cache_for=datetime.timedelta(days=1)
)

@task
def get_wgcna_command(gene_filename: str) -> str:
    logger = prefect.context.get("logger")
    command = f"Rscript WGCNA.R {gene_filename} /{RESULT_DIR}/ --verbose"
    logger.info(command)
    return command


@task
def get_color_filenames(colors: str) -> List[str]:
    return [f"{RESULT_DIR}/{c}" for c in colors.split(" ")]

@task
def extract_wgcna(filename: str) -> List[str]:
    logger = prefect.context.get("logger")
    logger.info(filename)
    with open(filename, "r") as f:
        return list(filter(None, f.read().split("\n")))


@task(
    checkpoint=True,
    result=LocalResult(dir=RESULT_DIR),
    cache_for=datetime.timedelta(days=1),
    max_retries=3,
    retry_delay=datetime.timedelta(minutes=1))
def get_stringdb() -> pandas.DataFrame:
    logger = prefect.context.get("logger")
    df = pandas.read_csv(
        "https://stringdb-static.org/download/protein.links.detailed.v11.0/9606.protein.links.detailed.v11.0.txt.gz",
        sep=" "
    )[["protein1", "protein2", "experimental", "database"]]
    df_names = pandas.read_csv(
        "https://stringdb-static.org/download/protein.info.v11.0/9606.protein.info.v11.0.txt.gz",
        sep="\t"
    )[["protein_external_id", "preferred_name"]]

    df_renamed_p1 = pandas.merge(
        df, df_names, "left", left_on="protein1", right_on="protein_external_id"
    ).rename(columns={"preferred_name": "preferredName_A"}
    )[["preferredName_A", "protein2", "experimental", "database"]]

    df_renamed = pandas.merge(
        df_renamed_p1, df_names, "left", left_on="protein2", right_on="protein_external_id"
    ).rename(columns={"preferred_name": "preferredName_B"}
    )[["preferredName_A", "preferredName_B", "experimental", "database"]]
    logger.info(df_renamed.head())
    return df_renamed


@task
def extract_string_scores(identifiers: List[str], db: pandas.DataFrame) -> pandas.DataFrame:
    logger = prefect.context.get("logger")
    logger.info(identifiers)
    df_genes = db[  
        db.preferredName_A.isin(identifiers) & db.preferredName_B.isin(identifiers)]

    df_genes["escore"] = df_genes["experimental"] / 1000.0
    df_genes["dscore"] = df_genes["database"] / 1000.0
    return_df = df_genes[["preferredName_A", "preferredName_B", "dscore", "escore"]]
    logger.info(return_df.head())
    return return_df


@task
def filter_reliable_interactions(
        node_df: pandas.DataFrame) -> pandas.DataFrame:
    logger = prefect.context.get("logger")

    filters = (
        (node_df.escore >= 0.5) |
        ((node_df.escore >= 0.3) & (node_df.dscore >= 0.9))
    )
    return_df = node_df[filters]
    logger.info(return_df.head())
    return return_df


@task
def build_interaction_graph(pattern_df: pandas.DataFrame) -> List(networkx.Graph):
    logger = prefect.context.get("logger")

    graph = networkx.from_pandas_edgelist(
        pattern_df, "preferredName_A", "preferredName_B", edge_attr=True)
    logger.info(graph.nodes)

    clusters = community.girvan_newman(graph)
    subgraphs = []
    for cluster in next(clusters):
        if len(cluster) >= 5:
            subgraph = graph.subgraph(cluster).copy()
            subgraph.remove_nodes_from(list(networkx.isolates(subgraph)))
            subgraphs.append(subgraph)
    for subgraph in subgraphs:
        logger.info(subgraph.nodes)
    return subgraphs


@task(result=LocalResult(dir=RESULT_DIR))
def save_output(subgraphs: List(networkx.Graph)) -> List(dict):
    subgraphs_cytoscape = []
    for subgraph in subgraphs:
        subgraphs_cytoscape.append(networkx.readwrite.json_graph.cytoscape_data(subgraph))
    return subgraphs_cytoscape
