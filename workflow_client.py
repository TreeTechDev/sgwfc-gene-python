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
    
    flow_id = state.result[end_flow].result
    client = Client()

    print("flow_id > ", flow_id)
    # espera o workflow terminar
    while not client.get_flow_run_info(flow_id).state.is_finished():
        time.sleep(5)

    with open("lastest_flow_id.txt", "w") as f:
        f.write(flow_id)
    
    
    # # obtém o resultado da execução do workflow
    # info = client.get_flow_run_info(flow_id)

    # results = []
    # for task in info.task_runs:
    #     print("appending result...")
    #     results.append(task.state.load_result(task.state._result).result)

    # for res in results:
    #     print(type(res))


    # # last_task = info.task_runs.pop()
    # # cyto_graph_dicts = last_task.state.load_result(last_task.state._result).result
    # # return cyto_graph_dicts

    return


def get_results():
    print("get results >>>")
    # get the results from the last prefect run

    with open("lastest_flow_id.txt", "r") as f:
        flow_id = f.read()
        f.close()

    client = Client()
    info = client.get_flow_run_info(flow_id)

    results = []
    for task in info.task_runs:
        results.append(task.state.load_result(task.state._result).result)

    for res in results:
        print(type(res))
    
    return results