#!/bin/python3
from flask import Flask, render_template, redirect, url_for, request, session, flash
from helpers import find_user_in_db

app = Flask(__name__)
app.secret_key = "Something secret!"
users = [
    {"login": "user1", "password": "passof1", "vm_ids": [1, 3]},
    {"login": "user2", "password": "passof2", "vm_ids": [2]}
]


vms = [
    {"id": 1, "open_nebula_id": 75526},
    {"id": 2, "open_nebula_id": 72216},
    {"id": 3, "open_nebula_id": 72214},
]

@app.route("/")
def empty():
    return redirect((url_for("/vms")))

@app.route("/vms")
def view_vm_list():
    if 'username' in session:
        username = session['username']
        user_data = find_user_in_db(username, users) # should be substituted by db call
        if user_data is not None:
            users_vm_ids = user_data["vm_ids"]
            users_vms_data = [vm for vm in vms if vm["id"] in users_vm_ids]
            # call OpenNebela API/SHELL here to get info about vms
            return render_template('vms.html', user_data=user_data, vmlist=users_vms_data)
        
    return redirect(url_for('login'))


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        user = find_user_in_db(username, users) # should be substituted by db call
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
        user_data = find_user_in_db(username, users) # should be substituted by db call
        return render_template("create.html", user_data=user_data)
    
    return redirect(url_for("login"))


@app.route('/logout')
def logout():
    session.pop('username', None)
    return redirect(url_for('login'))


@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html"), 404

app.run(host="0.0.0.0", port=8080)