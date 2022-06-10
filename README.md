# MLFlow on AppEngine
This module deploys MLFlow app on App Engine Flex with IAP authorization.

## Installation
Follow the related blog post on GetInData's official site:
[link]()

### Using service accounts with IAP
#### Using bash
1. Service account needs to have the following roles:
   1. `IAP-secured Web App User`
   2. `Service Account Token Creator`
2. Obtaining authorization token via curl:
```bash
export TOKEN=$(curl -s -X POST -H "content-type: application/json" -H "Authorization: Bearer $(gcloud auth print-access-token)" -d "{\"audience\": \"${_IAP_CLIENT_ID}\", \"includeEmail\": true }" "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/$(gcloud auth list --filter=status:ACTIVE --format='value(account)'):generateIdToken"  | jq -r '.token')
```
3. Sending the request:
```bash
curl -X GET https://<link to app>.appspot.com/api/2.0/mlflow/experiments/list -H "Authorization: Bearer ${TOKEN}" 
```

#### Using Python
1. Make sure that `google-cloud-iam` package is installed
2. Use the following code
```python
from google.cloud import iam_credentials
import requests
client = iam_credentials.IAMCredentialsClient()
sa = "<Service Account Email>"
client_id = "<OAuth 2.0 Client ID>"
token = client.generate_id_token(
            name=f"projects/-/serviceAccounts/{sa}",
            audience=client_id,
            include_email=True,
).token

result = requests.get("https://<link to app>.appspot.com/api/2.0/mlflow/experiments/list", 
                     headers={"Authorization": f"Bearer {token}"})
print(result.json())
```