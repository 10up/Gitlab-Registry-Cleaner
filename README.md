# Gitlab-Registry-Cleaner
Bash script using the Gitlab API to delete images from a repository.  Support regex and deleting images older than a specific age.  

# How to Use
Copy `config-sample.sh` to `config.sh` and fill in the variables to match the needs of your project.  The `config-sample.sh` file is documented with comments.  

This script uses v4 of the Gitlab API.  It is tested against a self-hosted Gitlab instance and it is unknown if these same commands work on projects hosted on Gitlab.com.  

This is a bash script, so a Linux type shell is required to use it.  It has been tested in Ubuntu, but it should run fine on MacOS and any version of Linux.  

To run the script, first give it execution permissions:

`chmod +x clean-registry.sh`

Running the script:

`./clean-registry.sh`

There are no command line arguments for this script and it is configured entirely with the `config.sh` file.

This script removes the tags from the container registry, but does not actually delete the images (because this is how Gitlab works).  To delete the images, connect to your Gitlab instance (or open a shell inside your Gitlab docker instance) and run the following:

`gitlab-ctl registry-garbage-collect -m`

You may need to use sudo for that command to work.  This will take a while, but afterwards you should see a reduction in the disk space used if you've deleted any docker images with this script.  

## Support Level

**Active:** 10up is actively working on this, and we expect to continue work for the foreseeable future.  Gitlab does have an automatic [registry cleanup](https://docs.gitlab.com/ee/user/packages/container_registry/#enable-the-cleanup-policy) function that can be set, and in the future, this built-in cleanup policy may negate the need for this script.  For now, we like having the ability to delete images immediately, which is what this script allows us to do.  

## Like what you see?

<a href="http://10up.com/contact/"><img src="https://10up.com/uploads/2016/10/10up-Github-Banner.png" width="850" alt="Work with us at 10up"></a>