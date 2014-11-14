# Packagist Cookbook

This is a cookbook that also functions as a [motherbrain](github.com/RiotGames/motherbrain)
plugin. You will need to read the docs for that project, but the idea is to
allow you to bootstrap a packagist web app with a list of known projects and to
traverse their repositories with workers connected to rabbitmq.

At the time of this writing, Motherbrain intermittently sends bad requests (HTTP
400) to AWS and the cluster provisioning just dies. However, you may be left in
a recoverable state when this happens. Confirm the state of the cluster before
doing something rash like blowing them all away and starting over. Similarly, if
the initial chef run doesn't work out, you may need to copy the most recent
provision.json from your `~/.mb` directory and purge the chef nodes and clients
and use the bootstrap command. After ther first chef run works for all the
nodes, you can use the upgrade command to cause a chef run on the nodes in the
environment (amongst other things that the upgrade command is actually for).

For whatever reason, the workers don't always start running down their queues
after the first successful run through. Using `knife ssh` to stop and start the
supervisord service has been generally successful for working around this.

The bootstrapping process for the packagist app makes use of commands provided
in a fork of the packagist repo [here](github.com/winmillwill/packagist#drupal)
and the list of projects to add is hardcoded in this cookbook. For now, all this
apparatus does is make a composer repository out of drupal.org for projects with
7.x releases.

