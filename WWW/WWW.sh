#!/bin/bash

# Global Variables
apache_file="/etc/apache2/sites-available/www.conf"
apache_server_admin="c@chse.dev"

# Check for root, and bail if not root.
if [ "$(/usr/bin/whoami)" != 'root' ]; then
    echo -e "Error: You have to execute this script as root.\nMaybe try running the following command:\nsudo !!"
    exit 1
fi

# Do we have dialog?
if ! [ -x "$(command -v dialog)" ]; then
    echo -e "Error: dialog is not installed.\nMaybe try running the following command:\nsudo apt install dialog -y" >&2
    exit 1
fi

# Generate two random passwords, one for the user account, and one for the database if needed.
# shellcheck disable=SC2120
generatePassword() {
    local passwordLength=128
    # shellcheck disable=SC2155,SC2086
    local generatedPW="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | /usr/bin/head -c${1:-$passwordLength};echo;)"
    echo "$generatedPW"
}
# shellcheck disable=SC2119
generatedPassword1="$(generatePassword)"
# shellcheck disable=SC2119
generatedPassword2="$(generatePassword)"

# Get HTTPS certificate from Let's Encrypt.
doHTTPS() {
    /usr/bin/sudo /usr/bin/systemctl restart apache2
    /usr/bin/sudo /usr/bin/certbot certonly --apache -d "$1"
    sed -i '/#Include \/etc\/letsencrypt\/options-ssl-apache.conf/s/^# *//' $apache_file
    sed -i '/#SSLCertificateFile \/etc\/letsencrypt\/live\/'"$1"'\/fullchain.pem/s/^# *//' $apache_file
    sed -i '/#SSLCertificateKeyFile \/etc\/letsencrypt\/live\/'"$1"'\/privkey.pem/s/^# *//' $apache_file
    /usr/bin/sudo /usr/bin/systemctl restart apache2
}

doApacheDocRoot() {
    echo "<VirtualHost *:80>
ServerName $1
Redirect permanent / https://$1/
</VirtualHost>

<VirtualHost *:443>
ServerAdmin $apache_server_admin
ServerName $1
DocumentRoot /var/www/$1
<IfModule mod_headers.c>
Header always set Strict-Transport-Security \"max-age=15552000; includeSubDomains\"
Header always set Permissions-Policy: interest-cohort=()
</IfModule>
#/Include /etc/letsencrypt/options-ssl-apache.conf
#/SSLCertificateFile /etc/letsencrypt/live/$1/fullchain.pem
#/SSLCertificateKeyFile /etc/letsencrypt/live/$1/privkey.pem
</VirtualHost>
" >> $apache_file
}

# Create a simple HTML website.
doSimpleHTML() {
    /usr/bin/mkdir /var/www/"$1"
    /usr/bin/chown -R www-data:www-data /var/www/"$1"/
    doApacheDocRoot "$1"
    #doHTTPS "$1"
    echo "ErrorDocument 404 https://$1" >> /var/www/"$1"/.htaccess
    /usr/bin/clear
}

# Create a redirect to another website.
doRedirect() {
    # $1 is hostname
    # $2 is dest
    # $3 is true (disregard path) or false (keep path)
    if [ "$3" = "true" ]; then
        redirect="RedirectMatch ^ https://$2"
    else
        redirect="Redirect permanent / https://$2"
    fi
    echo "<VirtualHost *:80>
ServerName $1
Redirect permanent / https://$1/
</VirtualHost>

<VirtualHost *:443>
ServerAdmin $apache_server_admin
ServerName $1
$redirect
<IfModule mod_headers.c>
Header always set Strict-Transport-Security \"max-age=15552000; includeSubDomains\"
Header always set Permissions-Policy: interest-cohort=()
</IfModule>
#/Include /etc/letsencrypt/options-ssl-apache.conf
#/SSLCertificateFile /etc/letsencrypt/live/$1/fullchain.pem
#/SSLCertificateKeyFile /etc/letsencrypt/live/$1/privkey.pem
</VirtualHost>
" >> $apache_file
    #doHTTPS "$1"
}

# Create a reverse proxy to another website.
doReverseProxy() {
    # $1 is hostname
    # $2 is dest
    echo "<VirtualHost *:80>
ServerName $1
Redirect permanent / https://$1/
</VirtualHost>

<VirtualHost *:443>
ServerAdmin $apache_server_admin
ServerName $1
<IfModule mod_headers.c>
Header always set Strict-Transport-Security \"max-age=15552000; includeSubDomains\"
Header always set Permissions-Policy: interest-cohort=()
</IfModule>
ProxyPreserveHost On
ProxyPass /.well-known !
<Location />
ProxyPass http://$2/
ProxyPassReverse http://$2/
</Location>
#/Include /etc/letsencrypt/options-ssl-apache.conf
#/SSLCertificateFile /etc/letsencrypt/live/$1/fullchain.pem
#/SSLCertificateKeyFile /etc/letsencrypt/live/$1/privkey.pem
</VirtualHost>
" >> $apache_file
    #doHTTPS "$1"
}

# Create a basic WordPress site.
doWordPress() {
    DB_Name="${1//./}"
    DB_PW=$(<~/DB_PW.txt)
    WP_Username="Chase"

    # Check for WP-CLI
    if [ ! -e "/usr/local/bin/wp" ]; then
        /usr/bin/curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && /usr/bin/chmod +x wp-cli.phar && /usr/bin/sudo /usr/bin/mv wp-cli.phar /usr/local/bin/wp
    fi
    /usr/bin/sudo /usr/local/bin/wp cli update
    /usr/bin/mkdir /var/www/"$1"
    /usr/bin/chown -R www-data:www-data /var/www/"$1"/
    doApacheDocRoot "$1"
    #doHTTPS "$1"
    cd /var/www/"$1"/ || exit
    /usr/bin/wget http://wordpress.org/latest.tar.gz
    /usr/bin/tar -xzvf latest.tar.gz
    /usr/bin/mv wordpress/* .
    /usr/bin/rm -r wordpress/
    /usr/bin/rm latest.tar.gz
    /usr/bin/mysql -uroot -p"$DB_PW" -e "CREATE DATABASE $DB_Name;"
    /usr/bin/mysql -uroot -p"$DB_PW" -e "CREATE USER $DB_Name@localhost IDENTIFIED BY '$generatedPassword1';"
    /usr/bin/mysql -uroot -p"$DB_PW" -e "GRANT ALL PRIVILEGES ON $DB_Name.* TO '$DB_Name'@'localhost';"
    /usr/bin/mysql -uroot -p"$DB_PW" -e "FLUSH PRIVILEGES;"
    /usr/local/bin/wp config create --dbname="$DB_Name" --dbuser="$DB_Name" --dbpass="$generatedPassword1" --allow-root
    /usr/local/bin/wp core install --url=https://"$1" --title="$1" --admin_user="$WP_Username" --admin_password="$generatedPassword2" --admin_email="$apache_server_admin" --allow-root
    /usr/local/bin/wp plugin install maintenance --activate --allow-root
    /usr/local/bin/wp theme delete twentynineteen --allow-root
    /usr/local/bin/wp theme delete twentytwenty --allow-root
    /usr/local/bin/wp site empty --yes --allow-root
    /usr/local/bin/wp plugin delete akismet --allow-root
    /usr/local/bin/wp plugin delete hello --allow-root
    /usr/local/bin/wp rewrite structure '/%postname%/' --allow-root
    /usr/local/bin/wp option update default_comment_status closed --allow-root
    /usr/local/bin/wp post create --post_type=page --post_status=publish --post_title='Home' --allow-root
    /usr/local/bin/wp plugin install all-404-redirect-to-homepage --activate --allow-root
    /usr/local/bin/wp plugin install autoptimize --activate --allow-root
    /usr/local/bin/wp plugin install insert-headers-and-footers --activate --allow-root
    /usr/local/bin/wp plugin install better-wp-security --activate --allow-root
    /usr/local/bin/wp plugin install redirection --activate --allow-root
    /usr/local/bin/wp plugin install wp-super-cache --activate --allow-root
    /usr/local/bin/wp plugin install wordpress-seo --activate --allow-root
    #/usr/local/bin/wp plugin install adminimize --activate --allow-root
    /usr/local/bin/wp plugin install capability-manager-enhanced --activate --allow-root
    /usr/local/bin/wp plugin install host-webfonts-local --activate --allow-root
    /usr/local/bin/wp plugin install hcaptcha-for-forms-and-more --activate --allow-root
    /usr/bin/chown -R www-data:www-data /var/www/"$1"/

    /usr/bin/clear
    echo Your WP Login:
    echo https://"$1"/wp-admin
    echo "$WP_Username"
    echo "$generatedPassword2"
    echo
    echo
    echo Go configure all the plugins now.
    echo
    echo
    echo Install any additional plugins.
    echo Atomic Blocks
    echo Adminimize
    echo WP Mail SMTP
    echo Contact Form 7
    echo Email Subscribers and Newsletters
    echo Ultimate Member
    echo WooCommerce
}

# POST to CloudFlare with our domain & IP.
postCF() {
    ip=$(/usr/bin/curl -4 https://icanhazip.com/)
    auth_email="cf@chse.dev"
    auth_key=$(<~/CF_auth_key.txt)

    /usr/bin/curl -X POST "https://api.cloudflare.com/client/v4/zones/$2/dns_records" \
        -H "X-Auth-Email: $auth_email" \
        -H "X-Auth-Key: $auth_key" \
        -H "Content-Type: application/json" \
        --data '{"type":"A","name":"'"$1"'","content":"'"$ip"'","ttl":1,"proxied":'"$3"'}'

}

# Tell CloudFlare we want "proxied" mode.
orangeCF() {
    # $1 is our domain
    # $2 is our zone id
    echo "\$CF $2 $1 true" >> /root/ddns.sh
    echo "/usr/bin/sleep 3" >> /root/ddns.sh
    postCF "$1" "$2" "true"
}

# Tell CloudFlare we don't want "proxied" mode.
grayCF() {
    # $1 is our domain
    # $2 is our zone id
    echo "\$CF $2 $1 false" >> /root/ddns.sh
    echo "/usr/bin/sleep 3" >> /root/ddns.sh
    postCF "$1" "$2" "false"
}

# Ask the user what their hostname is.
siteName=$(/usr/bin/dialog --stdout --title "Hostname" --inputbox "What is your site's hostname? (i.e. site.chse.dev)" 0 0)
/usr/bin/clear

# If siteName has more than one period in it:
if [ "$(echo "$siteName" | /usr/bin/grep -o '\.' | /usr/bin/wc -l)" -gt 1 ]; then
    # Remove the first period and everything before it.
    rootDomain=$(echo "$siteName" | /usr/bin/cut -d'.' -f2-)
else
    # Otherwise, just use the siteName.
    rootDomain="$siteName"
fi

# Look in ~/ddns.sh for the zone ID of the root domain.
if /usr/bin/grep -q "\$CF" /root/ddns.sh; then
    zoneID=$(/usr/bin/grep "\$CF" /root/ddns.sh | /usr/bin/grep "$rootDomain" | cut -d' ' -f2 | head -n 1)
    if [ -z "$zoneID" ]; then
        zoneID=$(/usr/bin/dialog --stdout --title "Cloudflare Zone ID" --inputbox "What is $rootDomain's Zone ID?" 0 0)
    fi
else
    zoneID=$(/usr/bin/dialog --stdout --title "Cloudflare Zone ID" --inputbox "What is $rootDomain's Zone ID?" 0 0)
fi
/usr/bin/clear
/usr/bin/dialog --stdout --title "Cloudflare Proxy?" --yesno "Are we proxying $siteName through Cloudflare?" 0 0
cloudflare_proxy_question=$?
/usr/bin/clear
if [ "$cloudflare_proxy_question" -eq 0 ]; then
    orangeCF "$siteName" "$zoneID"
elif [ "$cloudflare_proxy_question" -eq 1 ]; then
    grayCF "$siteName" "$zoneID"
else
    exit 1
fi

# Ask the user what type of site they want to use.
optionsForSite=$(/usr/bin/dialog --stdout --menu "What type of site do you want?" 0 0 0 1 "WordPress" 2 "Reverse Proxy" 3 "HTTP" 4 "Redirect")
/usr/bin/clear
if [ "$optionsForSite" -eq 1 ]; then
    doWordPress "$siteName"
elif [ "$optionsForSite" -eq 2 ]; then
    destProxySite=$(/usr/bin/dialog --stdout --title "Reverse Proxy" --inputbox "Where is $siteName going? (i.e. 192.168.86.12:1337)" 0 0)
    /usr/bin/clear
    doReverseProxy "$siteName" "$destProxySite"
elif [ "$optionsForSite" -eq 3 ]; then
    doSimpleHTML "$siteName"
elif [ "$optionsForSite" -eq 4 ]; then
    destSite=$(/usr/bin/dialog --stdout --title "Hostname" --inputbox "Where is $siteName going? (i.e. dest.chse.dev)" 0 0)
    /usr/bin/clear
    redirectType=$(/usr/bin/dialog --stdout --menu "What type of redirect?" 0 0 0 1 "Disregard Path" 2 "Keep Path")
    /usr/bin/clear
    if [ "$redirectType" -eq 1 ]; then
        doRedirect "$siteName" "$destSite" "true"
    elif [ "$redirectType" -eq 2 ]; then
        doRedirect "$siteName" "$destSite" "false"
    else
        exit 1
    fi
else
    exit 1
fi

/usr/bin/systemctl restart apache2
