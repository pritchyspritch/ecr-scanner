# Introduction
This is a simple bash script I had to hack together so I could pull multiple container images from AWS ECR, then run Trivy against the latest image version. I'm aware ECR already scans images, but there was a specific need to run my own scans, and in doing so I noticed it picked up things the ECR scans did not.

## TODO
- [ ] fix it to make the script more generic
- [ ] _maybe_ convert it to python

In the meantime, feel free to steal the hacky version.

## Pre-requisites
In order to run this script you will need:

* a Read-Only user in the ECR AWS Account you're auditing
* [AWS CLI](https://aws.amazon.com/cli/) and [AWS-Vault](https://github.com/99designs/aws-vault)/Authentication for the CLI
* [trivy](https://github.com/aquasecurity/trivy) scanner
* [docker](https://www.docker.com/products/docker-desktop)

## Running the script
Create a directory for your script to run, then make your script executable: `sudo chmod +x ecr-scanner.sh`.

Simply run with: `aws-vault exec <profile-name> -- ./ecr-scanner.sh`

The scan will run and output the Trivy scan data to files with the convention `trivy_$name.txt`.