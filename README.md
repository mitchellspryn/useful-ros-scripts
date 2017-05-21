# Useful ROS Scripts

This repository consists of a collection of automation scripts that I find useful when working with ROS projects. All of these scripts have been tested with ROS Kinetic on Ubuntu 16.04.

Contained within this repo are the following scripts:

## Bag2Vid
This script will take a RosBag file that contains [sensor_msgs/Image](http://docs.ros.org/api/sensor_msgs/html/msg/Image.html) messages and convert them to a .mpg video file format. In addition, it can also be used to extract the frames to separate .jpg images. The script takes the following paramters:

Required
* **-t** the topic name from which the image bag was created.

Optional
* **-p** Change the temporary file directory name. The script will first extract all of the images to this path, then combine them together into a video. If not set, this defaults to "tmp".
* **-o** Change the output file name. If not set, then this defaults to "output.mpg"
* **-s** Save the temporary directory with the images. If this flag is not passed, then the script will delete the temporary directory with the extracted images.
* **-f** the number of frames per second for which the video was recorded. If not set, this defaults to 30.
* **-n** Do not create the video. If passed, then the video will not be created from the images. This is useful with the **-s** flag to extract the images. If not set, then the video will be created.

Sample usage:
`$./Bag2Vid Images.bag -f 30`

Dependencies:
* **[rosbag](http://wiki.ros.org/rosbag)**. This is included with the ros-desktop-full package
* **ros [imageview](http://wiki.ros.org/image_view)**. This is included with the ros-desktop-full package
* **[mencoder](https://en.wikipedia.org/wiki/MEncoder)**. This can be installed on ubuntu with `$sudo apt-get install mencoder`
* **bc** This is a standard linux utility. If it's not installed, it can be installed with `sudo apt-get install bc`
