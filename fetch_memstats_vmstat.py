#!/usr/bin/env python3
import re, sys
from subprocess import check_output, call, PIPE, Popen
from time import sleep
import signal
import threading

PERIOD_SECS = 0.5
CPU_PERIOD_SECS = 1
x = 0.0

def to_mb(n_str):
    return int(n_str)/1024

class Wall:
    def write(self, msg):
        call('wall -n "{}"'.format(str(msg)), shell=True)
    def flush(self):
        pass
    def close(self):
        pass

usercpu = syscpu = totalcpu = 0.0
def thread_get_cpu():
    global usercpu, syscpu, totalcpu
    process = Popen(
        'mpstat -P all {}'.format(CPU_PERIOD_SECS),
        stdout=PIPE,
        shell=True,
        encoding='utf-8',)

    while True:
        try:
            line = process.stdout.readline()
            words = line.split()
            if len(words) and words[2] == "all":
                usercpu = float(words[3])
                syscpu = float(words[5])
                totalcpu = 100.0 - float(words[12])
            #print("cpu: {} {} {:.2f}".format(usercpu, syscpu, totalcpu))
        except Exception as e:
            print("error: ", e)

#launch thread taht gets cpu usage every second
#this doesn't work on guest, so lets not run it
#t = threading.Thread(target=thread_get_cpu)
#t.daemon = True
#t.start()

#set where we output to
fp = None
if len(sys.argv) == 1 or sys.argv[1] == "stdout":
    fp = sys.stdout
#so i heard you like hacky stuff
elif sys.argv[1] == "wall":
    fp = Wall()
else:
    fp = open(sys.argv[1], "w")
    signal.signal(signal.SIGTERM, lambda _a,_b: fp.close)

fp.write("t, non-cache-buffer-used-mem, kernel-mem, total-used-mem, max-mem, usercpu, syscpu, totalcpu\n")
try:
    while True:
        #get vmstat mem usage
        #out = check_output("vmstat -s", shell=True)
        #lines = out.splitlines()
        #match = re.search("(\d*)\s+K total memory", str(lines[0]))
        #total = match.group(1)
        #match = re.search("(\d*)\s+K used memory", str(lines[1]))
        #used = match.group(1)

        #get cpu from mpstat
        #out = check_output("mpstat -P ALL", shell=True).decode("ASCII")
        #lines = out.splitlines()
        #no = "\d+\.\d+\s+" * 9
        #pat = "all\s*"+no+"(\d+\.\d)"
        #match = re.search(pat, str(lines[3]))
        #idle = match.group(1)
        #cpu = 100.0 - float(idle)

        #out = check_output("iostat", shell=True).decode("ASCII")
        #lines = out.splitlines()
        #pat = "(\d+\.\d+)\s*(\d+\.\d+)\s*(\d+\.\d+)\s*(\d+\.\d+)\s*(\d+\.\d+)\s*(\d+\.\d+)"
        #match = re.search(pat, str(lines[3]))
        #usercpu = match.group(1)
        #syscpu = match.group(3)
        #totalcpu = 100.0 - float(match.group(6))

        #https://stackoverflow.com/questions/41224738/how-to-calculate-system-memory-usage-from-proc-meminfo-like-htop
        #https://unix.stackexchange.com/questions/97261/how-much-ram-does-the-kernel-use:
        #   The 'Slab' field in the /proc/meminfo file is tracking information about used slab physical memory.
        data = { "MemFree": 0, "MemTotal": 0, "Buffers": 0, "Cached": 0, "Slab": 0 }
        def extract_mb(line):
            return to_mb(re.search("\s*(\d+)\s*kB", line).group(1))

        with open("/proc/meminfo") as f:
             for line in f.readlines():
                 for k in data.keys():
                    if line.startswith(k):
                        data[k] = extract_mb(line)
                        break

        total_used_mem = data["MemTotal"] - data["MemFree"]
        non_cache_buffer = total_used_mem - (data["Cached"] + data["Buffers"])
        kernel_mem = data["Slab"]
        maxmem = data["MemTotal"]

        fp.write("!STATS! {}, {:.0f}, {:.0f}, {:.0f}, {:.0f}, {}%, {}%, {:.2f}%\n".format(
                x, non_cache_buffer, kernel_mem, total_used_mem, maxmem, usercpu, syscpu, totalcpu)) 
        fp.flush()

        x += PERIOD_SECS
        sleep(PERIOD_SECS)
except Exception as e:
    print(e)
