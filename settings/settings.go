package settings

import (
	"os"
	"encoding/json"
	"log"
)

type settings struct {
	Port int
	DbFhirHost string
	DbFhirPort int
	DbFhirUser string
	DbFhirPassword string
	DbFhirName string
}

func GetSettings() settings{
	var settings settings
	jsonFile, err := os.Open("settings.json")
	if err != nil {
		log.Fatal(err.Error())
	}
	jsonParser := json.NewDecoder(jsonFile)
	err = jsonParser.Decode(&settings)
	if err != nil {
		log.Fatal(err.Error())
	}
	return settings
}