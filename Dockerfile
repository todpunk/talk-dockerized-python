FROM python:3.10-slim-bullseye


# These are things that are almost non-changes so they sort of be anywhere
EXPOSE 5000
ENV POETRY_VERSION=1.2.0
# We need to install some things as root before we switch users
RUN apt update && apt install -y curl
# Establish the runtime user (with no password and no sudo)
# Careful here, the IDs aren't guaranteed to be for that group/user
# and who knows what will happen then!
ARG UID=1001
ARG GID=1001
RUN groupadd -f -g ${GID} -o coolgroup
RUN useradd -m -u ${UID} -g coolgroup -o cooluser
USER cooluser
# We don't copy a bashrc because we actively don't want people to login to this

# Now we start making layers that may change over time
RUN curl -sSL https://install.python-poetry.org | python3 -

# Start from the basics, our requirements, via poetry
WORKDIR /home/cooluser/workspace
COPY pyproject.toml poetry.lock /home/cooluser/workspace/ 
RUN /home/cooluser/.local/bin/poetry install -n --no-root
# Only after installing the env do we copy everything else, this ensures our code changes come last
# and any package changes are relegated to a previous layer. PIN YOUR PACKAGE VERSIONS!
COPY . /home/cooluser/workspace

# This is where controversy can happen, we run poetry to run gunicorn
# which gives us isolation and consistency, but introduces an extra command and venv
# There is no right answer here, it's shown because isolation can be nice
# but you can run whatever however makes sense to your needs
CMD ["/home/cooluser/.local/bin/poetry", "run", "gunicorn", "-b 0.0.0:5000", "-w 4", "coolapp.app:app"]

