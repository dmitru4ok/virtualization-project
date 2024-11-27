from flask import Flask, render_template, redirect, url_for, request, session, flash
from db import find_user_in_db, get_vm_data, add_vm, remove_vm
import onevm

app = Flask(__name__)
app.secret_key = "Something secret!"
MESSAGE = "No user in the database"


@app.route("/")
def empty():
    return redirect((url_for("view_vm_list")))

@app.route("/vms")
def view_vm_list():
    if 'username' in session:
        username = session['username']
        user_data = find_user_in_db(username)
        if user_data is not None: # if user is in DB
            users_vms_ids = get_vm_data(user_data) 
            if len(user_data) > 0:
                all_vms_data = onevm.fetch_vms_from_nebula_account()
                full_vm_info = [vm for vm in all_vms_data if vm["ID"] in users_vms_ids]
            else:
                full_vm_info = []
            return render_template('vms.html', vmlist=full_vm_info, user_data=user_data)
        return redirect(url_for('logout'))
    return redirect(url_for('login'))


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = find_user_in_db(username)

        if user is not None and user["password"] == password:
            session['username'] = username
            return redirect(url_for('view_vm_list'))
        else:
            flash('Invalid username or password', 'danger')
            return redirect(url_for('login'))
    
    return render_template('login.html')


@app.route("/create", methods=['GET','POST'])
def create():
    if 'username' in session:
        username = session['username']
        user_data = find_user_in_db(username)
        if user_data is not None: 
            templates = onevm.get_nebula_oneadmin_templates()
            if request.method == 'GET':
                return render_template("create.html", templates=templates, user_data=user_data)
            
            # CREATE VM LOGIC HERE
            template_id = int(request.form["template"])
            vm_name = request.form["vm_name"]
            try:
                res_id = onevm.instantiate_vm(template_id, vm_name)
            finally:
                if res_id:
                    add_vm(user_data["login"], res_id)
            return redirect(url_for("view_vm_list"))
        return redirect(url_for('logout'))
    return redirect(url_for("login"))


@app.route('/vm/<int:vm_id>', methods=['GET'])
def manage_vm(vm_id):
    if 'username' in session:
        username = session['username']
        user_data = find_user_in_db(username)
        if user_data is not None:
            vm_info = onevm.fetch_vm_by_id(vm_id)
            return render_template("vminfo.html", vm_info=vm_info)
        return redirect(url_for('logout'))
    return redirect(url_for('login'))


@app.route('/vm/<int:id>/<action>', methods=['POST'])
def manage_vm_action(id, action):
    if 'username' in session:
        username = session['username']
        user_data = find_user_in_db(username)
        if user_data is not None:
            try:
                res = onevm.perform_vm_action(id, action)
                if res and action == 'shutdown-hard':
                    remove_vm(res)
                return redirect(url_for('view_vm_list'))
            except Exception as e:
                print(e)
                return redirect(url_for('manage_vm', vm_id=id))

        return redirect(url_for('logout'))
    return redirect(url_for('login'))

    

@app.route('/logout')
def logout():
    session.pop('username', None)
    return redirect(url_for('login'))


@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html"), 404

app.run(host="0.0.0.0", port=8080)