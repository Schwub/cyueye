import sys
sys.path.insert(0, "../src")
import cyueye as cu
import cv2

#Init Cam
cam = cu.Cam(format_id=8)
cam.capture_video()

#Stream Video
while True:
    pic = cam.video_to_numpy()
    cv2.imshow('image', pic)
    if cv2.waitKey(1) & 0xFF == ord('q'):
                break
cv2.destroyAllWindows()

