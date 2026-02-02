//
//  SupabaseClient.swift
//  LavoraMi
//
//  Created by Andrea Filice on 02/02/26.
//

import Foundation
import Supabase

let supabaseUrl = URL(string: "https://nfwcqsdbniwmmwcljgnw.supabase.co")!
let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5md2Nxc2Ribml3bW13Y2xqZ253Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5MDc4OTUsImV4cCI6MjA4NDQ4Mzg5NX0.n0BOksrd2mg4a0yVEuxFXTLu_aRCi-JWW7SXHrcGbDI"

let supabase = SupabaseClient(supabaseURL: supabaseUrl, supabaseKey: supabaseKey)
