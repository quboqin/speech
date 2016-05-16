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
	"io"
	"log"
	"net"

	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	pb "messagepb"
)

const (
	useSSL = false
)

// [START stickynoteserver]
type StickyNoteServer struct{}

var stickyNoteServer StickyNoteServer
// [END stickynoteserver]

// [START get]
func (s *StickyNoteServer) Get(ctx context.Context, r *pb.StickyNoteRequest) (*pb.StickyNoteResponse, error) {
	var sticky Sticky
	sticky.Message = r.Message
	sticky.Centered = false

	resp := &pb.StickyNoteResponse{}
	stickyBytes, err := sticky.DrawPNG(512, 512)
	resp.Image = *stickyBytes

	return resp, err
}
// [END get]

func (s *StickyNoteServer) Update(stream pb.StickyNote_UpdateServer) error {
	for {
		in, err := stream.Recv()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}

		var sticky Sticky
		sticky.Message = in.Message
		sticky.Centered = false

		resp := &pb.StickyNoteResponse{}
		stickyBytes, err := sticky.DrawPNG(512, 512)
		resp.Image = *stickyBytes

		if err := stream.Send(resp); err != nil {
			return err
		}
	}
	return nil
}

// [START main]
func main() {
	var err error
	var lis net.Listener
	var grpcServer *grpc.Server
	if !useSSL {
		lis, err = net.Listen("tcp", ":8080")
		if err != nil {
			log.Fatalf("failed to listen: %v", err)
		}
		grpcServer = grpc.NewServer()
	} else {
		certFile := "ssl.crt"
		keyFile := "ssl.key"
		creds, err := credentials.NewServerTLSFromFile(certFile, keyFile)
		lis, err = net.Listen("tcp", ":443")
		if err != nil {
			log.Fatalf("failed to listen: %v", err)
		}
		grpcServer = grpc.NewServer(grpc.Creds(creds))
	}
	pb.RegisterStickyNoteServer(grpcServer, &stickyNoteServer)
	grpcServer.Serve(lis)
}
// [END main]
