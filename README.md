# roon-extension-generator
A generator for Docker based Roon extensions

## Introduction
With the release of version 1.0 the Roon Extension Manager moved over to Docker based extension distribution only. This means that npm based extensions have to be converted to Docker images. Although not a very difficult process, this Roon Extension Generator is here to make the transition as easy as possible. It generates the core files for your extension that you then can extend with the required functionality or merge with your existing extension code to create the Docker image. This way converting an extension to a Docker image should be a task of a few hours max.

## Running the Hello World!
The correct operation of the Extension Generator can be verified by building and running the default Hello World! extension. The commands to run (from the root directory of the generator) are:

```shell
./generate.sh
./build.sh
out/roon-extension-hello-world/.reg/bin/docker_run.sh
```
If the commands ran successfully then the Hello World extension should appear in the Extensions list within Roon. It is just a displayed name, you cannot do anything with it.

## Building the image
The steps to take for building an image are:

* Set the variables in `settings` to their applicable values, each setting has a description about its purpose

* Generate the template for your extension

    ./generate.sh

* Make the necessary changes in the generated files to let the extension fulfil its function, or

* Merge the generated code with your existing extension

* Build the Docker image

    ./build.sh

## Running and testing the image
If you have set the `USER` variable in `settings` then your extension is now published on Docker Hub. If the variable is kept empty than you can test the local image.

### Published image testing
* Install and test your extension via the Extension Manager, you can find it in the Test category

### Local image testing
* Run and test your extension by running the generated script:

    out/<extension name>/bin/docker_run.sh

## Multi architecture support
TODO

## Inclusion in Extension Repository
* If al works fine, you can integrate the generate repository file `etc/repository.json` in your fork of the Extension Repository (v1.x branch) and create a pull request for inclusion.
