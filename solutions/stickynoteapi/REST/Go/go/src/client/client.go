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
	"log"
	"os"

	"io/ioutil"

	"net/http"
	"net/url"
)

const (
	address        = "localhost:8080"
	defaultMessage = "Hello."
)

func main() {

	message := defaultMessage
	if len(os.Args) > 1 {
		message = os.Args[1]
	}

	v := url.Values{}
	v.Set("message", message)

	response, err := http.Get("http://" + address + "/stickynote?" + v.Encode())
	if err != nil {
		log.Printf("%s", err)
		os.Exit(1)
	} else {
		defer response.Body.Close()
		contents, err := ioutil.ReadAll(response.Body)
		if err != nil {
			log.Printf("%s", err)
			os.Exit(1)
		}
		filename := "message.png"
		ioutil.WriteFile(filename, contents, 0644)
		log.Printf("OK: %s", filename)
	}

}
