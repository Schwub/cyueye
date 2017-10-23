from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize 

ext = Extension("cyueye", sources = ["cyueye.pyx"], libraries=["ueye_api"])

setup(
    name="cyueye", ext_modules = cythonize([ext])
)
