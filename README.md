# OpenShift Disconnected

This repository is currently a work in progress to document and automate the
process to install OpenShift 4.1 in a disconnected environment.

## Local Environment

To use the automation contained in this repository, you will need to configure
and install a few things locally to get started.

Clone this repository:

```bash
git clone git@github.com:jaredhocutt/openshift-disconnected
```

Install `pipenv`:

```bash
sudo dnf install pipenv
```

Activate the environment and install the dependencies:

```bash
cd openshift-disconnected

pipenv shell
pipenv install
```
