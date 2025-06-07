import time
import asyncio
from prefect.deployments import run_deployment
from prefect import get_client


async def main():
    flow_run = await run_deployment(name="graph-building/sgwfc-gene")

    flow_run_id = flow_run.id

    async with get_client() as client:
        flow_run = await client.read_flow_run(flow_run_id)
        while not flow_run.state.is_completed():
            time.sleep(10)
            print(f"Current state of the flow run: {flow_run.state}")

    res = last_task.state.load_result(last_task.state._result).result

    print(res)

asyncio.run(main())
