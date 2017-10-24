cdef extern from 'ueye.h':
    int IS_SET_DM_DIB
    int IS_CM_BGR8_PACKED
    int is_InitCamera(unsigned int* hcam, void* hwand)
    int is_ExitCamera(unsigned int hcam)
    int is_SetDisplayMode(unsigned int hcam, int mode)
    int is_SetColorMode(unsigned int hcam, int mode)
    int is_AllocImageMem(unsigned int hcam, int width, int height, int bitspixel, char** ppcImgMem, int* pid)
    int is_ImageFormat(unsigned int hcam, unsigned int ncommand, void *pParam, unsigned int nsizeofparam)



cdef class Cam:
    cdef:
        unsigned int hCam
        int pid
        char *pcImgMem
        
    def __init__(self, displaymode="dib", colormode="bgr8_packed"):
        self.hCam = 0
        self._init_camera()
        self.displaymode=displaymode
        self.colormode=colormode
        self.set_display_mode(self.displaymode)
        self.set_color_mode(self.colormode)
        self.bitspixel

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

    def image_format(unsigned int hcam, unsigned int ncommand, unsigned int pparam, unsigned int nsizeofparam):
        ret = is_ImageFormat(hcam, ncommand, &pparam, nsizeofparam)
        return ret

    def alloc_image_mem(unsigned int hcam, int width, int height, int bitspixel):
        cdef char *pcImgMem
        cdef int pid
        ret = is_AllocImageMem(hcam, width, height, bitspixel, &pcImgMem, &pid)
        return ret


