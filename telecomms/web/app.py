from flask import Flask, render_template, redirect, url_for, request, session, flash
from helpers import find_user_in_db, get_vm_data
from onevm import get_nebula_oneadmin_templates

app = Flask(__name__)
app.secret_key = "Something secret!"



@app.route("/")
def empty():
    return redirect((url_for("view_vm_list")))

@app.route("/vms")
def view_vm_list():
    if 'username' in session:
        username = session['username']
        user_data = find_user_in_db(username)
        if user_data is not None:
            users_vms_data = get_vm_data(user_data["vm_ids"]) # query our db
        
            return render_template('vms.html', user_data=user_data, vmlist=users_vms_data)
        
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
        if user_data: 
            templates = get_nebula_oneadmin_templates()
            if request.method == 'GET':
                return render_template("create.html", templates=templates, user_data=user_data)
            
            # CREATE VM LOGIC HERE
            return redirect(url_for("view_vm_list"))
    
        return redirect(url_for("login"))


    
    


@app.route('/vm/<int:vm_id>', methods=['GET', 'POST', 'DELETE'])
def manage_vm(vm_id):
    pass
    


@app.route('/logout')
def logout():
    session.pop('username', None)
    return redirect(url_for('login'))


@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html"), 404

app.run(host="0.0.0.0", port=8080)