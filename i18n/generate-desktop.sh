#!/bin/bash

# Copyright (C) 2017 Florent Revest <revestflo@gmail.com>
# All rights reserved.
#
# You may use this file under the terms of BSD license as follows:
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the author nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This script is used to extract the translated app names found inevery .ts file
# and gather those strings with the .desktop.template file in a single .desktop

if [ "$#" -ne 2 ]; then
    echo "usage: $0 src_directory output.desktop"
    exit 1
fi

SRC_DIR=$1
OUTPUT_DESKTOP_FILE=$2
if [ ! -f "${SRC_DIR}/${OUTPUT_DESKTOP_FILE}.template" ]; then
    echo "${SRC_DIR}/${OUTPUT_DESKTOP_FILE}.template not found"
    exit 2
fi
if [ ! -f "${SRC_DIR}/i18n/${OUTPUT_DESKTOP_FILE}.h" ]; then
    echo "${SRC_DIR}/i18n/${OUTPUT_DESKTOP_FILE}.h not found"
    exit 2
fi

DEFAULT_NAME=`grep -oP '//% "\K[^"]+(?=")' ${SRC_DIR}/i18n/${OUTPUT_DESKTOP_FILE}.h`
if [ -z "$DEFAULT_NAME" ]; then
  echo "Default name can not be found in ${SRC_DIR}/i18n/${OUTPUT_DESKTOP_FILE}.h"
  exit 3
fi

cat ${SRC_DIR}/${OUTPUT_DESKTOP_FILE}.template > ${OUTPUT_DESKTOP_FILE}
echo "Name=$DEFAULT_NAME" >> $OUTPUT_DESKTOP_FILE

for FILE in ${SRC_DIR}/i18n/*.ts; do
  echo "Processing $FILE..."

  PROCESSED_LANG=`grep -oP 'language="\K[^"]+(?=")' $FILE`
  if [ -z "$PROCESSED_LANG" ]; then
    echo "> Couldn't find a corresponding language id, aborting"
    continue
  fi
  echo "> Language: $PROCESSED_LANG detected"

  TRANSLATION_LINE=`grep -A 3 '<message id=\"id-app-launcher-name\">' $FILE | grep '<translation'`
  if [ -z "$TRANSLATION_LINE" ]; then
    echo "> Couldn't find a corresponding desktop.h translation, aborting"
    continue
  fi

  LINE_IS_UNFINISHED=`echo $TRANSLATION_LINE | grep unfinished`
  if [ ! -z "$LINE_IS_UNFINISHED" ]; then
    echo "> Translation line has been found but is marked as unfinished, aborting"
    continue
  fi

  TRANSLATED_NAME=`echo $TRANSLATION_LINE | grep -oP '>\K[^<]*(?=</translation>)'`
  if [ -z "$TRANSLATED_NAME" ]; then
    echo "> Translation is empty, aborting"
    continue
  fi
  echo "> Translation '$TRANSLATED_NAME' found, filling $OUTPUT_DESKTOP_FILE"

  echo "Name[$PROCESSED_LANG]=$TRANSLATED_NAME" >> $OUTPUT_DESKTOP_FILE
done
