#!/bin/bash

################################################################################
#
# Bag2Vid.sh
#
# Purpose: Given a rosbag with sensor_msgs/Image messages, 
# extract them into sequences of images or video files.
#
# Author: Mitchell Spryn <mitchell.spryn@gmail.com>
#
#################################################################################

usage()
{
  echo -e "Usage: ./Bag2Vid (flags) <BagName>";
  echo -e "\tBagName: The name of the bag with the images in it.";
  echo -e "\tFlags:";
  echo -e "\t\t-p: Sets the temporary file name path. If not set, defaults to 'tmp'";
  echo -e "\t\t-o: Changes the output file name. If not set, defaults to 'output.mpg'";
  echo -e "\t\t-s: If set, then the image directory will be saved. Otherwise, it will be cleaned up after the video is created. Default value is to clean up the image directory.";
  echo -e "\t\t-f: The FPS for the camera. If not set, defaults to 30";
  echo -e "\t\t-t: The topic name for the Rosbag. This is required.";
  echo -e "\t\t-n: If set, then the video will not be created. Otherwise, the video will be created. Default value is to create the video.";
  exit 1;
}

#Default values and environment variables
ORIGINAL_DIR=$PWD
TMP_DIR_NAME="tmp"
FRAMES_PER_SECOND="30"
SHOULD_SAVE_IMAGES="false"
SHOULD_MAKE_VIDEO="true"
OUTPUT_FILE_NAME='output.mpg'
TOPIC_NAME=""

#Parse command line arguments
while getopts "p:o:f:t:sn" o; do
  case "${o}" in
    p)
      TMP_DIR_NAME=${OPTARG}
      ;;
    o)
      OUTPUT_FILE_NAME=${OPTARG}
      ;;
    s)
      SHOULD_SAVE_IMAGES=true
      ;;
    n)
      SHOULD_MAKE_VIDEO=false
      ;;
    f)
      FRAMES_PER_SECOND=${OPTARG}
      ;;
    t)
      TOPIC_NAME=${OPTARG}
      ;;
    *)
      echo 'Unrecognized parameter.'
      usage
      ;;
  esac
done
shift $((OPTIND-1))

#Bag name should not be null or spaces
if [[ -z "${1// }" ]]; then
  usage
fi

BAG_PATH=$(readlink -e $1)

#Topic name should not be null or spaces
if [[ -z "${TOPIC_NAME// }" ]]; then
  echo 'ERROR: Topic name not supplied.'
  usage
fi

#Both the temp directory and the output file name should not be null or spaces.
# Otherwise, there's the possibility of attempting to run 'rm /' later on down the line in the script
if [[ -z "${TMP_DIR_NAME// }" ]] && [[ -z "${OUTPUT_FILE_NAME// }" ]]; then
  echo 'ERROR: temp directory name and output file name are empty. This is probably not intended.'
  usage
fi

#Image_View needs seconds per frame instead of frames per second.
# Check to make sure there wll not be a divide by zero error when converting
if [[ $(( ${FRAMES_PER_SECOND} | bc -l )) -eq "0" ]]; then
  echo 'ERROR: frames per second is zero. Set using -f flag.'
  usage
fi

SECONDS_PER_FRAME=$(echo "1.0 / ${FRAMES_PER_SECOND}" | bc -l)

#Make working directory
echo "making directory ${TMP_DIR_NAME}..."
mkdir -p $TMP_DIR_NAME
cd $TMP_DIR_NAME

#Start the core service
# Will error if roscore is already started, but script will still run
echo 'starting roscore...'
roscore &
ROSCORE_PID=$!
sleep 1

#Start the image extractor
echo 'starting image extractor...'
rosrun image_view extract_images _sec_per_frame:=${SECONDS_PER_FRAME} image:=${TOPIC_NAME} &
IMAGE_VIEW_PID=$!
sleep 1

#Play the rosbag
echo 'running rosbag...'
rosbag play $BAG_PATH

#Kill the started ROS processes
echo 'killing background processes...'

kill -9 $IMAGE_VIEW_PID
kill -9 $ROSCORE_PID

#Convert the image sequences to video
if [[ ${SHOULD_MAKE_VIDEO} == "true" ]]; then
  echo 'converting images to video...'
  mencoder "mf://*.jpg" -mf type=jpg:fps=${FRAMES_PER_SECOND} -o ${OUTPUT_FILE_NAME} -speed 1 -ofps ${FRAMES_PER_SECOND} -ovc lavc -lavcopts vcodec=mpeg2video:vbitrate=2500 -oac copy -of mpeg
fi

#Move the output video back to the current directory. 
# If images are not needed, clean up
cd $ORIGINAL_DIR
if [[ ${SHOULD_MAKE_VIDEO} == "true" ]]; then
  mv ${TMP_DIR_NAME}/${OUTPUT_FILE_NAME} .
fi
if [[ ${SHOULD_SAVE_IMAGES} != "true" ]]; then
  echo "cleaning up ${TMP_DIR_NAME}..."
  rm -r $TMP_DIR_NAME
fi

echo 'Done!'
