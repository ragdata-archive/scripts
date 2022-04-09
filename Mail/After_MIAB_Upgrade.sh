#!/bin/bash

# Fix links/title of roundcube.
sed -i 's/https:\/\/mailinabox.email\//https:\/\/chse.dev\//g' /usr/local/lib/roundcubemail/config/config.inc.php
sed -i 's/mail.chse.dev Webmail/Mail/g' /usr/local/lib/roundcubemail/config/config.inc.php
