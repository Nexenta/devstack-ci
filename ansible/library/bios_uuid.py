import uuid
from ansible.module_utils.basic import AnsibleModule

projects = {
    'openstack':        0xec,
    'docker':           0xde,
    'kubernetes':       0xb8
}

openstack_branches = {
    'master':           0xa0,
    'icehouse':         0xa1,
    'juno':             0xa2,
    'kilo':             0xa3,
    'liberty':          0xa4,
    'mitaka':           0xa5,
    'newton':           0xa6,
    'ocata':            0xa7,
    'pike':             0xa8,
    'queens':           0xa9
}

docker_branches = {
    'latest':           0xb1,
    'available':        0xb2
}

kubernetes_branches = {
    'latest':           0xb1
}

openstack_backends = {
    'ns4_nfs':          0x90,
    'ns5_nfs':          0x91,
    'ns4_iscsi':        0x92,
    'ns5_iscsi':        0x93,
    'ned_nbd':          0x94,
    'ned_iscsi':        0x95,
    'ns4_manila':       0x96,
    'ns5_manila':       0x97
}

docker_backends = {
    'node1':            0xd1,
    'node2':            0xd2
}

kubernetes_backends = {
    'node1':            0xd1,
    'node2':            0xd2,
    'node3':            0xd3
}

openstack_ostypes = {
    'linux':            0xa2
}

docker_ostypes = {
    'linux':            0xa2
}

kubernetes_ostypes = {
    'linux':            0xa2
}

openstack_osversions = {
    'ubuntu14':         0x14,
    'ubuntu16':         0x16,
    'ubuntu18':         0x18
}

docker_osversions = {
    'ubuntu14':         0x14,
    'ubuntu16':         0x16,
    'ubuntu18':         0x18
}

kubernetes_osversions = {
    'ubuntu16':         0x16,
    'ubuntu18':         0x18
}

config = {
    'openstack': {
        'branches':     openstack_branches,
        'backends':     openstack_backends,
        'ostypes':      openstack_ostypes,
        'osversions':   openstack_osversions
    },
    'docker': {
        'branches':     docker_branches,
        'backends':     docker_backends,
        'ostypes':      docker_ostypes,
        'osversions':   docker_osversions
    },
    'kubernetes': {
        'branches':     kubernetes_branches,
        'backends':     kubernetes_backends,
        'ostypes':      kubernetes_ostypes,
        'osversions':   kubernetes_osversions
    }
}

def get_uuid(project, branch, backend, ostype, osversion):
    u = uuid.uuid4()
    b = bytearray.fromhex(u.hex)
    b[0] = projects[project]
    b[1] = config[project]['branches'][branch]
    b[2] = config[project]['backends'][backend]
    b[3] = config[project]['ostypes'][ostype]
    b[4] = config[project]['osversions'][osversion]
    return str(uuid.UUID(''.join(map(lambda x: "%02x" % x, b))))

def main():
    spec = {
        'project': {
            'required': True,
            'choices':  projects.keys(),
            'type':     'str'
        },
        'branch': {
            'required': True,
            'type':     'str'
        },
        'backend': {
            'required': True,
            'type':     'str'
        },
        'ostype': {
            'required': True,
            'type':     'str'
        },
        'osversion': {
            'required': True,
            'type':     'str'
        }
    }

    module = AnsibleModule(argument_spec=spec)
    project = module.params.get('project')

    spec = {
        'project': {
            'required': True,
            'choices':  projects.keys(),
            'type':     'str'
        },
        'branch': {
            'required': True,
            'choices':  config[project]['branches'].keys(),
            'type':     'str'
        },
        'backend': {
            'required': True,
            'choices':  config[project]['backends'].keys(),
            'type':     'str'
        },
        'ostype': {
            'required': True,
            'choices':  config[project]['ostypes'].keys(),
            'type':     'str'
        },
        'osversion': {
            'required': True,
            'choices':  config[project]['osversions'].keys(),
            'type':     'str'
        }
    }

    module = AnsibleModule(argument_spec=spec)
    project = module.params.get('project')
    branch = module.params.get('branch')
    backend = module.params.get('backend')
    ostype = module.params.get('ostype')
    osversion = module.params.get('osversion')
    result = get_uuid(project, branch, backend, ostype, osversion)
    module.exit_json(msg="New uuid has been successfully created", changed=True, uuid=result)
 
if __name__ == "__main__":
    main()
