# Overview

This demo application was created to showcase the concept of [adding automated performance quality gates using Keptn Pitometer](https://cloudblogs.microsoft.com/opensource/2019/04/25/adding-automated-performance-quality-gates-using-keptn-pitometer/)

Once provisioned, the sample nodejs application will look like this for both a "staging" and "production" webapp intances.

<img src="img/demoapp.png" width="500"/>

# Folders and files

1. ```root folder and img/``` - location of demo ```app.js``` nodejs demo application
1. ```perfspec/``` - folder containing sample perfspec file
1. ```pipline/``` - folder containing scripts that can be used in DevOps pipelines
1. ```arm/``` - folder containing scripts and templates to provision demo Azure resources

# Local development

1. You must have [node](https://nodejs.org/en/download/) installed locally.
1. Once you clone the repo, you need to run ```npm install``` to download the required modules
1. run ```npm update```
1. run ```npm start```
1. access the application @ ```http://127.0.0.1:8080/```

# Provision Demo resources

See [these instructions](./arm/ARM.md) 