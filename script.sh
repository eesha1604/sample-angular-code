#!/bin/bash

sudo apt update
sudo apt install apache2 -y
sudo service apache2 start 
sudo service apache2 enable
sudo apt install npm -y 
sudo apt install git -y 

sudo openssl req -x509 -nodes -day 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache.key -out /etc/ssl/certs/apache.crt
sudo sed -i -E "s#SSLCertificateFile.*#SSLCertificateFile /etc/ssl/cert/apache.crt#" /etc/apache2/site-avilable/default-ssl.conf

git clone https://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@github.com/fullstacklabs/devops-ci-challenge.git
cd devops-ci-challenge
cd codebase/
tar -xvf rdicidr-0.1.0.tar.gz
cd rdicidr-0.1.0/
npm i 
npm run lint
sudo npm install -g prettier
npm run build
sudo cp -r build /var/www/html
sudo systemctl restart apache2
