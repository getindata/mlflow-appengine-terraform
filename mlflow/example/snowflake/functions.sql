create database demo;
use database demo;
use schema public;

-- INIT SETUP
-- use your GCP Gateway API url
SET GATEWAY_URL='XXX';
-- use your Google AUD (client_id)
SET GCP_AUD='XXX';
-- mlflow artifacts bucket
SET GCP_BUCKET='XXX';

--gcp external stage
CREATE STORAGE INTEGRATION gcp_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'GCS'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ($GCP_BUCKET);
-- get storage_gcp_service_account and set Terraform variable "snowflake_service_account"
DESC STORAGE INTEGRATION gcp_integration;

CREATE STAGE mlflow_stage
  URL = $GCP_BUCKET
  STORAGE_INTEGRATION = gcp_integration;
-- verify stage connection
LIST @mlflow_stage;


-- gcp gateway api integration
create or replace api integration mlflow_integration
    api_provider = google_api_gateway
    google_audience = $GCP_AUD
    api_allowed_prefixes = ($GATEWAY_URL)
    enabled = true;
-- gcp gateway api integration
create or replace api integration mlflow_integration
    api_provider = google_api_gateway
    google_audience = $GCP_AUD
    api_allowed_prefixes = ($GATEWAY_URL)
    enabled = true;


--  EXTERNAL FUNCTION mlflow_experiment_create
-- request/response translators for create experiment

--req
CREATE OR REPLACE FUNCTION mlflow_experiment_create_req(EVENT OBJECT)
RETURNS OBJECT
LANGUAGE JAVASCRIPT AS
'
let exeprimentName = EVENT.body.data[0][1]
return { "body": { "name": exeprimentName }}
';
select mlflow_experiment_create_req(parse_json('{"body":{"data": [["test02"]]}}') );

--resp (passthrough for now)
CREATE OR REPLACE FUNCTION mlflow_experiment_create_res(EVENT OBJECT)
RETURNS OBJECT
LANGUAGE JAVASCRIPT AS
'
return { "body": { "data" :  [[0, EVENT]] } };
';

create or replace external function mlflow_experiment_create(name VARCHAR)
    returns object
    api_integration = mlflow_integration
    request_translator = demo.public.mlflow_experiment_create_req
    response_translator = demo.public.mlflow_experiment_create_res
    as 'XXX/experiments/create';

-- example
select mlflow_experiment_create('demo09');

--  EXTERNAL FUNCTION mlflow_run_create


--req
CREATE OR REPLACE FUNCTION mlflow_run_create_req(EVENT OBJECT)
RETURNS OBJECT
LANGUAGE JAVASCRIPT AS
'
let exeprimentId = EVENT.body.data[0][1]
let runName = EVENT.body.data[0][2]
let seconds = new Date().getTime();

return { "body": { "experiment_id": exeprimentId, "run_name": runName, start_time: seconds }}
';

select mlflow_run_create_req(parse_json('{"body":{"data": [[0,"11"]]}}') );

--resp (passthrough for now)
CREATE OR REPLACE FUNCTION mlflow_run_create_res(EVENT OBJECT)
RETURNS OBJECT
LANGUAGE JAVASCRIPT AS
'
return { "body": { "data" :  [[0, EVENT]] } }
';

create or replace external function mlflow_run_create(experiment_id VARCHAR, run_name VARCHAR)
    returns object
    api_integration = mlflow_integration
    request_translator = demo.public.mlflow_run_create_req
    response_translator = demo.public.mlflow_run_create_res
    as 'XXX/runs/create';

-- example
select mlflow_run_create('1','test');