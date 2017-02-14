package main

import (
	"bytes"
	"flag"
	"fmt"
	"math/rand"
	"net"
	"time"
)

// XP duration in second
const duration = 60

var rate = flag.Int("rate", 1, "Number of 64KB buffer sent every second")

var letterRunes = []byte("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

var applicationsId [50][]byte

func main() {
	flag.Parse()

	for i := 0; i < 50; i++ {
		applicationsId[i] = genApplicationId()
	}

	for i := 0; i < duration; i++ {
		for j := 0; j < *rate; j++ {
			go sendLogsBuffer()
		}
		time.Sleep(1 * time.Second)
	}
}

func sendLogsBuffer() {
	conn, err := net.Dial("tcp", "logger.example.com:5140")
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	var buffer bytes.Buffer
	// Openresty have a 64KB buffer before sending logs to our service
	for i := 0; i < 1024; i++ {
		appId := applicationsId[rand.Intn(50)]
		_, err = buffer.Write(appId)
		if err != nil {
			panic(err)
		}
		// Create a 64 characters buffer representing one line of log
		for j := 0; j < 63-24; j++ {
			_, err = buffer.WriteString("a")
			if err != nil {
				panic(err)
			}
		}
		_, err = buffer.WriteString("\n")
		if err != nil {
			panic(err)
		}
	}

	_, err = conn.Write(buffer.Bytes())
	if err != nil {
		panic(err)
	}
	fmt.Println("Send end at", time.Now())
}

func genApplicationId() []byte {
	appId := make([]byte, 24)
	for i := range appId {
		appId[i] = letterRunes[rand.Intn(len(letterRunes))]
	}
	return appId
}
