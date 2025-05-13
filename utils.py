
import zipfile
import pandas
import os
import io


def save_results(results):
    # no momento está salvando apenas os dataframes em csv
    # mas ainda deve ser modificado para salvar os subgrafos gerados
    # no final do pipeline

    for i,res in enumerate(results):
        if f"task_{i}" not in os.listdir("result/export"):
            os.mkdir(f"result/export/task_{i}")
        if type(res) == pandas.core.frame.DataFrame:
            pandas.DataFrame(res).to_csv(f"result/export/task_{i}/dataframe_{i}.csv", index=False)


def make_zip():
    results_dir = "result/export"
    zip_buffer = io.BytesIO()

    with zipfile.ZipFile(zip_buffer, "w") as zip_file:
        # Walk through the results directory and add files to the ZIP
        for root, dirs, files in os.walk(results_dir):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, start=results_dir)  # Preserve folder structure
                zip_file.write(file_path, arcname=arcname)

    # Finalize the in-memory ZIP file
    zip_buffer.seek(0)

    with open("results.zip", "wb") as f:
        f.write(zip_buffer.getvalue())