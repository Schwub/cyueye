# Example
This is a example how to use this package to capture a video from your *IDS uEye* camera.

## Import the package

To import the compiled cyueye.so file into your Python project you need to add it to your sys path:

```python
import sys
sys.path.insert(0, "PATH_TO_THE_cyueye.so_FILE")
import cyueye as cu
```

## Import OpenCV for showing the image
```python
import cv2
```

## Initialise the Camera
To connect to your camera it has to be connected to your computer and the *IDS uEye* daemon has to be started.
```python
cam = cu.Cam(format_id=8)
```

By passing a format_id to the cam object you can select the resolution of your images and videos,
for a list of supported formats for your camera visit [ids-imaging.com](https://de.ids-imaging.com/manuals/uEye_SDK/DE/uEye_Handbuch_4.90.6/index.html). You might have to create an account to access the IDS documentation. 

## Start the video capture
```python
cam.capture_video()
```

## Show Video
```python
while True:
	pic = cam.video_to_numpy()
	cv2.imshow('image', pic)
	if cv2.watKey(1) & 0xFF == ord('q'):
		break
cv2.destroyAllWindows()
```

This code receives an image from your camera by calling the *video_to_numpy* method, the return value is a numpy array.
OpenCV is used to display the image. By looping over the *video_to_numpy* method, a videostream is created.
You can press *q* on your keyboard to close the video window.
You can find this code an the */example/example.py* file.
