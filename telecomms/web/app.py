#!/bin/python3
from flask import Flask, render_template

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/database")
def db():
    return render_template("db.html")

@app.route("/opennebula")
def one():
    return render_template("one.html")

@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html"), 404

app.run(host="0.0.0.0", port=8080)