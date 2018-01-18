# cython: profile=True
from __future__ import print_function
from libc.stdlib cimport malloc, free
import numpy as np
cimport numpy as np

np.import_array()

cdef extern from 'ueye.h':
    # --- Structs ---
    ctypedef struct IMAGE_FORMAT_INFO:
       int nFormatID
       unsigned int nWidth
       unsigned int nHeight
       int nX0
       int nY0
       unsigned int nSupportedCaptureModes
       unsigned int nBinningMode
       unsigned int nSubsamplingMode
       char strFormatName[64]
       double dSensorScalerFactor
       unsigned int nReserved[22]
    ctypedef struct IMAGE_FORMAT_LIST:
        unsigned int nSizeOfListEntry
        unsigned int nNumListElements
        unsigned int nReserved[4]
        IMAGE_FORMAT_INFO FormatInfo[1]
    # --- Defines ---
        # --- Displaymodes
    int IS_SET_DM_DIB
        # --- Colormodes ---
    int IS_CM_BGR8_PACKED
    # --- Enums ---
    ctypedef enum IMAGE_FORMAT_CMD:
        IMGFRMT_CMD_GET_NUM_ENTRIES = 1
        IMGFRMT_CMD_GET_LIST = 2
        IMGFRMT_CMD_SET_FORMAT = 3
        IMGFRMT_CMD_GET_ARBITORY_AOI_SUPPORTED = 4
        IMGFRMT_CMD_GET_FORMAT_INFO = 5

    ctypedef enum EXPOSURE_CMD:
        IS_EXPOSURE_CMD_SET_EXPOSURE =  12
    # --- Functions ---
    int is_InitCamera(unsigned int* hcam, void* hwand)
    int is_ExitCamera(unsigned int hcam)
    int is_SetDisplayMode(unsigned int hcam, int mode)
    int is_SetColorMode(unsigned int hcam, int mode)
    int is_AllocImageMem(unsigned int hcam, int width, int height, int bitspixel, char** ppcImgMem, int* pid)
    int is_ImageFormat(unsigned int hcam, unsigned int ncommand, void *pParam, unsigned int nsizeofparam)
    int is_SetImageMem(unsigned int hcam, char* pcImageMem, int pid_id)
    int is_FreezeVideo(unsigned int hcam, int wait)
    int is_GetImageMemPitch(unsigned int hcam, int* pitch)
    int is_CaptureVideo(unsigned int hcam, int wait)
    int is_FreeImageMem(unsigned int hcam, char* pcImgMem, int imgId)
    int is_StopLiveVideo(unsigned int hcam, int wait)
    int is_SetFrameRate(unsigned int hcam, double fps, double* newFps)
    int is_Exposure(unsigned int hCam, unsigned int nCommand, void* pParam, unsigned int cbSizeOfParam)

cdef class Cam:
    cdef:
        unsigned int hCam
        int pid
        char *pcImgMem
        str displaymode
        str colormode
        int bitspixel
        int width
        int height
        int format_id
        object init
        object capture
        object errorCodes
        IMAGE_FORMAT_LIST* image_format_list
        cdef np.npy_intp dims[3]
    def __cinit__(self, format_id, displaymode="dib", colormode="bgr8_packed", hCam=0):
        self._get_error_codes()
        self.init = False
        self.capture = False
        self.hCam = hCam
        self._init_camera()
        self.get_supported_formats()
        self.displaymode=displaymode
        self.colormode=colormode
        self.set_display_mode(self.displaymode)
        self.set_color_mode(self.colormode)
        self.format_id = format_id
        self.init = True
        self.set_format(self.format_id)
        np.Py_INCREF(np.NPY_UINT8)


    def __dealloc__(self):
        self._free_image_mem()
        self.exit_camera()

    def _init_camera(self):
        self.error_handler(is_InitCamera(&self.hCam, NULL))

    def exit_camera(self):
        self.error_handler(is_ExitCamera(self.hCam))

    def set_display_mode(self, mode):
        if mode is 'dib':
            self.error_handler(is_SetDisplayMode(self.hCam, IS_SET_DM_DIB))
        else:
            raise ValueError(mode, " is not a displaymode")
        self._alloc_image_mem()

    def set_color_mode(self, mode):
        if mode is 'bgr8_packed':
            self.error_handler(is_SetColorMode(self.hCam, IS_CM_BGR8_PACKED))
            self.bitspixel = 24
        else:
            raise ValueError(mode, " is not a colormode")
        self._alloc_image_mem()

    def set_framerate(self, double framerate):
        cdef double newFps
        self.error_handler(is_SetFrameRate(self.hCam, framerate, &newFps))
        return newFps

    def set_exposure(self, double exposure):
        self.error_handler(is_Exposure(self.hCam, IS_EXPOSURE_CMD_SET_EXPOSURE, &exposure, 8))
        return exposure

    def set_format(self, int format_id):
        cdef unsigned int i
        cdef IMAGE_FORMAT_INFO format_info
        for i in range(self.image_format_list.nNumListElements):
            format_info = self.image_format_list.FormatInfo[i]
            if format_id is format_info.nFormatID:
                self.error_handler(is_ImageFormat(self.hCam, IMGFRMT_CMD_SET_FORMAT, &format_id, 4))
                self.height = format_info.nHeight
                self.width = format_info.nWidth
                self._alloc_image_mem()
                return
        raise ValueError("Format: ", format_id, "is not supported on your camera")

    def get_supported_formats(self):
        cdef unsigned int count
        cdef unsigned int bytesneeded = sizeof(IMAGE_FORMAT_LIST)
        self.error_handler(is_ImageFormat(self.hCam, IMGFRMT_CMD_GET_NUM_ENTRIES, &count, sizeof(count)))
        bytesneeded += (count - 1) * sizeof(IMAGE_FORMAT_INFO)
        cdef void* ptr
        ptr = malloc(bytesneeded)
        cdef IMAGE_FORMAT_LIST* pformatList = <IMAGE_FORMAT_LIST *> ptr
        pformatList.nSizeOfListEntry = sizeof(IMAGE_FORMAT_INFO)
        pformatList.nNumListElements = count
        ret = is_ImageFormat(self.hCam, IMGFRMT_CMD_GET_LIST, pformatList, bytesneeded)
        cdef unsigned int i, n = pformatList.nNumListElements
        cdef IMAGE_FORMAT_INFO formatInfo
        self.image_format_list = pformatList

    def _alloc_image_mem(self):
        if self.init is False:
            return
        self.error_handler(is_AllocImageMem(self.hCam, self.width, self.height, self.bitspixel, &self.pcImgMem, &self.pid))
        self._set_image_mem()
        cdef int colorspace = ((self.bitspixel+7)/8)
        self.dims[0]=self.height
        self.dims[1]=self.width
        self.dims[2]=colorspace

    def _set_image_mem(self):
        self.error_handler(is_SetImageMem(self.hCam, self.pcImgMem, self.pid))

    def _free_image_mem(self):
        self.error_handler(is_FreeImageMem(self.hCam, self.pcImgMem, self.pid))

    def _freeze_video(self, isWait = 0):
        self.error_handler(is_FreezeVideo(self.hCam, isWait))

    def start_capture(self, isWait = 0):
        self.capture = True
        self.error_handler(is_CaptureVideo(self.hCam, isWait))

    def stop_capture(self, isWait = 0):
        self.capture = False
        self.error_handler(is_StopLiveVideo(self.hCam, isWait))

    def freeze_video(self, isWait = 0):
        self._freeze_video(isWait)
        return np.PyArray_SimpleNewFromData(3, self.dims, np.NPY_UINT8, self.pcImgMem)

    def capture_video(self):
        if self.capture is False:
            raise Exception("Capture Mode has to be turned on")
        return np.PyArray_SimpleNewFromData(3, self.dims, np.NPY_UINT8, self.pcImgMem)

    def error_handler(self, ret):
        if ret is not 0:
            ret = str(ret)
            raise Exception(self.errorCodes[ret] + " \nPlease check the IDS website for more Information")

    def _get_error_codes(self):
        self.errorCodes = {}
        with open("ret.txt") as f:
            for line in f:
                value, key = line.split()
                self.errorCodes[key] = value
