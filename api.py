from fastapi import FastAPI, File, UploadFile

import os
import shutil
import time
from start_workflow import *

app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.post("/upload-file/")
async def upload_file(file: UploadFile = File(...)):

    file_location = os.path.join("input", file.filename)

    # saves the input file
    with open(file_location, "wb+") as file_object:
        shutil.copyfileobj(file.file, file_object)

    # runs the workflow
    result = start_workflow(file.filename)

    # removes the input file
    os.remove(file_location)

    return result