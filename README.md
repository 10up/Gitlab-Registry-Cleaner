# GitLab Registry Cleaner

> Bash script using the GitLab API to delete images from a GitLab container registry. Supports regex and deleting images older than a specific age.

[![Support Level](https://img.shields.io/badge/support-stable-blue.svg)](#support-level) [![Release Version](https://img.shields.io/github/release/10up/Gitlab-Registry-Cleaner.svg)](https://github.com/10up/Gitlab-Registry-Cleaner/releases/latest) [![MIT License](https://img.shields.io/github/license/10up/Gitlab-Registry-Cleaner.svg)](https://github.com/10up/Gitlab-Registry-Cleaner/blob/develop/LICENSE.md)

## How to Use
Copy `config-sample.sh` to `config.sh` and fill in the variables to match the needs of your project.  The `config-sample.sh` file is documented with comments.  

This script uses v4 of the GitLab API.  It is tested against a self-hosted GitLab instance and it is unknown if these same commands work on projects hosted on gitlab.com.  

This is a bash script, so a Linux type shell is required to use it.  It has been tested in Ubuntu, but it should run fine on MacOS and any version of Linux.  

To run the script, first give it execution permissions:

`chmod +x clean-registry.sh`

Running the script:

`./clean-registry.sh`

There are no command line arguments for this script and it is configured entirely with the `config.sh` file.

This script removes the tags from the container registry, but does not actually delete the images (because this is how GitLab works).  To delete the images, connect to your GitLab instance (or open a shell inside your GitLab Docker instance) and run the following:

`gitlab-ctl registry-garbage-collect -m`

You may need to use `sudo` for that command to work.  This will take a while, but afterwards you should see a reduction in the disk space used if you've deleted any Docker images with this script.  

## Frequently Asked Questions

### Why use this instead of GitLab's simliar function?

GitLab does have an automatic [registry cleanup](https://docs.gitlab.com/ee/user/packages/container_registry/#enable-the-cleanup-policy) function that can be set, and in the future, this built-in cleanup policy may negate the need for this script.  For now, we like having the ability to delete images immediately, which is what this script allows us to do.

## Support Level

**Stable:** 10up is not planning to develop any new features for this, but will still respond to bug reports and security concerns. We welcome PRs, but any that include new features should be small and easy to integrate and should not include breaking changes. We otherwise intend to keep this tested up to the most recent version of WordPress.

## Changelog

A complete listing of all notable changes to GitLab Registry Cleaner are documented in [CHANGELOG.md](https://github.com/10up/Gitlab-Registry-Cleaner/blob/develop/CHANGELOG.md).

## Contributing

Please read [CODE_OF_CONDUCT.md](https://github.com/10up/Gitlab-Registry-Cleaner/blob/develop/CODE_OF_CONDUCT.md) for details on our code of conduct, [CONTRIBUTING.md](https://github.com/10up/Gitlab-Registry-Cleaner/blob/develop/CONTRIBUTING.md) for details on the process for submitting pull requests to us, and [CREDITS.md](https://github.com/10up/Gitlab-Registry-Cleaner/blob/develop/CREDITS.md) for a listing of maintainers of, contributors to, and libraries used by GitLab Registry Cleaner.

## Like what you see?

<a href="http://10up.com/contact/"><img src="https://10up.com/uploads/2016/10/10up-Github-Banner.png" width="850" alt="Work with us at 10up"></a>
