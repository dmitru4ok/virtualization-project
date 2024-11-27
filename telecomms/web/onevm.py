import pyone
from load_dotenv import load_dotenv
from os import getenv


load_dotenv()
ON_uname = getenv("ON_LOGIN")
ON_pass = getenv("ON_PASS")
if ON_uname is None or ON_pass is None:
    raise ConnectionRefusedError("NO CREDENTIALS IN ENVIRONMENT VARIABLES (watch .env.example file)")
one = pyone.OneServer("https://grid5.mif.vu.lt/cloud3/RPC2", session=f"{ON_uname}:{ON_pass}")
STATE = ["INIT", "PENDING", "HOLD", "RUNNING", 
         "STOPPED", "SUSPENDED", "DONE", "FAILED", "POWEROFF", 
         "UNDEPLOYED", "CLONING", "CLONING_FAILURE"]

def get_nebula_oneadmin_templates():
    result = []

    # 0 for ondeadmin, 0 for offset, -1 for no limit
    templates = one.templatepool.info(0, 0, -1).VMTEMPLATE 
    for t in templates:
        result.append({
            "NAME": t.NAME, 
            "ID": t.ID, 
            "CPU": float(t.TEMPLATE["CPU"]),
            "MEMORY": int(t.TEMPLATE["MEMORY"]),
            "VCPU": int(t.TEMPLATE["VCPU"])
        })
    result.sort(key=lambda x: x["NAME"])
    return result

def instantiate_vm(template, name):
    res = one.template.instantiate(template, name)
    return res
  
def fetch_vms_from_nebula_account():
    result = []
    res = one.vmpool.info(-1, -1, -1, -1).VM
    for vm in res:
        value = {
            "ID": vm.ID,
            "NAME": vm.NAME,
            "STATE": STATE[vm.STATE]
        }
        result.append(value)
    return result

def fetch_vm_by_id(id):
    res = one.vm.info(id)
    ut = res.USER_TEMPLATE
    value = {
        "ID": res.ID,
        "NAME": res.NAME,
        "STATE": STATE[res.STATE],
        "CONNECT_INFO1": ut["CONNECT_INFO1"], 
        "CONNECT_INFO2": ut["CONNECT_INFO2"],
        "DESCRIPTION": ut["DESCRIPTION"],
        "PRIVATE_IP": ut["PRIVATE_IP"],
        "PUBLIC_IP": ut["PUBLIC_IP"],
        "TCP_PORT_FORWARDING": ut["TCP_PORT_FORWARDING"]
    }
    return value
    

def perform_vm_action(vm_id, action):
    res = one.vm.action(action, vm_id)
    return res