import psycopg2
from psycopg2 import sql

from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Establish the database connection
def get_db_connection():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )
    return conn

# Find user in the database
def find_user_in_db(login):
    conn = get_db_connection()
    cur = conn.cursor()

    query = sql.SQL("SELECT * FROM users WHERE login = %s")
    cur.execute(query, (login,))
    user = cur.fetchone()

    cur.close()
    conn.close()

    if user:
        return {"login": user[0], "password": user[1]}  # Assuming the first column is login>
    return None

# Get VM data from the database for a given user
def get_vm_data(user: dict[str, str]):
    conn = get_db_connection()
    cur = conn.cursor()

    query = sql.SQL("SELECT open_nebula_id FROM vms WHERE user_login = %s")
    cur.execute(query, (user["login"],))
    vm_data = cur.fetchall()

    cur.close()
    conn.close()

    return [vm[0] for vm in vm_data]  # Returning list of VM IDs

# Add a VM to the database
def add_vm(login, vm_id):
    conn = get_db_connection()
    cur = conn.cursor()

    query = sql.SQL("INSERT INTO vms (user_login, open_nebula_id) VALUES (%s, %s)")
    cur.execute(query, (login, vm_id))
    conn.commit()

    cur.close()
    conn.close()

# Remove a VM from the database
def remove_vm(vm_id):
    conn = get_db_connection()
    cur = conn.cursor()

    query = sql.SQL("DELETE FROM vms WHERE open_nebula_id = %s")
    cur.execute(query, (vm_id,))
    conn.commit()

    cur.close()
    conn.close()