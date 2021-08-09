#!/bin/bash

# Place to put temp json files created by AWS CLI commands (doesn't play nice with bash variables)
mkdir tmp

account_id=$(012345678910)
region=$(eu-west-1)

# List all repositories in ECR
aws ecr describe-repositories > tmp/repositories.json

# Get the names of all repositories
repo_names=$(jq '.[] | .[] | .repositoryName' tmp/repositories.json | cut -d'"' -f2)

# Loop through all of the repositories
for repo_name in $repo_names
do
    echo $repo_name

    # Get the image name, list details and output to JSON file
    name=$(echo $repo_name | cut -d'/' -f2)
    aws ecr describe-images --repository-name $repo_name > tmp/$name.json

    # Grab the image tag for the latest version using naming convention logic of "release-X" X being the number incremented each new version, removing alpha versions (this may throw an error if there are no images, but it will carry on running)
    image_tag=$(jq '.[] | .[] | {imageTags}' tmp/$name.json | grep release | sort -u | grep -v alpha | tail -1 | cut -d'"' -f2)
    echo $image_tag

    # Make more generic for latest image, rather than by tag like I used. Needs testing.
    # aws ecr describe-images --repository-name $repo_name --query 'imageDetails[*].imageTags[ * ]' --output text | sort -r | head -n 1

    # List the details for the latest image and output to JSON file
    aws ecr describe-images --repository-name $repo_name --image-ids imageTag=$image_tag > tmp/latest_$name.json

    # Grab the details JSON list and check to see if the repository has any images inside, only tries to download if one exists
    image_details=$(jq '.imageDetails' tmp/latest_$name.json)
    echo $image_details

    if [ -z "${image_details}" ] 
        then
            echo "No images for $name"
        else
            # Get the image digest of the latest image in order to allow us to download the image we want
            image_digest=$(jq '.imageDetails | .[] | .imageDigest' tmp/latest_$name.json | cut -d'"' -f2)
            echo $image_digest

            # Get the URI of the image repo
            aws ecr describe-repositories --repository-name $repo_name > tmp/repo_$name.json
            image_uri=$(jq '.[] | .[] | .repositoryUri' tmp/repo_$name.json | cut -d'"' -f2)
            echo $image_uri

            # Get the docker login from AWS, pull the image and scan with trivy - output to .txt file with name of image
            aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $account_id.dkr.ecr.$region.amazonaws.com
            docker pull $image_uri@$image_digest
            trivy image $image_uri@$image_digest > trivy_$name.txt
    fi

done

# Clean up JSON files
rm -rf tmp