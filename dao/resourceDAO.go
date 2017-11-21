package dao

import (
	"net/http"
	"encoding/json"
	"github.com/gorilla/mux"
)

func GetResourceSearchResult(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	resourceSearch := &ResourceSearch{ResourceType: vars["resourceType"], QueryString: r.URL.RawQuery}
	params, err := json.Marshal(resourceSearch)
	P(err)

	println(r.URL.RawQuery);
	q := `select fhir_search::jsonb val from fhir.fhir_search('` + string(params) + `');`
	println(q)
	CommonReturn(q, w)
}

func GetResourceById(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	resourceSelect := &ResourceSelect{ResourceType: vars["resourceType"], Id: vars["id"]}
	params, err := json.Marshal(resourceSelect)
	P(err)

	CommonReturn(`select fhir_read_resource::jsonb val from fhir.fhir_read_resource('` + string(params) + `');`, w)
}
/*

func GetResourceHistory(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	resourceSelect := &ResourceSelect{ResourceType: vars["resourceType"], Id: vars["id"]}
	params, err := json.Marshal(resourceSelect)
	P(err)

	CommonReturn(`SET plv8.start_proc = 'plv8_init'; select fhir_resource_history::jsonb val from fhir_resource_history('` + string(params) + `');`, w)
}

func GetResourceHistoryById(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	resourceSelect := &ResourceSelect{ResourceType: vars["resourceType"], Id: vars["id"], VersionId: vars["vid"]}
	params, err := json.Marshal(resourceSelect)
	P(err)

	CommonReturn(`SET plv8.start_proc = 'plv8_init'; select fhir_vread_resource::jsonb val from fhir_vread_resource('` + string(params) + `');`, w)
}

func GetExpandValueSetById(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	resourceSelect := &ResourceSelect{Id: vars["id"]}
	params, err := json.Marshal(resourceSelect)
	P(err)

	CommonReturn(`SET plv8.start_proc = 'plv8_init'; select fhir_expand_valueset::jsonb val from fhir_expand_valueset('` + string(params) + `');`, w)
}
*/
