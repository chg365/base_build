#!/bin/bash

#开发端口
firewall-cmd --zone=public --add-port=80/tcp --permanent

firewall-cmd --reload
