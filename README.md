# Dockerize Python

This repo is materials used for the talk originally given at Python at the Point in Lehi, UT September 8th, 2022.

## Why Docker? Why now?

Ultimately, docker is about isolating variables and repeatable actions. Idempotency in asset building and execution.

It solves (among other things) 3 major pains for us as engineers: "works on my machine" syndrome, consistent packaging (how many times did you install something and it broke your ability to build other stuff?), and environment management.

Another benefit that I think is undervalued is that it forces us to think about build steps in repeatable and change isolating ways, or we pay the consequences in high build times, oversized assets, etc.

## What is Docker?

Docker is process and environment isolation packaged in a set of tools. It is not virtualization, though it solves much of the same problems with easier composable pieces. They're more akin to chroot jails. There's a good Bryan Cantrill talk on the [history of containers](https://www.youtube.com/watch?v=xXWaECk9XqM), I highly recommend it.

The Docker ecosystem is more interesting. The Docker project itself is very fragmented, and in the real world not all of its pieces are used. The CLI tool is the main interface for us, but there's a daemon that maps operations to process namespaces and such.

So really we're talking about containers and the docker CLI command is the forefront, but you're probably not running raw docker project stuff in all places.


## Rules of Engagement

Proper Docker approaches require we have some principles we follow with rare exception:

* We run one thing in a container. One thing. Always. If we need more things, we should refactor so we can run them in separate containers and have them talk to each other.
* We have as little as possible in the container. If we can get away with one binary, that's what we put in there.
* We organize Dockerfiles from least likely to change to our code/build steps that should change with our code. Then we run the command for the container.
* We don't see everything as a nail (see dev environments). This tooling is cool, it is not a panacea.
* We don't run as root, which will cause us some headache, but only once.
* Docker containers are ephemeral. An example: no disk access unless it's called out as "you need to mount a volume if you want this data to persist." Cattle, not pets.

That last bit, cattle not pets, is important. If the priority is to get prod back up and running, your first reaction should be to kill the current container and start a new one, and hopefully you have logs and metrics to debug what was going on in the now-dead container before you killed it. Somewhat violent wording, but important because you want to distance yourself from these containers. They are not your pets.


## Why Python Makes This Hard

Python is interpreted, and it has a massive unwieldy runtime. We add to that runtime. Docker is best when you don't have to have a whole OS with it, and this is difficult for Python.

Languages where you compile to a single binary merely have to build that and copy the resulting binary into the final docker image. They're tiny, they're easy to build, they make things nice.

In order to get closer to that with Python, we use small OS images as our base, and we write python that doesn't rely on our laptops. This means you develop wherever, but you should be testing in a container for that isolaton. Oh, right, isolation. We have venvs for that already, right?

Venvs are great for isolating packages. We want to isolate the rest of the environment with it. We want process, filesystem, and even history isolation. Ever had a venv where you had to adjust the use of global packages? Now imagine that with your environment variables, that config file you were fiddling with in your home directory, or dozens of other scenarios. Test in docker and you eliminate _all_ of thos variables.


## Embrace Minimalism

Docker can be used to run massive monolithic apps, but this is not very useful. When you are building for separation of concerns, you want to build composable pieces and have them interact. This is just normal software engineering, and we're applying it to asset management.

So even if we're going to run a monolith, separating libraries that are built and maintained separately is a huge advantage since we just version pin to those API contracts of those libraries, and our build is as easy as installing those versions. It's cutting the huge feast into bite-sized manageable chunks.

Have your Dockerfiles do less, your code do less, and then you will be surprised how easily you will glue things up differently over time. It's like remodeling your house, but without it being a huge project. You just push the wall out a bit and move those stairs on the rollers you made for them.


## You Should Care Less

Coupling happens when we care. We should avoid that. Let's ask some questions:

- Do we care that we're running in Docker or on a laptop? What about our code needs to know?
- Do we care if we're running in AWS or GCP?
- Do we care if we're on Python 3.7 or 3.8? If we support those versions, we should test in them, but do we care what version specifically we are actively running in? Duck-type your whole system.
- Do we care about the kernel version we're running against? Windows? Linux? Solaris?
- Do we care if the database we're talking to is in the same server? Across the world? Whether it works or not?

All of these are things we should sometimes care about, but most of the time, no. We don't care. We don't need to care. If we care, we start tying our system to those other things. Suddenly you can't run your twitter clone on a windows machine because you thought you needed a linux kernel version for performance. Maybe you need that for production, but you should be able to run it on Windows for development or demos or something. Things like that.

Docker lets us package things where we can care less about even more things than usual.


## Docker for Development: A Special Case

I don't use Docker for my dev environments. Part of that is I don't want to be tied to Docker. That's the whole point of caring less.

Part of that is Docker making it difficult to simultaneously isolate an environment while also bringing all the nice things I like about my environment, like my editor and my debugger.

You can see it in the Dockerfile.dev where I've setup an environment you can execute into, and it has mounted your local filesystem, but the User IDs are weird (try `ll` in there), the rest of your tooling isn't there, you can't `ll` at all without the special bashrc I included to exemplify this surgery you have to do, etc.

You should try it and see what you like and don't like about it, and you should try to fix some of the issues you find with the workflow in a docker environment, but time box it to a week of attempting or something. I recommend by starting to edit some code outside the container, like with VSCode or similar, adjust the flask app in `serve-local.sh` to auto-reload and see if it picks up edits. It might. Depends on your system and such.


## Kicking the Tires: Demo Time!

Everything here uses bash, because even on Windows I used bash for development and if you are picky about that, well, you should know how to translate those commands. There's only a few of them. Otherwise, just use bash or WSL2 or something.

Docker makes demoing pretty easy because it's literally supposed to be a portable reproducable execution. If you have docker installed (up to you, I'm afraid, too may paths for this), you can do the following:

- Run `dev-docker.sh` which will leave you _inside_ a container freshly run from a newly built image.
- Inside the container, try `ll` and see what user you are and what files you have. You should see the code.
- Run `serve-local.sh` to serve it. Note that it will bind to 0.0.0.0 _inside_ the container, and the `docker run` command we used binds the container's port 5000 to our _host_ machine's localhost:5000
- Open a browser on your machine to (http://localhost:5000) and see Hello World!  Feel free to manipulate this and see what changes in varous ways. Edit it outside the container, kill the container, etc.
- Logout of the container. It will remove the container for you. Then run the `run-prodlike.sh` script to run the prod version. Compare the dockerfiles. Note that it doesn't drop you into the container. This is a prod container, it's not built to be a nice env.

Now there's some advanced stuff like multistage builds, or you could have the same "base" for both dev and prod Dockerfiles, but these are topics for very different conversations. Feel free to explore them at your leisure.

Another important thing here is the user management. Many docker examples and the excrutiatingly vast majority of production builds just run as root. Here I've done the hard work for us all on not having to run as root. It's about half the Dockerfiles to do so, but it's worth it since I will never have to change that and it's flexible to multiple environments. If your UID is 1005 or something, the dev container will still work for you. The prod one doesn't care, it's always running as its own non-root ID and shouldn't even know about yours.

## Q&A

This should be obvious what the content of this section would be.
