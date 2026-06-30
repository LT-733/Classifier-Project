package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
)

func relayHandler(w http.ResponseWriter, r *http.Request) {
	// 1. CORS Headers: MANDATORY for browser clients
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	// 2. Pre-flight check: MANDATORY to avoid protocol errors
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	endpoint := "https://ltcai-zone-classifier.hf.space/predict"

	// 3. Proxy Request
	req, err := http.NewRequest("POST", endpoint, r.Body)
	if err != nil {
		http.Error(w, "Failed to create request", 500)
		return
	}

	// Copy Content-Type only
	req.Header.Set("Content-Type", r.Header.Get("Content-Type"))

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, "Bad Gateway", 502)
		return
	}
	defer resp.Body.Close()

	// 4. Proxy Response
	for k, v := range resp.Header {
		w.Header()[k] = v
	}
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func main() {
	http.HandleFunc("/predict", relayHandler)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	fmt.Printf("hosting on PORT: %s\n", port)
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		fmt.Println("Server Failed: ", err)
	}
}
