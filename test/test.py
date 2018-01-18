import sys
sys.path.insert(0, "..")
from cyueye import cyueye as cu
import cv2
import numpy as np
cam = cu.Cam(format_id=8)
print(cam.set_exposure(50))
cam.start_capture()
while True:
    pic = cam.capture_video()
    #pic = cam.freeze_video()
    cv2.imshow('image', pic)
    if cv2.waitKey(1) & 0xFF == ord('q'):
                break
cv2.destroyAllWindows()

