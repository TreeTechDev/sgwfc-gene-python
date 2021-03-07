import pandas
import networkx
from prefect import task, Flow, Parameter
from prefect.engine.results import LocalResult
from prefect.run_configs import LocalRun


@task
def extract_string(filename: str) -> pandas.DataFrame:
    return pandas.read_csv(filename)


@task
def extract_wgcna() -> pandas.DataFrame:
    return pandas.read_csv("input/WGCNA/module_yellow.txt", names=["name"])


@task
def define_node_interaction(string_df: pandas.DataFrame) -> pandas.DataFrame:
    spliting_name = string_df.name.str.split(" \\(pp\\) ").str
    string_df["node1"] = spliting_name[0]
    string_df["node2"] = spliting_name[1]
    return string_df


@task
def filter_reliable_interactions(
        node_df: pandas.DataFrame) -> pandas.DataFrame:
    cols = ["node1", "node2", "experiments", "databases", "score"]
    filters = (
        (node_df.experiments >= 0.5) |
        ((node_df.experiments >= 0.3) & (node_df.databases >= 0.9))
    )
    return node_df[cols][filters]


@task
def pattern_gene_names(
        reliable_df: pandas.DataFrame,
        wgcna_df: pandas.DataFrame) -> pandas.DataFrame:
    reliable_df.loc[reliable_df[reliable_df.node2 ==
                                "DP2"].index, "node2"] = "TFDP2"
    reliable_df.loc[reliable_df[reliable_df.node2 ==
                                "CCL4L1"].index, "node2"] = "CCL4L2"
    reliable_df = reliable_df.drop(
        index=reliable_df[reliable_df.node2 == "ENSP00000412457"].index)

    assert reliable_df.node1.isin(wgcna_df.name).all()
    assert reliable_df.node2.isin(wgcna_df.name).all()
    return reliable_df


@task
def build_interaction_graph(pattern_df: pandas.DataFrame) -> networkx.Graph:
    return networkx.from_pandas_edgelist(
        pattern_df, "node1", "node2", edge_attr=True)


@task(result=LocalResult(dir='results'))
def save_output(graph: networkx.Graph) -> dict:
    return networkx.readwrite.json_graph.cytoscape_data(graph)


with Flow("graph_building") as flow:
    gene_filename = Parameter("gene_filename", default = "input/STRING/yellow_interactions.csv")
    string_data = extract_string(gene_filename)
    wgcna_data = extract_wgcna()
    node_interaction = define_node_interaction(string_data)
    gene_interactions = filter_reliable_interactions(node_interaction)
    gene_pattern_names = pattern_gene_names(gene_interactions, wgcna_data)
    result_graph = build_interaction_graph(gene_pattern_names)
    output = save_output(result_graph)

flow.run_config = LocalRun()
flow.register(project_name="sgwfc-gene", idempotency_key=flow.serialized_hash())
