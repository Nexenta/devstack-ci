import os, fcntl, time, random, errno
from ansible.module_utils.basic import AnsibleModule

lock_wait = 60
lock_dir = '/tmp'

def lock_path(lock_name):
    return '%s/%s.lock' % (lock_dir, lock_name)

def lock_cleanup(lock_name):
    lock_file = lock_path(lock_name)
    if os.path.isfile(lock_file):
        os.unlink(lock_file)
        return 0
    return errno.ENOENT

def lock_acquire(lock_name):
    lock_file = lock_path(lock_name)
    lock_size = 0
    while lock_size == 0:
        lock_fd = os.open(lock_file, os.O_CREAT | os.O_WRONLY)
        fcntl.flock(lock_fd, fcntl.LOCK_EX)
        lock_stat = os.fstat(lock_fd)
        if lock_stat.st_size == 0:
            lock_size = os.write(lock_fd, lock_name)
            os.close(lock_fd)
        else:
            os.close(lock_fd)
            time.sleep(random.uniform(1, lock_wait))
    return 0

def lock_release(lock_name):
    lock_file = lock_path(lock_name)
    if not os.path.isfile(lock_file):
        return errno.ENOENT
    lock_fd = os.open(lock_file, os.O_RDWR)
    fcntl.flock(lock_fd, fcntl.LOCK_EX)
    lock_text = os.read(lock_fd, len(lock_name))
    if lock_text == lock_name:
        os.ftruncate(lock_fd, 0)
    os.close(lock_fd)
    return 0

def main():
    spec = {
        'name': {
            'required': True,
            'type':     'str'
        },
        'action': {
            'required': True,
            'choices':  ['acquire', 'release', 'cleanup'],
            'type':     'str'
        }
    }

    actions = {
        'acquire': lock_acquire,
        'release': lock_release,
        'cleanup': lock_cleanup
    }

    module = AnsibleModule(argument_spec=spec)

    lock_name = module.params.get('name')
    lock_action = module.params.get('action')

    rc = actions[lock_action](lock_name)

    if rc == 0:
        result = {
            'changed': True,
            'msg': 'Lock name: %s, action: %s, result: success' % (
                lock_name, lock_action)
        }
        module.exit_json(**result)
    else:
        result = {
            'changed': False,
            'msg': 'Lock name: %s, action: %s, result: %s' % (
                lock_name, lock_action, os.strerror(rc))
        }
        module.fail_json(**result)
 
if __name__ == "__main__":
    main()
