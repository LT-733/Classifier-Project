package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
)

func relayHandler(w http.ResponseWriter, r *http.Request) {
	endpoint := "https://ltcai-zone-classifier.hf.space"
	req, err := http.NewRequest("POST", endpoint, r.Body)
	if err != nil {
		http.Error(w, "failed to send request", http.StatusInternalServerError)
		return
	}
	req.Header.Set("Content-Type", r.Header.Get("Content-Type"))

	client := http.Client{}
	response, error := client.Do(req)
	if error != nil {
		http.Error(w, "Failed to communicate with backend", http.StatusBadGateway)
		return
	}
	defer response.Body.Close()

	w.WriteHeader(response.StatusCode)

	io.Copy(w, response.Body)
}

func main() {
	http.HandleFunc("/predict", relayHandler)

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
