# NativeScript Simple Setup

## What is it?

Small script that lets you automatically install NativeScript and all necessary dependencies on Mac. It can be re-run many times as the dependencies would be simply reinstalled. This script is made, so developers don't need to manually update dependencies, paths etc. on their machines. It also helps to avoid overcomplicated solutions like Ansible.

## How does it work?

Script makes necessary checks for versions at the top of the file. Once a change is detected, it will install the version from top of the file. It doesn't compare Semver for the time being. It only checks for version difference.

## What does the Setup Script include?

* Brew - the latest
* Xcode tools - the latest
* Node - 18.14.2
* NPM - 9.5.1
* NVM - 0.39.3
* NativeScript - 8.4.7
* Python - 2.7.18
* PyEnv - 2.7.18
* Ruby - 3.1.1
* Pods - 1.11.3
* Java - 11.0.15

Both Bash and ZSH are supported.

Please mind that Python 2 is still required by NativeScript.

## Run

Insert setup.sh file in your NS root project directory & run:

```
sh setup.sh
```

## Issues?

Any PRs are welcome. Thank you.
