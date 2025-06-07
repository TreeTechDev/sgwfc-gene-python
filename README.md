# sgwfc-gene-python
gene INCA workflow using Python

## Install
Make Python 3.8+ virtualenv

```
make install
```

## Prototype

### Opening notebook (Optional)

```
make notebook
```

Workflow prototipe is [here](analysis/workflow.ipynb)

## Using

You need to follow these instructions in order to make sure everything working

### Build Image to Run

Docker image with all R and Python workflow dependecies is built with
```
make pull
```

### Prefect Server

```
make server
```

Should be up and running on http://localhost:4200

### Prefect Agent

```
make agent
```
This command will create a new worker called `sgwfc-gene` on Prefect and start a Worker (was called Agent) to run workflows

### Register Workflow

Everytime you change the workflow requirements you need to run this command to register it to Prefect. Workflow code is already mounted inside agent and every change in your pc changes agent too

```
make flow
```

### Test engine

Will test the registered workflow calling it externally

```
make test
```

All inputs inside `worflow/input` folder will be available for workflow and all results are stored pickle encoded inside `workflow/result` folder

### Test with the Frontend

In order to send the input file and run the workflow through the frontend server you need to run the FastApi server

```
make api
```
