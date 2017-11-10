package dao

import (
	"net/http"
	"fmt"
	"database/sql"
	ss "../settings"
)

var s = ss.GetSettings()
var fhirPsqlInfo = fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", s.DbFhirHost, s.DbFhirPort, s.DbFhirUser, s.DbFhirPassword, s.DbFhirName)
var fhirDb, errFhirCon = sql.Open("postgres", fhirPsqlInfo)


func setHeaders(w http.ResponseWriter) http.ResponseWriter  {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	return w
}

/*func getParams(r *http.Request) string {
	pKeys := [21]string{"lpu", "dt1", "dt2", "rdt1", "rdt2" , "vdt1", "vdt2", "case_type", "district", "spec", "reg_dt1", "reg_dt2", "ref_dt1", "ref_dt2",
		"src_spec", "src_pos", "ref_type", "src_lpu", "trg_spec", "trg_lpu", "ctrl"}
	params := ""
	for i := 0; i < len(pKeys); i++ {
		if r.FormValue(pKeys[i]) != "" {
			if len(params) > 0 {params += ","}
			params += pKeys[i] + " := '" + r.FormValue(pKeys[i]) + "'"
		}
	}

	return params;
}*/




func getRows(query string) (*sql.Rows) {
	var err error
	err = errFhirCon
	P(err)
	P(fhirDb.Ping())
	P(err)
	rows, err := fhirDb.Query(query)
	P(err)
	return rows
}

func P(err error){
	if err != nil {
		panic(err)
	}
}

type ResourceSearch struct {
	ResourceType string `json:"resourceType"`
	QueryString string `json:"queryString"`
}

type ResourceSelect struct {
	ResourceType string `json:"resourceType"`
	Id string `json:"id"`
	VersionId string `json:"versionId"`
}