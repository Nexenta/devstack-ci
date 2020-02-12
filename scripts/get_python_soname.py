from distutils.sysconfig import get_config_var

soname = get_config_var("INSTSONAME")

print(soname)
