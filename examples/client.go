// Example client implementation to access the ssh_scan API in go
//
// go build client.go
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net/http"
	"os"
	"time"
)

var apiServerUrl string = "https://sshscan.rubidus.com/api/v1"

// Use a defined struct for the scan request response, we will want to make use of
// the UUID for results polling.
//
// Note we don't use a similar struct for the actual results, since we want to keep
// that particular data arbitrary and simply display it in this example using a generic
// interface.
type scanResponse struct {
	UUID string `json:"uuid"`
}

// Execute a scan against target. The results are submitted in resch, if any error
// occurs the error is sent on errch.
func runScan(target string, resch chan interface{}, errch chan error) {
	var (
		scan   scanResponse
		result interface{}
	)

	client := &http.Client{}

	// Create initial scan request
	url := apiServerUrl + "/scan"
	req, err := http.NewRequest("POST", url, nil)
	if err != nil {
		errch <- err
		return
	}
	q := req.URL.Query()
	q.Add("target", target)
	req.URL.RawQuery = q.Encode()
	resp, err := client.Do(req)
	if err != nil {
		errch <- err
		return
	}
	if resp.StatusCode != http.StatusOK {
		errch <- fmt.Errorf("http request failed: code %v", resp.StatusCode)
		return
	}
	err = json.NewDecoder(resp.Body).Decode(&scan)
	resp.Body.Close()
	if err != nil {
		errch <- err
		return
	}

	// Poll for results
	url = apiServerUrl + "/scan/results"
	req, err = http.NewRequest("GET", url, nil)
	if err != nil {
		errch <- err
		return
	}
	q = req.URL.Query()
	q.Add("uuid", scan.UUID)
	req.URL.RawQuery = q.Encode()
	for {
		resp, err = client.Do(req)
		if err != nil {
			errch <- err
			return
		}
		if resp.StatusCode != http.StatusOK {
			errch <- fmt.Errorf("http request failed: code %v", resp.StatusCode)
			return
		}
		err = json.NewDecoder(resp.Body).Decode(&result)
		resp.Body.Close()
		if err != nil {
			errch <- err
			return
		}
		// Test if we have a completed scan by looking for the "ssh_scan_version"
		// element in the JSON response body
		rm, ok := result.(map[string]interface{})
		if !ok {
			errch <- fmt.Errorf("failed type assertion from json")
			return
		}
		if _, ok := rm["ssh_scan_version"]; ok {
			break
		}
		time.Sleep(time.Millisecond * 500)
	}
	resch <- result
}

func main() {
	var (
		result     interface{}
		resultChan chan interface{}
		errChan    chan error
		err        error
	)

	var target = flag.String("t", "ssh.mozilla.com", "target to scan")
	flag.Parse()

	resultChan = make(chan interface{}, 0)
	errChan = make(chan error, 0)
	go runScan(*target, resultChan, errChan)
	select {
	case err = <-errChan:
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	case result = <-resultChan:
		buf, err := json.MarshalIndent(result, "", "  ")
		if err != nil {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("%v\n", string(buf))
	}
}
