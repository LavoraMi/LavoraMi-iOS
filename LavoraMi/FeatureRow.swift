//
//  FeatureRow.swift
//  LavoraMi
//
//  Created by Andrea Filice on 11/09/2026.
//

import SwiftUI

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 28))
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .lineSpacing(3)
            }
            Spacer()
        }
    }
}

struct StructedMovibusView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Mappe per i Bus")
                .font(.system(size: 36, weight: .heavy))
                .foregroundColor(.white)
                .padding(.top, 40)
                .padding(.bottom, 32)

            VStack(alignment: .leading, spacing: 32) {
                FeatureRow(
                    icon: "location.fill.viewfinder",
                    iconColor: Color(red: 28/255, green: 28/255, blue: 1),
                    title: "Visualizza le Mappe",
                    description: "Guarda le Mappe dei bus che usi ogni giorno! Dettagliate e create appositamente per te! [Funzione disponibile per linee MOVIBUS]."
                )

                FeatureRow(
                    icon: "mappin.and.ellipse",
                    iconColor: Color(red: 28/255, green: 28/255, blue: 1),
                    title: "Seleziona una fermata",
                    description: "Seleziona una fermata e visualizza gli orari del bus! Basta cliccarci sopra e vedrai le prossime partenze."
                )

                FeatureRow(
                    icon: "arrow.left.arrow.right",
                    iconColor: Color(red: 28/255, green: 28/255, blue: 1),
                    title: "Cambia Direzione",
                    description: "Cambia la direzione del tuo bus, selezionando il pulsante con questa icona. Potrai vedere le fermate nel senso opposto!"
                )
            }

            Spacer()

            if #available(iOS 26.0, *) {
                Button(action: { dismiss() }) {
                    Text("Chiudi")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .padding(.bottom, 24)
                .buttonStyle(.glass)
                .tint(Color(red: 28/255, green: 28/255, blue: 1))
            }
            else {
                Button(action: { dismiss() }) {
                    Text("Chiudi")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 24)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 4/255, green: 15/255, blue: 17/255))
    }
}

#Preview {
    StructedMovibusView()
}
