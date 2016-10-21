package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func main() {

	args := os.Args[1:]

	kibana_pod := args[0]
	es_svc := args[1]
	index := args[2]
	filePath := args[3]
	querySize := args[4]
	userName := args[5]
	userToken := args[6]
	testIP := args[7]
	journal := os.Getenv("USE_JOURNAL")
	verbose := false
	if os.Getenv("VERBOSE") != "" {
		verbose = true
	}

	//we want the hostname witout a domain for the most generic search
	hostname, _ := os.Hostname()
	hostname = strings.Split(hostname, ".")[0]

	// instead of receiving jsonStream as an Arg, we'll make the call ourselves...
	proxyHeaders := `-H 'X-Proxy-Remote-User: ` + userName + `' -H 'Authorization: Bearer ` + userToken + `' -H 'X-Forwarded-For: ` + testIP + `'`
	queryCommand := `oc exec ` + kibana_pod + ` -- curl -s --key /etc/kibana/keys/key --cert /etc/kibana/keys/cert --cacert /etc/kibana/keys/ca ` + proxyHeaders + ` -XGET "https://` + es_svc + `/` + index + `.*/com.redhat.viaq.common/_search?q=hostname:` + hostname + `&fields=message&size=` + querySize + `"`
	if verbose {
		fmt.Printf("Executing command [%s]\n", queryCommand)
	}
	queryCmdName := "bash"
	queryCmdArgs := []string{"-c", queryCommand}

	queryCmd := exec.Command(queryCmdName, queryCmdArgs...)

	byt, err := queryCmd.Output()
	if err != nil {
		fmt.Printf("output [%s]\nerror [%v]", byt, err)
		panic(err)
	}

	type Fields struct {
		Message []string `json:"message"`
	}

	type Hit struct {
		Index  string  `json:"_index"`
		Type   string  `json:"_type"`
		Id     string  `json:"_id"`
		Score  float32 `json:"_score"`
		Fields Fields  `json:"fields"`
	}

	type Shards struct {
		Total      int `json:"total"`
		Successful int `json:"successful"`
		Failed     int `json:"failed"`
	}

	type Hits struct {
		Total     int     `json:"total"`
		Max_score float32 `json:"max_score"`
		Hits      []Hit   `json:"hits"`
	}

	type ESResponse struct {
		Took      int    `json:"took"`
		Timed_out bool   `json:"timed_out"`
		Shards    Shards `json:"_shards"`
		Hits      Hits   `json:"hits"`
	}

	dat := ESResponse{}

	if err := json.Unmarshal(byt, &dat); err != nil {
		panic(err)
	}

	var missesBuffer bytes.Buffer
	totalEntries := len(dat.Hits.Hits)
	foundEntries := totalEntries

	for _, record := range dat.Hits.Hits {
		// for each message, we need to check the logs
		message := record.Fields.Message[0]

		searchCmd := ""
		if journal == "true" {
			// escape certain characters that were being interpreted by bash
			message = strings.Replace(message, `\`, `\\`, -1)
			message = strings.Replace(message, `"`, `\"`, -1)
			message = strings.Replace(message, "`", `\`+"`", -1)
			message = strings.Replace(message, `$`, `\$`, -1)
			searchCmd = `journalctl MESSAGE="` + message + `"`
		} else {
			// escape certain characters that were being interpreted by grep -e "" or bash
			message = strings.Replace(message, `\`, `\\\\`, -1)
			message = strings.Replace(message, `[`, `\[`, -1)
			message = strings.Replace(message, `]`, `\]`, -1)
			message = strings.Replace(message, `*`, `\*`, -1)
			message = strings.Replace(message, `"`, `\"`, -1)
			message = strings.Replace(message, "`", `\`+"`", -1)
			message = strings.Replace(message, `$`, `\$`, -1)
			searchCmd = `grep "` + message + `" ` + filePath
		}
		cmdName := "bash"
		cmdArgs := []string{"-c", searchCmd}

		cmd := exec.Command(cmdName, cmdArgs...)

		_, err := cmd.Output()
		if err != nil {
			foundEntries -= 1
			missesBuffer.WriteString(" ! Log entry '")
			missesBuffer.WriteString(message)
			missesBuffer.WriteString("' was not found in path\n")
		}
	}

	if foundEntries == totalEntries {
		if totalEntries == 0 {
			fmt.Printf("Failure - no log entries found in Elasticsearch %s for index %s\n", es_svc, index)
		} else {
			fmt.Printf("Success - [%v/%v] log entries found in %s\n", foundEntries, totalEntries, filePath)
		}
	} else {
		fmt.Printf("Failure - [%v/%v] log entries found in %s\n%s", foundEntries, totalEntries, filePath, missesBuffer.String())
	}

}
