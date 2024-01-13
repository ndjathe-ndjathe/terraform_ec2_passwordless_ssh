#!/bin/bash
echo "${public_key}" > /home/ec2-user/.ssh/id_rsa.pub
echo "${private_key}" > /home/ec2-user/.ssh/id_rsa
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa*
chmod -R 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/*