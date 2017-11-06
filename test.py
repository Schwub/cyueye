import cyueye as cu
import pprint
import cv2
import numpy as np
cam = cu.Cam(format_id=8)
cam.alloc_image_mem()
while True:
    pic = cam.freeze_to_numpy()
    cv2.imshow('image', pic)
    if cv2.waitKey(1) & 0xFF == ord('q'):
                break
cv2.destroyAllWindows()

