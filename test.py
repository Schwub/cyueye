import cyueye as cu
ret, hcam = cu.init_camera(0)
print(ret)
ret = cu.set_display_mode(hcam, 1)
print(ret)
ret = cu.set_color_mode(hcam, 1)
print(ret)
ret = cu.image_format(hcam, 3, 6, 4)
print(ret)
ret = cu.alloc_image_mem(hcam, 1920,  1080, 24)
print(ret)
ret = cu.exit_camera(hcam)
print(ret)
