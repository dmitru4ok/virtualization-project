# THIS SHOULD BE IN DB
users = [
    {"login": "user1", "password": "passof1"},
    {"login": "user2", "password": "passof2"}
]


vms = [
    {"user_login": "user1", "open_nebula_id": 73784},
    {"user_login": "user1", "open_nebula_id": 72317},
    {"user_login": "user2", "open_nebula_id": 73569},
]

# THESE SHOULD BE DB CALLS
def find_user_in_db(login):
    for usr in users:
        if usr["login"] == login:
            return usr

    return None

def get_vm_data(user: dict[str, str]):
    return [vm["open_nebula_id"] for vm in vms if vm["user_login"] == user["login"]]


def add_vm(login, vm_id):
    vms.append({"user_login": login, "open_nebula_id": vm_id})