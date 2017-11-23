import cyueye as cu
import pprint
import cv2
import numpy as np


#Init Cam
cam = cu.Cam(format_id=8)
cam.set_exposure(20.1)
cam.capture_video()

#Stream Video
while True:
    pic = cam.video_to_numpy()
    cv2.imshow('image', pic)
    if cv2.waitKey(1) & 0xFF == ord('q'):
                break
cv2.destroyAllWindows()

