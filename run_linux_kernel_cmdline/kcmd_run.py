#!/usr/bin/env python3
# eg:  <some kernel args> krun="/home/ubuntu/test.py" <more kernel args> --env=a=b --env=x=y
#
from subprocess import call, Popen
from re import finditer, search
import os
from timeit import default_timer as timer

s = timer()

p2 = Popen(["/bin/mount", "-o", "mode=nosuid,nodev,noexec",
            "-t", "sysfs", "sysfs", "/sys"])
p3 = Popen(["/bin/mount", "-t", "tmpfs", "-o",
            "mode=1777,nosuid,nodev,exec,relatime",
            "tmpfs", "/tmp"])
p4 = Popen(["mount", "-t", "tmpfs", "cgroup_root", "/sys/fs/cgroup"])
p4.wait()
os.makedirs("/sys/fs/cgroup/memory")
p5 = Popen(["/bin/mount", "-t", "cgroup", "-o", "memory",
            "memory", "/sys/fs/cgroup/memory"])
p5.wait()

try:
    os.makedirs("/sys/fs/cgroup/memory/limit")
except:
    print("exception: /sys/fs/cgroup/memory/limit probably already exists, continuing")

#TODO: make limit from env or something
p6 = Popen('echo "18790481920" > /sys/fs/cgroup/memory/limit/memory.limit_in_bytes',
           shell=True)
p2.wait()
p3.wait()
p6.wait()

# read cmdline
with open("/proc/cmdline") as fp:
    cmd = fp.read()

if "mount-efs" in cmd:
    if not os.path.exists("/mnt/efs"):
        os.makedirs("/mnt/efs")
    Popen(["/bin/mount", "-t", "efs", "-o",
           "tls,accesspoint=fsap-0e4080b697dc97f69",
           "fs-0d8b7f8f:/", "/mnt/efs"])

# find all env vars, set for current process (and children)
for ev_match in finditer(r'--env=([\w\-\_]*)=([$\\%@+-=:._,\w]*)', cmd):
    k, v = (ev_match.group(1), ev_match.group(2))
    print("adding {} : {}".format(k, v))
    os.environ[k] = v

os.environ['PYTHONIOENCODING'] = "utf-8"

# this wanna stick in other scripts, so lets do it runtime
fcd_addr = os.environ['FCD_ADDR']
sp = fcd_addr.split(':')
dns = f'printf "nameserver {sp[0]}\nnameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 10.1.0.2\n" > /etc/resolv.conf'
# dns = f'printf "nameserver 8.8.8.8\nnameserver 8.8.4.4\n" > /etc/resolv.conf'
# dns = f'printf "nameserver 10.1.0.2\n" > /etc/resolv.conf'
call(dns, shell=True)

# launch the stats printer if this is in the cmdline
if "fetch-stats" in cmd:
    Popen("python3 /fetch_memstats_vmstat.py {}"
          .format("stdout" if "boot.sh" in cmd else "wall"),
          shell=True)  # need to switch between regular init and boot.sh

# extract what's in DOUBLE quotes and eval it
print("cmdline: " + cmd)
match = search(r"krun=\"(.*)\"", cmd)
if match:
    cmd = match.groups()[0]
    t = timer() - s
    print("running kcmd {}, start takes: {}".format(cmd, t))
    call(cmd, shell=True)
else:
    print("kcmd_run couldnt find a valid krun kernel parameter")
