from fastapi import FastAPI, File, UploadFile

import os
import shutil

from start_workflow import *

app = FastAPI()

# change fastapi port to 8080



@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.post("/upload-file/")
async def upload_file(file: UploadFile = File(...)):
    #file_location = f"/input/{file.filename}"
    file_location = os.path.join("workflow/input", file.filename)
    with open(file_location, "wb") as file_object:
        shutil.copyfileobj(file.file, file_object)

    
    result = start_workflow(file.filename)
    

    # Call the Prefect flow with the file path
    return result