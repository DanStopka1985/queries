package loader

import (
	"fmt"
	"database/sql"
	io "io/ioutil"
	ss "../settings"
	"log"
	"strings"
)

var s = ss.GetSettings()
var dbFhirPsqlInfo = fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", s.DbFhirHost, s.DbFhirPort, s.DbFhirUser, s.DbFhirPassword, s.DbFhirName)
var fhirDb, errIemkCon = sql.Open("postgres", dbFhirPsqlInfo)

func LoadDbFunctions(){
	files, err := io.ReadDir("queries")
	if err != nil {
		log.Fatal(err)
	}

	for _, f := range files {
		if (!f.IsDir() && strings.HasSuffix(f.Name(), ".sql")) {
			script := ""
			buf, err := io.ReadFile("queries/" + f.Name())
			if (buf[0] == 239 && buf[1] == 187 && buf[2] == 191){
				script = string(buf[3:])
			} else {
				script = string(buf)
			}

			if err != nil {
				log.Fatal(err)
			}

			fhirDb.Exec(script)
		}
	}
}