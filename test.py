import time
from prefect.tasks.prefect import StartFlowRun
from prefect import Flow, task, Client
from prefect.run_configs import LocalRun

graph_building = StartFlowRun(
      flow_name="graph_building",
      project_name="sgwfc-gene",
      wait=False
)

with Flow("Call Flow") as flow:
    end_flow = graph_building(parameters=dict(gene_filename="/input/base_wgcna.csv"))

flow.run_config = LocalRun(
    labels=["teste"]
)
state = flow.run()
flow_id = state.result[end_flow].result
client = Client()

while not client.get_flow_run_info(flow_id).state.is_finished():
    time.sleep(10)
info = client.get_flow_run_info(flow_id)
last_task = info.task_runs.pop()
res = last_task.state.load_result(last_task.state._result).result

print(res)
