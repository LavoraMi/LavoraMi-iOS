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
                    title: String(localized: .featureRow1Title),
                    description: String(localized: .featureRow1Desc)
                )

                FeatureRow(
                    icon: "mappin.and.ellipse",
                    iconColor: Color(red: 28/255, green: 28/255, blue: 1),
                    title: String(localized: .featureRow2Title),
                    description: String(localized: .featureRow2Desc)
                )

                FeatureRow(
                    icon: "arrow.left.arrow.right",
                    iconColor: Color(red: 28/255, green: 28/255, blue: 1),
                    title: String(localized: .featureRow3Title),
                    description: String(localized: .featureRow3Desc)
                )
            }

            Text("Puoi rivedere questa pagina premendo sulla tab \"Mappa\" quando è selezionata.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(.top, 30)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            
            HStack {
                Spacer()
                Button(action: {})
                {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                        
                        Text("Mappa")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(maxWidth: 200)
                    .frame(height: 38)
                    .background(
                        Capsule()
                            .fill(Color(red: 28/255, green: 28/255, blue: 1))
                    )
                    .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.top, 20)
            
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
