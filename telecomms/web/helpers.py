from load_dotenv import load_dotenv
from os import getenv




# THIS SHOULD BE IN DB
users = [
    {"login": "user1", "password": "passof1", "vm_ids": [1, 3]},
    {"login": "user2", "password": "passof2", "vm_ids": [2]}
]


vms = [
    {"id": 1, "open_nebula_id": 75526},
    {"id": 2, "open_nebula_id": 72216},
    {"id": 3, "open_nebula_id": 72214},
]

# THESE SHOULD BE DB CALLS
def find_user_in_db(login):
    for usr in users:
        if usr["login"] == login:
            return usr

    return None

def get_vm_data(vm_ids: list[int]):
    if vm_ids is not None:
        return [vm for vm in vms if vm["id"] in vm_ids]

    return None

def add_vm(login, vm_id):
    new_vm_id = vms[-1]["id"] + 1
    vms.append({"id": new_vm_id, "open_nebula_id": vm_id})
    usr = find_user_in_db(login)
    usr["vm_ids"].append(new_vm_id)