# The Snowpark package is required for Python Worksheets.
# You can add more packages by selecting them using the Packages control and then importing them.
import mlflow
import numpy as np
from sklearn.linear_model import LinearRegression
import snowflake.snowpark as snowpark
from snowflake.snowpark.functions import col

def main(session: snowpark.Session):
    mlflow.set_tracking_uri("file:///tmp/")
    exp_id = mlflow.create_experiment("test")
    run_id = "aee6b961c1794fd59d1046b26d0d8e3c"
    model_local_path = "/tmp/model"

    with mlflow.start_run(run_name='untuned_random_forest', experiment_id=exp_id):
        # prepare training data
        X = np.array([[1, 1], [1, 2], [2, 2], [2, 3]])
        y = np.dot(X, np.array([1, 2])) + 3

        # train a model
        model = LinearRegression()
        model.fit(X, y)
        run_id = mlflow.last_active_run().info.run_id
        print("Logged data and model in run {}".format(run_id))
        mlflow.sklearn.save_model(model,model_local_path)
        session.file.put(f"{model_local_path}/*", f"@mlflow_stage/{exp_id}/{run_id}/artifacts/model/", auto_compress=False)
    return "OK"