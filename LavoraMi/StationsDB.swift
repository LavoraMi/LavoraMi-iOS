//
//  StationsDB.swift
//  LavoraMi
//
//  Created by Andrea Filice on 08/01/26.
//

import Foundation
import MapKit

struct StationsDB {
    static let stationsM1: [MetroStation] = [
        .init(name: "Sesto 1° Maggio FS", coordinate: .init(latitude: 45.54156, longitude: 9.23835), branch: "Main"),
        .init(name: "Sesto Rondò", coordinate: .init(latitude: 45.5342, longitude: 9.23128), branch: "Main"),
        .init(name: "Sesto Marelli", coordinate: .init(latitude: 45.52356, longitude: 9.22796), branch: "Main"),
        .init(name: "Villa S. Giovanni", coordinate: .init(latitude: 45.51745, longitude: 9.22613), branch: "Main"),
        .init(name: "Precotto", coordinate: .init(latitude: 45.51215, longitude: 9.22449), branch: "Main"),
        .init(name: "Gorla", coordinate: .init(latitude: 45.50662, longitude: 9.22287), branch: "Main"),
        .init(name: "Turro", coordinate: .init(latitude: 45.50091, longitude: 9.22114), branch: "Main"),
        .init(name: "Rovereto", coordinate: .init(latitude: 45.49578, longitude: 9.21957), branch: "Main"),
        .init(name: "Pasteur", coordinate: .init(latitude: 45.49091, longitude: 9.21816), branch: "Main"),
        .init(name: "Loreto", coordinate: .init(latitude: 45.48584, longitude: 9.21638), branch: "Main"),
        .init(name: "Lima", coordinate: .init(latitude: 45.48027, longitude: 9.21085), branch: "Main"),
        .init(name: "Porta Venezia", coordinate: .init(latitude: 45.47471, longitude: 9.20568), branch: "Main"),
        .init(name: "Palestro", coordinate: .init(latitude: 45.47142, longitude: 9.20194), branch: "Main"),
        .init(name: "San Babila", coordinate: .init(latitude: 45.46642, longitude: 9.19757), branch: "Main"),
        .init(name: "Duomo", coordinate: .init(latitude: 45.46443, longitude: 9.18927), branch: "Main"),
        .init(name: "Cordusio", coordinate: .init(latitude: 45.46539, longitude: 9.18635), branch: "Main"),
        .init(name: "Cairoli", coordinate: .init(latitude: 45.4682, longitude: 9.18225), branch: "Main"),
        .init(name: "Cadorna FN", coordinate: .init(latitude: 45.4682, longitude: 9.17588), branch: "Main"),
        .init(name: "Conciliazione", coordinate: .init(latitude: 45.46749, longitude: 9.1663), branch: "Main"),
        .init(name: "Pagano", coordinate: .init(latitude: 45.46828, longitude: 9.16077), branch: "Main"),
        
        .init(name: "Buonarroti", coordinate: .init(latitude: 45.47054, longitude: 9.1552), branch: "Rho"),
        .init(name: "Amendola", coordinate: .init(latitude: 45.47356, longitude: 9.15132), branch: "Rho"),
        .init(name: "Lotto", coordinate: .init(latitude: 45.47909, longitude: 9.14454), branch: "Rho"),
        .init(name: "QT8", coordinate: .init(latitude: 45.48625, longitude: 9.13743), branch: "Rho"),
        .init(name: "Lampugnano", coordinate: .init(latitude: 45.4894, longitude: 9.12731), branch: "Rho"),
        .init(name: "Uruguay", coordinate: .init(latitude: 45.49344, longitude: 9.12045), branch: "Rho"),
        .init(name: "Bonola", coordinate: .init(latitude: 45.49703, longitude: 9.11009), branch: "Rho"),
        .init(name: "San Leonardo", coordinate: .init(latitude: 45.50116, longitude: 9.10149), branch: "Rho"),
        .init(name: "Molino Dorino", coordinate: .init(latitude: 45.50516, longitude: 9.09323), branch: "Rho"),
        .init(name: "Pero", coordinate: .init(latitude: 45.50869, longitude: 9.08581), branch: "Rho"),
        .init(name: "Rho Fiera", coordinate: .init(latitude: 45.51797, longitude: 9.08564), branch: "Rho"),
        
        .init(name: "Wagner", coordinate: .init(latitude: 45.46784, longitude: 9.15529), branch: "Bisceglie"),
        .init(name: "De Angeli", coordinate: .init(latitude: 45.46656, longitude: 9.14987), branch: "Bisceglie"),
        .init(name: "Gambara", coordinate: .init(latitude: 45.46499, longitude: 9.14295), branch: "Bisceglie"),
        .init(name: "Bande Nere", coordinate: .init(latitude: 45.46133, longitude: 9.13695), branch: "Bisceglie"),
        .init(name: "Primaticcio", coordinate: .init(latitude: 45.45952, longitude: 9.12961), branch: "Bisceglie"),
        .init(name: "Inganni", coordinate: .init(latitude: 45.45756, longitude: 9.12225), branch: "Bisceglie"),
        .init(name: "Bisceglie", coordinate: .init(latitude: 45.45531, longitude: 9.11335), branch: "Bisceglie")
    ]
    
    static let stationsM3: [MetroStation] = [
        .init(name: "San Donato", coordinate: .init(latitude: 45.42897, longitude: 9.25653), branch: "Main"),
        .init(name: "Rogoredo FS", coordinate: .init(latitude: 45.43366, longitude: 9.23849), branch: "Main"),
        .init(name: "Porto Di Mare", coordinate: .init(latitude: 45.43717, longitude: 9.23041), branch: "Main"),
        .init(name: "Corvetto", coordinate: .init(latitude: 45.4403, longitude: 9.22385), branch: "Main"),
        .init(name: "Brenta", coordinate: .init(latitude: 45.44301, longitude: 9.21801), branch: "Main"),
        .init(name: "Lodi TIBB", coordinate: .init(latitude: 45.44698, longitude: 9.20975), branch: "Main"),
        .init(name: "Porta Romana", coordinate: .init(latitude: 45.45152, longitude: 9.203), branch: "Main"),
        .init(name: "Crocetta", coordinate: .init(latitude: 45.45597, longitude: 9.19569), branch: "Main"),
        .init(name: "Missori", coordinate: .init(latitude: 45.46057, longitude: 9.18818), branch: "Main"),
        .init(name: "Duomo", coordinate: .init(latitude: 45.46443, longitude: 9.18927), branch: "Main"),
        .init(name: "Montenapoleone", coordinate: .init(latitude: 45.47027, longitude: 9.19249), branch: "Main"),
        .init(name: "Turati", coordinate: .init(latitude: 45.47455, longitude: 9.19481), branch: "Main"),
        .init(name: "Repubblica", coordinate: .init(latitude: 45.48038, longitude: 9.19878), branch: "Main"),
        .init(name: "Centrale FS", coordinate: .init(latitude: 45.48469, longitude: 9.20274), branch: "Main"),
        .init(name: "Sondrio", coordinate: .init(latitude: 45.4896, longitude: 9.20109), branch: "Main"),
        .init(name: "Zara", coordinate: .init(latitude: 45.49225, longitude: 9.19246), branch: "Main"),
        .init(name: "Maciachini", coordinate: .init(latitude: 45.49788, longitude: 9.18478), branch: "Main"),
        .init(name: "Dergano", coordinate: .init(latitude: 45.50564, longitude: 9.17978), branch: "Main"),
        .init(name: "Affori Centro", coordinate: .init(latitude: 45.51358, longitude: 9.17417), branch: "Main"),
        .init(name: "Affori FN", coordinate: .init(latitude: 45.52087, longitude: 9.16901), branch: "Main"),
        .init(name: "Comasina", coordinate: .init(latitude: 45.52835, longitude: 9.16387), branch: "Main")
    ]
    
    static let stationsM5: [MetroStation] = [
        .init(name: "Bignami", coordinate: .init(latitude: 45.52653, longitude: 9.21227), branch: "Main"),
        .init(name: "Ponale", coordinate: .init(latitude: 45.52186, longitude: 9.20939), branch: "Main"),
        .init(name: "Bicocca", coordinate: .init(latitude: 45.51429, longitude: 9.20549), branch: "Main"),
        .init(name: "Ca'Granda", coordinate: .init(latitude: 45.50733, longitude: 9.20121), branch: "Main"),
        .init(name: "Istria", coordinate: .init(latitude: 45.50163, longitude: 9.19792), branch: "Main"),
        .init(name: "Marche", coordinate: .init(latitude: 45.49639, longitude: 9.19499), branch: "Main"),
        .init(name: "Zara", coordinate: .init(latitude: 45.49225, longitude: 9.19246), branch: "Main"),
        .init(name: "Isola", coordinate: .init(latitude: 45.48759, longitude: 9.19131), branch: "Main"),
        .init(name: "Garibaldi FS", coordinate: .init(latitude: 45.48351, longitude: 9.18671), branch: "Main"),
        .init(name: "Monumentale", coordinate: .init(latitude: 45.48532, longitude: 9.18098), branch: "Main"),
        .init(name: "Cenisio", coordinate: .init(latitude: 45.48799, longitude: 9.17207), branch: "Main"),
        .init(name: "Gerusalemme", coordinate: .init(latitude: 45.48469, longitude: 9.16696), branch: "Main"),
        .init(name: "Domodossola FN", coordinate: .init(latitude: 45.48135, longitude: 9.1621), branch: "Main"),
        .init(name: "Tre Torri", coordinate: .init(latitude: 45.47807, longitude: 9.15664), branch: "Main"),
        .init(name: "Portello", coordinate: .init(latitude: 45.4814, longitude: 9.15045), branch: "Main"),
        .init(name: "Lotto", coordinate: .init(latitude: 45.47909, longitude: 9.14454), branch: "Main"),
        .init(name: "Segesta", coordinate: .init(latitude: 45.47909, longitude: 9.13734), branch: "Main"),
        .init(name: "S. Siro Ippodromo", coordinate: .init(latitude: 45.47909, longitude: 9.12858), branch: "Main"),
        .init(name: "S. Siro Stadio", coordinate: .init(latitude: 45.47909, longitude: 9.11857), branch: "Main")
    ]
}
