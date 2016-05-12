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
	"flag"
	"fmt"
	"log"

	"crypto/tls"
	"io"
	"io/ioutil"

	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	pb "messagepb"
)

const (
	useSSL         = false
	host           = "localhost"
	defaultMessage = "Hello."
)

func main() {

	var stream = flag.Bool("s", false, "send multiple messages by streaming")
	var message = flag.String("m", defaultMessage, "the message to send")

	flag.Parse()

	// Set up a connection to the server.
	var conn *grpc.ClientConn
	var err error
	if !useSSL {
		conn, err = grpc.Dial("localhost:8080", grpc.WithInsecure())
	} else {
		conn, err = grpc.Dial("localhost:443",
			grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{
				// remove the following line if the server certificate is signed by a certificate authority
				InsecureSkipVerify: true,
			})))
	}

	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewStickyNoteClient(conn)

	if *stream {
		send_many_messages(c, *message)
	} else {
		send_one_message(c, *message)
	}
}

func send_one_message(c pb.StickyNoteClient, message string) {
	// Contact the server and print out its response.
	response, err := c.Get(context.Background(), &pb.StickyNoteRequest{Message: message})
	if err != nil {
		log.Fatalf("could not create sticky: %v", err)
	}
	filename := "message.png"
	ioutil.WriteFile(filename, response.Image, 0644)
	log.Printf("OK: %s", filename)
}

func send_many_messages(c pb.StickyNoteClient, message string) {
	stream, err := c.Update(context.Background())
	if err != nil {
		panic(err)
	}
	waitc := make(chan struct{})
	go func() {
		var count int
		for {
			in, err := stream.Recv()
			if err == io.EOF {
				// read done.
				close(waitc)
				return
			}
			if err != nil {
				log.Fatalf("Failed to receive a note : %v", err)
			}
			filename := fmt.Sprintf("message-%d.png", count)
			count = count + 1
			ioutil.WriteFile(filename, in.Image, 0644)
			log.Printf("OK: %s", filename)
		}
	}()
	for i := 0; i < 5; i++ {
		var note pb.StickyNoteRequest
		note.Message = fmt.Sprintf("%s %d", message, i)
		if err := stream.Send(&note); err != nil {
			log.Fatalf("Failed to send a note: %v", err)
		}
	}
	stream.CloseSend()
	<-waitc
}
