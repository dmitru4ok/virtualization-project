import pyone
from load_dotenv import load_dotenv
from os import getenv


load_dotenv()
ON_uname = getenv("ON_LOGIN")
ON_pass = getenv("ON_PASS")
one = pyone.OneServer("https://grid5.mif.vu.lt/cloud3/RPC2", session=f"{ON_uname}:{ON_pass}")

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
    
