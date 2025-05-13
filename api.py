from fastapi import FastAPI, File, UploadFile,HTTPException
from fastapi.responses import StreamingResponse,FileResponse
import os
import shutil
import zipfile
import time
from workflow_client import *
import requests
import pandas

from utils import *


app = FastAPI()



@app.get("/")
def read_root():
    return {"Hello": "World"}



@app.post("/upload-file/")
async def upload_file(file: UploadFile = File(...)):

    # saves the input file
    file_location = os.path.join("input", file.filename)

    # saves the input file
    with open(file_location, "wb+") as file_object:
        shutil.copyfileobj(file.file, file_object)

    # runs the workflow
    start_workflow(file.filename)

    # removes the input file
    os.remove(file_location)

    # DUMMIE DATA
    # # get files from output folder
    # file_names = os.listdir("output")
    
    # # get the subdictionaries from each file
    # cyto_graph_dicts = []
    # for file_name in file_names:
    #     with open(f"output/{file_name}", "r") as f:
    #         cyto_graph_dicts.append(f.read())
    
    # return cyto_graph_dictsf
    return {"finished": True}



@app.get("/download-results/")
async def download_results():
    print("download results endpoint -----------")
    results = get_results()

    save_results(results)

    make_zip()

    file_path = "results.zip"

    # Check if the file exists
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    
    def file_iterator():
        try:
            with open(file_path, "rb") as file:
                while chunk := file.read(1024 * 1024):  # 1 MB chunks
                    yield chunk
        finally:
            # Delete the file after the response is streamed
            if os.path.exists(file_path):
                os.remove(file_path)
                print(f"{file_path} has been deleted.")

    # return the result.zip file
    return StreamingResponse(file_iterator(), media_type="application/zip")