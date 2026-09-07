#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( dirname "$DIR" )/.."

# Create an awesome 1080p 60fps sizzle video from screenshots
ffmpeg -y \
  -loop 1 -t 3.5 -i "$PROJECT_DIR/Marketing/AppStoreScreenshots/1_Applications_Matrix.png" \
  -loop 1 -t 3.5 -i "$PROJECT_DIR/Marketing/AppStoreScreenshots/2_Themes_And_Shaders.png" \
  -loop 1 -t 3.5 -i "$PROJECT_DIR/Marketing/AppStoreScreenshots/3_MenuBar_Studio_Hub.png" \
  -loop 1 -t 3.5 -i "$PROJECT_DIR/Marketing/AppStoreScreenshots/4_Settings_And_Battery_Styles.png" \
  -filter_complex "\
    [0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=out:st=3.0:d=0.5[v0]; \
    [1:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=0.5,fade=t=out:st=3.0:d=0.5[v1]; \
    [2:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=0.5,fade=t=out:st=3.0:d=0.5[v2]; \
    [3:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=0.5[v3]; \
    [v0][v1][v2][v3]concat=n=4:v=1:a=0[outv]" \
  -map "[outv]" \
  -c:v libx264 -pix_fmt yuv420p -r 60 -preset medium -crf 20 \
  "$DIR/GoldenGateStudio_Showcase.mp4"

cp "$DIR/GoldenGateStudio_Showcase.mp4" "$PROJECT_DIR/web/assets/videos/"
echo "Video created successfully: $DIR/GoldenGateStudio_Showcase.mp4"
