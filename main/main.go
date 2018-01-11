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
	router.HandleFunc("/nci/fhir/{resourceType}", dao.GetResourceSearchResult).Methods("GET")
	router.HandleFunc("/nci/fhir/{resourceType}/{id}", dao.GetResourceById).Methods("GET")
	router.HandleFunc("/nci/fhir/{resourceType}/{id}/_history/{vid}", dao.GetResourceHistoryById)
	router.HandleFunc("/nci/fhir/{resourceType}/{id}/_history", dao.GetResourceHistory)
	router.HandleFunc("/nci/fhir/ValueSet/{id}/$expand", dao.GetExpandValueSetById)
	router.HandleFunc("/nci/fhir/ValueSet/{id}/_history/{vid}/$expand", dao.GetExpandValueSetById)

	router.HandleFunc("/nci/fhir/CodeSystem", dao.PostCodeSystem).Methods("POST")
	router.HandleFunc("/nci/fhir/CodeSystem/{id}", dao.PutCodeSystem).Methods("PUT")


	log.Fatal(http.ListenAndServe(":" + strconv.Itoa(ss.GetSettings().Port), router))
}