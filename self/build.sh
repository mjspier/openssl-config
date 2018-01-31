#!/bin/bash
openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout key.pem -out cert.pem -config cert.conf -extensions 'ca_reqext'
