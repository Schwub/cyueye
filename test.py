import cyueye as cu
import pprint
import cv2
import numpy as np
cam = cu.Cam(format_id=6)
cam.alloc_image_mem()
while True:
    cam.freeze_video()
    pic = cam.freeze_to_numpy()
    cv2.imshow('image', pic)
    if cv2.waitKey(1) & 0xFF == ord('q'):
                break
cv2.destroyAllWindows()
