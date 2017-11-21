package main

import (
	"log"
	"net/http"
	"github.com/gorilla/mux"
	"strconv"
	_ "github.com/lib/pq"
	ss "../settings"
	"../dao"
	"../loader"
)

func main() {
	loader.LoadDbFunctions()
	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/nci/fhir/{resourceType}", dao.GetResourceSearchResult)
	router.HandleFunc("/nci/fhir/{resourceType}/{id}", dao.GetResourceById)
	router.HandleFunc("/nci/fhir/{resourceType}/{id}/_history/{vid}", dao.GetResourceHistoryById)
	//router.HandleFunc("/nci/fhir/{resourceType}/{id}/_history", dao.GetResourceHistory)

	//router.HandleFunc("/nci/fhir/ValueSet/{id}/$expand", dao.GetExpandValueSetById)
	log.Fatal(http.ListenAndServe(":" + strconv.Itoa(ss.GetSettings().Port), router))
}