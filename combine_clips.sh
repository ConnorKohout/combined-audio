#!/bin/bash

# Directories
GATSBY_DIR="gatsby1"
MP3_DIR="mp3"
OUTPUT_DIR="combined"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to get the duration of an MP3 file in seconds
get_duration() {
  ffmpeg -i "$1" 2>&1 | grep "Duration" | awk '{print $2}' | tr -d ',' | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }'
}

# Process each file in gatsby1
for gatsby_clip in "$GATSBY_DIR"/*.mp3; do
  # Get a random mp3 file from the mp3 directory
  random_mp3=$(find "$MP3_DIR" -type f | shuf -n 1)
  
  # Get the duration of the random mp3 file
  duration=$(get_duration "$random_mp3")
  
  # Ensure duration is greater than 10 seconds, otherwise skip this file
  if (( $(echo "$duration < 10" | bc -l) )); then
    echo "Skipping $random_mp3 as it is less than 10 seconds."
    continue
  fi

  # Get a random start time for the 10-second clip
  random_start=$(echo "$duration - 10" | bc)
  random_start=$(shuf -i 0-${random_start%.*} -n 1)

  # Create a 10-second segment from the random mp3
  ffmpeg -y -ss "$random_start" -t 10 -i "$random_mp3" -c copy temp_random.mp3

  # Check if temp_random.mp3 was created
  if [[ ! -f temp_random.mp3 ]]; then
    echo "Error: temp_random.mp3 was not created. Skipping."
    continue
  fi

  # Mix the gatsby clip with the random segment
  output_file="$OUTPUT_DIR/$(basename "$gatsby_clip")"
  ffmpeg -y -i "$gatsby_clip" -i temp_random.mp3 -filter_complex "amix=inputs=2:duration=shortest" "$output_file"

  echo "Processed $gatsby_clip with random segment from $random_mp3"
done

# Cleanup temporary files
rm -f temp_random.mp3
