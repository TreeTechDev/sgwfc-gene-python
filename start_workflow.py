import time
from prefect.tasks.prefect import StartFlowRun
from prefect import Flow, task, Client
from prefect.run_configs import LocalRun


def start_workflow(filename:str):
    # inicializa o workflow
    graph_building = StartFlowRun(
        flow_name="graph_building",
        project_name="sgwfc-gene",
        wait=False
    )

    with Flow("Call Flow") as flow:
        end_flow = graph_building(parameters=dict(gene_filename=f"/input/{filename}"))

    # executa o workflow
    state = flow.run()
    print("> foi??")
    flow_id = state.result[end_flow].result
    client = Client()

    # espera o workflow terminar
    while not client.get_flow_run_info(flow_id).state.is_finished():
        time.sleep(5)
    
    # obtém o resultado da execução do workflow

    info = client.get_flow_run_info(flow_id)
    last_task = info.task_runs.pop()
    cyto_graph_dicts = last_task.state.load_result(last_task.state._result).result
    return cyto_graph_dicts