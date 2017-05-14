package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

type ESResponse struct {
	Took      int    `json:"took"`
	Timed_out bool   `json:"timed_out"`
	Shards    Shards `json:"_shards"`
	Hits      Hits   `json:"hits"`
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

type Hit struct {
	Index  string  `json:"_index"`
	Type   string  `json:"_type"`
	Id     string  `json:"_id"`
	Score  float32 `json:"_score"`
	Fields Fields  `json:"fields"`
}

type Fields struct {
	Message []string `json:"message"`
}

func main() {
	journal := os.Getenv("USE_JOURNAL")

	var elasticSearchData ESResponse
	if err := json.NewDecoder(os.Stdin).Decode(&elasticSearchData); err != nil {
		fmt.Printf("[ERROR] Invalid JSON response: %v", err)
		os.Exit(1)
	}

	if elasticSearchData.Hits.Total == 0 {
		fmt.Println("[ERROR] No messages found in JSON response")
		os.Exit(1)
	}

	for _, record := range elasticSearchData.Hits.Hits {
		// for each message, we need to check the logs
		message := record.Fields.Message[0]

		if journal == "true" {
			// escape certain characters that were being interpreted by bash
			message = strings.Replace(message, `\`, `\\`, -1)
			message = strings.Replace(message, `"`, `\"`, -1)
			message = strings.Replace(message, "`", `\`+"`", -1)
			message = strings.Replace(message, `$`, `\$`, -1)
		} else {
			// escape certain characters that were being interpreted by grep -e "" or bash
			message = strings.Replace(message, `\`, `\\\\`, -1)
			message = strings.Replace(message, `[`, `\[`, -1)
			message = strings.Replace(message, `]`, `\]`, -1)
			message = strings.Replace(message, `*`, `\*`, -1)
			message = strings.Replace(message, `"`, `\"`, -1)
			message = strings.Replace(message, "`", `\`+"`", -1)
			message = strings.Replace(message, `$`, `\$`, -1)
		}
		fmt.Println(message)
	}
}