# sgwfc-gene-python
gene INCA workflow using Python

## Install
Make Python 3.8+ virtualenv

```
make install
```

## Prototype

### Opening notebook

```
make notebook
```

Workflow prototipe is [here](workflow.ipynb)

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

Should be up and running on http://localhost:8080

### Prefect Agent

```
make agent
```
This command will create a new project called `sgwfc-gene` on Prefect and start an Agent to run workflows

### Register Workflow

Everytime you change the workflow you need to run this command to register it to Prefect

```
make flow
```

### Test engine

Will test the registered workflow calling it externally

```
make test
```

### Test with the Frontend

In order to send the input file and run the workflow through the frontend server you need to run the FastApi server

```
make api
```
