from __future__ import print_function
from libc.stdlib cimport malloc, free
import numpy as np

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
    int IS_SET_DM_DIB
    int IS_CM_BGR8_PACKED
    # --- Enums ---
    ctypedef enum IMAGE_FORMAT_CMD:
        IMGFRMT_CMD_GET_NUM_ENTRIES = 1
        IMGFRMT_CMD_GET_LIST = 2
        IMGFRMT_CMD_SET_FORMAT = 3
        IMGFRMT_CMD_GET_ARBITORY_AOI_SUPPORTED = 4
        IMGFRMT_CMD_GET_FORMAT_INFO = 5
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
        IMAGE_FORMAT_LIST* image_format_list
    def __cinit__(self, format_id, displaymode="dib", colormode="bgr8_packed"):
        self.hCam = 0
        self._init_camera()
        self.get_supported_formats()
        self.displaymode=displaymode
        self.colormode=colormode
        self.set_display_mode(self.displaymode)
        self.set_color_mode(self.colormode)
        self.format_id = format_id
        self.set_format(self.format_id)
    def __dealloc__(self):
        pass
        self.exit_camera()

    def _init_camera(self):
        ret = is_InitCamera(&self.hCam, NULL)
        print("Status init_Camera: ", ret)
        return ret

    def exit_camera(self):
        ret = is_ExitCamera(self.hCam)
        print("Status exit_camera: ", ret)
        return ret

    def set_display_mode(self, mode):
        if mode is 'dib':
            ret = is_SetDisplayMode(self.hCam, IS_SET_DM_DIB)
        else:
            raise ValueError(mode, " is no displaymode")
        print("Status set_display_moded: ", ret)

    def set_color_mode(self, mode):
        if mode is 'bgr8_packed':
            ret = is_SetColorMode(self.hCam, IS_CM_BGR8_PACKED)
            self.bitspixel = 24
        else:
            raise ValueError(mode, " is no colormode")
        print("Status set_color_mode: ", ret)
        return ret

    def set_format(self, int format_id):
        cdef unsigned int i
        cdef IMAGE_FORMAT_INFO format_info
        for i in range(self.image_format_list.nNumListElements):
            format_info = self.image_format_list.FormatInfo[i]
            if format_id is format_info.nFormatID:
                ret = is_ImageFormat(self.hCam, IMGFRMT_CMD_SET_FORMAT, &format_id, 4)
                print("Status set_format: ", ret)
                self.height = format_info.nHeight
                self.width = format_info.nWidth
                return ret
        raise ValueError("Format: ", format_id, "is not supported on your camera")

    def get_supported_formats(self):
        cdef unsigned int count
        cdef unsigned int bytesneeded = sizeof(IMAGE_FORMAT_LIST)
        ret = is_ImageFormat(self.hCam, IMGFRMT_CMD_GET_NUM_ENTRIES, &count, sizeof(count))
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
        print("Status get_supported_formats", ret)
        return ret

    def alloc_image_mem(self):
        ret = is_AllocImageMem(self.hCam, self.width, self.height, self.bitspixel, &self.pcImgMem, &self.pid)
        print("Status alloc_image_mem: ", ret)
        ret = self.set_image_mem()
        return ret

    def set_image_mem(self):
        ret = is_SetImageMem(self.hCam, self.pcImgMem, self.pid)
        print("Status set_image_mem: ", ret)

    def freeze_video(self):
        #self.set_image_mem()
        ret = is_FreezeVideo(self.hCam, 0)

    def freeze_to_numpy(self):
        pic = np.zeros([self.height, (self.width*3)], dtype=np.uint8)
        cdef int i, j, mem_marker = 0
        for i in range(len(pic)):
            for j in range(len(pic[i])):
                pic[i][j]=self.pcImgMem[mem_marker]
                mem_marker += 1
        return pic
