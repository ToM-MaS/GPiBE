Folder "freeswitch"
===================
Scripts to automate build of FreeSwitch.
Used by FreeSwitch's Jenkins configurations below.


Folder "freeswitch/jenkins"
===========================
Jenkins configurations using a copy of the FreeSwitch
scripts above. They also contain the logic to upload
the packages and update a Debian repository server
via SSH using reprepro.

Local Jenkins user was setup via console with
correct SSH key settings.

Restore: See "jenkins" below.


Folder "freeswitch/raspbian-repository"
=====================================
Those files are the initial reprepro configuration files for
the repository.
Just have them available in the right directory for the reprepro
script (in this case: /var/www/<repo-domain>/raspbian).
The user running reprepro needs to have a working GPG setup in ~/.gnupg
to sign the repo files. You should publish the public key in the
webserver directory so that it's available for import from users.


Folder "jenkins"
================
Used Jenkins configurations for GemeinschaftPi continuous integration.
(just a copy from the jobs directory under /var/lib/jenkins/jobs)
Hints to restore:
https://wiki.jenkins-ci.org/display/JENKINS/Administering+Jenkins#AdministeringJenkins-Moving/copying/renamingjobs

