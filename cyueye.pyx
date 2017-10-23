cdef extern from 'ueye.h':
    int is_InitCamera(unsigned int* hcam, void* hwand)
    int is_ExitCamera(unsigned int hcam)
    int is_SetDisplayMode(unsigned int hcam, int mode)
    int is_SetColorMode(unsigned int hcam, int mode)
    int is_AllocImageMem(unsigned int hcam, int width, int height, int bitspixel, char** ppcImgMem, int* pid)
    int is_ImageFormat(unsigned int hcam, unsigned int ncommand, void *pParam, unsigned int nsizeofparam)


def init_camera(unsigned int hcam):
    ret = is_InitCamera(&hcam, NULL)
    return ret, hcam

def exit_camera(unsigned int  hcam):
    ret = is_ExitCamera(hcam)
    return ret

def set_display_mode(unsigned int hcam, int mode):
    ret = is_SetDisplayMode(hcam, mode)
    return ret

def set_color_mode(unsigned int hcam, int mode):
    ret = is_SetColorMode(hcam, mode)
    return ret

def image_format(unsigned int hcam, unsigned int ncommand, unsigned int pparam, unsigned int nsizeofparam):
    ret = is_ImageFormat(hcam, ncommand, &pparam, nsizeofparam)
    return ret

def alloc_image_mem(unsigned int hcam, int width, int height, int bitspixel):
    cdef char *pcImgMem
    cdef int pid
    ret = is_AllocImageMem(hcam, width, height, bitspixel, &pcImgMem, &pid)
    return ret


