# roon-extension-generator
A generator for Docker based Roon extensions

## Introduction
With the release of version 1.0 the Roon Extension Manager moved over to Docker based extension distribution only. This means that npm based extensions have to be converted to Docker images. Although not a very difficult process, this Roon Extension Generator is here to make the transition as easy as possible. It generates the core files for your extension that you then can extend with the required functionality or merge with your existing extension code to create the Docker image. This way converting an extension to a Docker image should be a task of a few hours max.

## Installation
The Extension Generator is a development tool and is used within its git repository, installation is done via cloning:

    git clone https://github.com/TheAppgineer/roon-extension-generator.git
    cd roon-extension-generator

### Importing an existing extension
If you want to modify or maintain an existing extension then you have to clone the extension in the `out` directory of the Extension Generator:

    mkdir out && cd out
    git clone <extension url>

## The Hello World! extension
The correct operation of the Extension Generator can be verified by building and running the default Hello World! extension. The commands to run (from the root directory of the generator) are:

```shell
./generate.sh
./build.sh
out/roon-extension-hello-world/.reg/bin/docker_run.sh
```
If the commands ran successfully then the Hello World extension should appear in the Extensions list within Roon. It is just a displayed name, you cannot do anything with it.

## Detailed instructions
The Extension Generator is a set of scripts, each script performs a specific task in creating, building and publishing an extension.

### The generator
The generator creates an initial set of source files, providing a Hello World! extension in the form of a Docker image. This initial code base can then be extended with the required functionality. It can also be used on an existing code base to create the necessary source file for the creation of a Docker image.

The generator is used once for a specific extension, either for the initial creation or for the conversion to a Docker image.

The steps it take for using the generator are:
* Create a copy of the `settings.sample` file

<p>

    cp settings.sample settings

* Set the variables in `settings` to their applicable values, each setting has a description about its purpose

* Generate the initial code base for your extension

<p>

    ./generate.sh

* Make the necessary changes in the generated files to let the extension fulfill its function, or

* Merge the generated code with your existing extension by going through the created changes in your source files

The output is found in the `out/$NAME` directory. A copy of the `settings` file can be found in `out/$NAME/.reg/etc/settings`. It is advised to commit this file to the git repository of your extension, it can then be used for rebuilding the image in case of an update. You use a specific settings file by supplying its path as a parameter to the script you want to run:

    ./<script>.sh out/$NAME/.reg/etc/settings

### The builder
The builder creates the Docker image from the sources and publishes it on Docker Hub if the `USER` variable in `settings` is set. Publishing requires a [Docker Hub account](https://hub.docker.com/signup) and you have to be signed it via the Docker daemon:

    docker login

The build process is started by running the `build.sh` script:

    ./build.sh

The resulting image if for the CPU architecture of the host system, to support multiple architectures the build script has to be executed once for each required architecture.

To setup the Extension Generator on a second host you first clone the generator and then clone your extension in the `out` directory of the generator (see [Installation](#installation)). After that you can perform the build.

###  The multi architecture publisher
After you have published multiple architecture for your image you can create a [Docker Manifest](https://docs.docker.com/engine/reference/commandline/manifest/) to have it installable via a single `latest` tag. The manifest is an experimental Docker feature that has to be enabled in its `config.json` file, see the linked documentation for more information.

The manifest is optional, the Extension Manager doesn't depend on it.

The manifest is created by running the `publish_multi.sh` script, supplying it the location of the settings file and the architectures that should be included additional to the current host architecture (splitted by spaces):

    ./publish_multi.sh out/$NAME/.reg/etc/settings <additional architectures>

## Running and testing the image
If you have set the `USER` variable in `settings` then your extension is now published on Docker Hub. If the variable is kept empty than you can test the local image.

### Published image testing
Install and test your extension via the Extension Manager, you can find it in the Test category.

### Local image testing
Run and test your extension by running the generated script:

    out/$NAME/.reg/bin/docker_run.sh

## Inclusion in Extension Repository
If your extension works as expected then you can integrate the generated repository file `out/$NAME/.reg/etc/repository.json` in your fork of the Extension Repository (v1.x branch) and create a pull request for inclusion.

If you have published an image for multiple architectures, you should specify all these architectures in the repository entry, e.g:

```json
[{
    "display_name": "Playback",
    "extensions": [{
        "author": "The Appgineer",
        "display_name": "Queue Bot",
        "description": "Roon Extension that lets the queue take control",
        "image": {
            "repo": "theappgineer/roon-extension-queue-bot",
            "tags": {
                "amd64": "amd64",
                "arm": "arm"
            },
            "binds": [
                "/home/node/config.json"
            ]
        }
    }]
}]
```
