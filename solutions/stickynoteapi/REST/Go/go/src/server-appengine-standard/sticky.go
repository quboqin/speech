// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"bytes"
	"github.com/llgcode/draw2d"
	"github.com/llgcode/draw2d/draw2dimg"
	"image"
	"image/color"
	"image/png"
	"log"
	"strings"
)

type Sticky struct {
	Message  string
	Centered bool
}

func (sticky *Sticky) DrawPNG(W, H int) (imageBytes *[]byte, err error) {
	var byteStorage []byte
	b := bytes.NewBuffer(byteStorage)
	img, err := sticky.DrawImage(W, H)
	if err != nil {
		return nil, err
	}
	err = png.Encode(b, img)
	byteStorage = b.Bytes()
	return &byteStorage, err
}

const DEBUG_DRAWING = false

func (sticky *Sticky) DrawImage(W, H int) (img *image.RGBA, err error) {
	fontSize := float64(H / 2)
	lineHeight := 1.7

	draw2d.SetFontFolder("fonts")
	fontData := draw2d.FontData{
		Name:   "RobotoCondensed",
		Family: draw2d.FontFamilySans,
		Style:  draw2d.FontStyleNormal,
	}

	for {
		textW := 0.9 * float64(W)
		textH := 0.9 * float64(H)

		bitmap := image.NewRGBA(image.Rect(0, 0, W, H))
		gc := draw2dimg.NewGraphicContext(bitmap)

		// draw a solid yellow background
		gc.SetFillColor(color.RGBA{0xFF, 0xFF, 0x80, 0xFF})
		gc.MoveTo(float64(0), float64(0))
		gc.LineTo(float64(W), float64(0))
		gc.LineTo(float64(W), float64(H))
		gc.LineTo(float64(0), float64(H))
		gc.Close()
		gc.Fill()

		gc.SetFontData(fontData)
		gc.SetFillColor(image.Black)
		gc.SetFontSize(fontSize)

		// split message into lines
		lines := make([]string, 0)
		heights := make([]float64, 0)
		widths := make([]float64, 0)

		words := strings.Fields(sticky.Message)
		start := 0
		length := 1
		var testline string
		for {
			var left, top, right, bottom float64

			// set maximum font size so that the widest word will fit
			longestWord := ""
			for _, word := range words {
				if len(word) > len(longestWord) {
					longestWord = word
				}
			}
			left, top, right, bottom = gc.GetStringBounds(longestWord)
			if right > textW {
				fontSize = fontSize * textW / right
				gc.SetFontSize(fontSize)
			}

			// split lines for current font size
			for {
				if start+length > len(words) {
					// we are out of words, so stop
					wordrange := words[start : start+length-1]
					testline = strings.Join(wordrange, " ")
					left, top, right, bottom = gc.GetStringBounds(testline)
					break
				}

				wordrange := words[start : start+length]
				testline = strings.Join(wordrange, " ")
				left, top, right, bottom = gc.GetStringBounds(testline)

				if right > textW {
					// we went too far
					length = length - 1
					if length == 0 {
						length = 1
					}
					wordrange := words[start : start+length]
					testline = strings.Join(wordrange, " ")
					left, top, right, bottom = gc.GetStringBounds(testline)
					break
				}
				length = length + 1
			}

			if DEBUG_DRAWING {
				log.Printf("bounds [%f %f %f %f]: %s\n", left, top, right, bottom, testline)
			}

			lines = append(lines, testline)
			heights = append(heights, -top)
			widths = append(widths, right)

			start = start + length
			length = 1

			if start > len(words) {
				break
			}
		}

		// compute the overall text size
		totalHeight := 0.0
		maxWidth := 0.0
		for i, _ := range lines {
			totalHeight = totalHeight + heights[i]*lineHeight
			if widths[i] > maxWidth {
				maxWidth = widths[i]
			}
		}

		if totalHeight > textH || maxWidth > textW {
			// if the text was too big, reduce the font size and redraw
			fontSize = fontSize * 0.9
		} else {
			// draw the text line-by-line and return the image
			textX := 0.5 * (float64(W) - maxWidth)
			textY := 0.5 * (float64(H) - totalHeight - 0.5*heights[0])
			y := textY
			for i, line := range lines {
				y = y + heights[i]*lineHeight
				if sticky.Centered {
					textX = 0.5 * (float64(W) - widths[i])
				}
				gc.FillStringAt(line, textX, y)
			}
			return bitmap, nil
		}
	}
	return nil, nil
}
