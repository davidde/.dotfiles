#!/bin/zsh

# Script to convert video with ffmpeg to x265/av1 codec.
# Status: WIP


local usage='
  echo "Convert video to x265/av1 codec. Defaults to x265." ;
  echo "Usage:  ffmpeg_convert <path-to-video> [< x265/av1 >] [-p]" ;
  echo "        -p: Prompt for confirmation; allows editing the command before execution." ;
  return 1
'
if [[ -z $1 ]]; then
  eval $usage
elif [[ -z $2 || $2 == '-p' ]]; then
  local codec_suffix=x265
  local codec=libx265
  local flags='-crf 28 -preset medium'
  # crf: 0–51: quality; 0 is best quality, 28 default, 51 smallest file size but horrible quality.
  # preset: Encoding speed and compression efficiency (slower results in smaller size):
  #         ultrafast, superfast, veryfast, faster, fast, medium (= default), slow, slower, veryslow
  local flag_suffix=medium
elif [[ $2 == 'x265' ]]; then
  local codec_suffix=x265
  local codec=libx265
  local flags='-crf 25 -preset slow'
  local flag_suffix=slow
elif [[ $2 == 'av1' ]]; then
  local codec_suffix=rav1e
  local codec=librav1e
  local flags='-qp 120 -speed 10 -tile-columns 2 -tile-rows 2'
  # qp: 0-255: quality; 0 is best quality, 100 default, 255 smallest file size but horrible quality.
  # speed: 0-10: speed to encode with; 0 is best quality while 10 is the fastest.
  # tiles: tile-based encoding for more speed enhancements.
  local flag_suffix=speed10
else
  eval $usage
fi

# Create output path by removing input extension, adding codec info, flag info and .mkv extension:
local output_path_template='output_path="${1:r}--${codec_suffix}-${flag_suffix}.mkv"'
eval $output_path_template

# Put ffmpeg command together:
local command_template='command="ffmpeg -hide_banner -loglevel warning -stats -i '\''${1}'\''  \\
                        -c:v $codec $flags -metadata title=''  \\
                        '\''${output_path}'\'' "'
# NOTES:
# Pass `-c copy` to prevent audio/subs from being re-encoded.
eval $command_template

# Prepare format string for displaying the execution time:
local TIMEFMT="
${codec}-encode finished in %*Es."

# Prompt for confirmation before executing when necessary:
if [[ $2 == '-p' || $3 == '-p' ]]; then
  echo "\n  Execute the below command?"
  echo "  -> Modify it if necessary, and press <Enter> to continue."
  echo "    (Modifications to the output path and stream title will be ignored; they are "
  vared -p $'     automatically generated from the first 2 options after the video codec.)\n\n> ' -c command
  echo ''
  # Update 'flag_suffix':
  flag_suffix=$(echo $command | head -n 2 | tail -n 1 | cut -d : -f 2 | cut -d ' ' -f 3-6 --output-delimiter=-)
  # And pass it through to the other parts:
  eval $output_path_template
  eval $command_template
else
  echo "\n  Executing: \n  $command\n"
  echo "  Use the -p flag to prompt for confirmation and edit this command before execution.\n"
fi

# time ( eval $command )
echo "( $command )"

# If ffmpeg finished successfully:
if [[ $? == 0 ]]; then
  echo "\noutput:  $output_path"
else # ffmpeg threw error:
  echo '\nSomething went wrong though.'
fi

