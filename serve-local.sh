#!/usr/bin/env bash

export FLASK_APP=coolapp.app

#env 
poetry run flask run --host=0.0.0.0
