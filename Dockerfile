FROM python:3.10-slim-bullseye

ENV POETRY_VERSION=1.2.0
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
# Start from the basics, our requirements, via poetry
COPY pyproject.toml poetry.lock /workspace

# Create the space we'll start and build from
COPY . /workspace
WORKDIR /workspace

RUN poetry install
# This is where controversy can happen, we run poetry to run gunicorn
# which gives us isolation and consistency, but introduces an extra command
# There is no right answer here, it's shown because of venv isolation is nice
# but you can effectively treat the whole docker container as a venv if preferred
CMD ["poetry", "run", "gunicorn", "-w 4", "coolapp:app"]

