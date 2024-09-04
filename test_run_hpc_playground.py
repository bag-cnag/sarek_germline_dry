import requests
#import jwt
import os

from keycloak import KeycloakOpenID
import pytest
def pytest_namespace():
    return {'plan_id': 0 ,"dar_id": None}
api_host="https://playground.gpapdev.cnag.eu/analysis_service/"

username='test'#os.environ['username']
password= os.environ['password']


keycloak_openid = KeycloakOpenID(server_url="https://sso.gpapdev.cnag.eu/",
                    client_id="genomed4all",
                    realm_name="playground",
                    client_secret_key="ac1ae8c6-d525-472e-ab59-7631399cdc29",
                    verify=False)

import requests,json
token = keycloak_openid.token(username,password )

headers={"Content-Type": "application/json","Authorization":f"Bearer {token['access_token']}", "host":"playground.gpapdev.cnag.eu"}

def pytest_namespace():
    return {'dar_id': 0}
#dataload
#first step generate a csv file out of  something,pipeline,query,etc and then link the data id to the training plan
dar_data1 = {"analysis_type":"germline",
 "description":"","clinical_referrer":"",
 "clinical_referrer_contact":"","hospital_name":"",
 "priority":"medium","deadline":"2024-09-04",
 "resource_id":1,"pipeline_id":12,
 "tumor_experiment_id":"",
 "control_experiment_id":"HG002"}



def test_create_dar():
    resp=requests.put(api_host+"/dars/",json=dar_data1, headers=headers)
    pytest.dar_id=resp.json()['id']
    print(pytest.dar_id)
    assert resp.status_code == 201

def test_run_task():
    resp=requests.post(f"{api_host}/dars/run/{pytest.dar_id}",json={"resource_id":1}, headers=headers)
    status_array=resp.json()['data'][0]
    if len(status_array[1])==7:
        pytest.task_id=status_array[1]
    else :
        pytest.task_id=status_array[2]
    print(pytest.task_id)
    assert resp.status_code == 200

def test_run_execution():
    import time
    while True:
        
        
        time.sleep(3)
        
        resp= requests.get(f"{api_host}/tasks/{pytest.task_id}", headers=headers)
        status=resp.json()['data'][0]['status']
        if status=='completed':
            assert 1==1
            break
        if status=='failed':
            assert 1==0
            break
        

def test_check_status_dar():
    resp=requests.get(f"{api_host}/dars/{pytest.dar_id}", headers=headers)
    assert resp.json()['data'][0]['status']=='review'

    assert resp.status_code == 200 

def test_delete_dar():
    resp=requests.delete(f"{api_host}/dars/{pytest.dar_id}", headers=headers)
    assert resp.status_code == 200 
