import uuid
from ansible.module_utils.basic import AnsibleModule

projects = {
    'openstack':        0xec,
    'nfs':              0xed,
    'iscsi':            0xee
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
    'queens':           0xa9,
    'rocky':            0xb0,
    'stein':            0xb1,
    'train':            0xb2,
    'ussuri':           0xb3,
    'victoria':         0xb4
}

nfs_branches = {
    'master':           0xa0
}

iscsi_branches = {
    'master':           0xa0
}

openstack_backends = {
    'ns4_nfs':          0x90,
    'ns5_nfs':          0x91,
    'ns4_iscsi':        0x92,
    'ns5_iscsi':        0x93,
    'ned_nbd':          0x94,
    'ned_iscsi':        0x95,
    'ns4_manila':       0x96,
    'ns5_manila':       0x97,
    'lustre':           0x98
}

nfs_backends = {
    'nfs':              0x88
}

iscsi_backends = {
    'iscsi':            0x89
}

openstack_ostypes = {
    'nexentastor4':     0xa1,
    'nexentastor5':     0xa2,
    'firecrest':        0xa3,
    'exascaler':        0xa4,
    'ubuntu':           0xa5,
    'centos':           0xa6
}

nfs_ostypes = {
    'nexentastor5':     0xa2,
    'firecrest':        0xa3,
    'ubuntu':           0xa5,
    'centos':           0xa6
}

iscsi_ostypes = {
    'nexentastor5':     0xa2,
    'firecrest':        0xa3,
    'ubuntu':           0xa5,
    'centos':           0xa6
}

nexentastor4_versions = {
    '4.0.5':            0x40
}

nexentastor5_versions = {
    '5.0':              0x50,
    '5.1':              0x51,
    '5.2':              0x52,
    '5.3':              0x53
}

firecrest_versions = {
    '1.0':              0x30
}

exascaler_versions = {
    '5.1.1':            0xa0
}

ubuntu_versions = {
    '14.04':            0x14,
    '16.04':            0x16,
    '18.04':            0x18,
    '20.04':            0x20
}

centos_versions = {
    '7.7':              0x77,
    '7.8':              0x78
}

common_osversions = {
    'nexentastor4':     nexentastor4_versions,
    'nexentastor5':     nexentastor5_versions,
    'firecrest':        firecrest_versions,
    'exascaler':        exascaler_versions,
    'ubuntu':           ubuntu_versions,
    'centos':           centos_versions
}

config = {
    'openstack': {
        'branches':     openstack_branches,
        'backends':     openstack_backends,
        'ostypes':      openstack_ostypes,
        'osversions':   common_osversions
    },
    'nfs': {
        'branches':     nfs_branches,
        'backends':     nfs_backends,
        'ostypes':      nfs_ostypes,
        'osversions':   common_osversions
    },
    'iscsi': {
        'branches':     iscsi_branches,
        'backends':     iscsi_backends,
        'ostypes':      iscsi_ostypes,
        'osversions':   common_osversions
    }
}

def get_uuid(project, branch, backend, ostype, osversion):
    u = uuid.uuid4()
    b = bytearray.fromhex(u.hex)
    b[0] = projects[project]
    b[1] = config[project]['branches'][branch]
    b[2] = config[project]['backends'][backend]
    b[3] = config[project]['ostypes'][ostype]
    b[4] = config[project]['osversions'][ostype][osversion]
    return str(uuid.UUID(''.join(map(lambda x: '%02x' % x, b))))

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
    ostype = module.params.get('ostype')

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
            'choices':  config[project]['osversions'][ostype].keys(),
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
    module.exit_json(msg='New uuid has been successfully created', changed=True, uuid=result)
 
if __name__ == '__main__':
    main()
