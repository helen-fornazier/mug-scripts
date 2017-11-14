#!/bin/bash

sudo sh -c "echo 8 > /proc/sys/kernel/printk"
sudo modprobe vimc
#sudo sh -c "echo -n 'module vimc +p' > /sys/kernel/debug/dynamic_debug/control"
sudo sh -c "echo -n 'module media +p' > /sys/kernel/debug/dynamic_debug/control"
