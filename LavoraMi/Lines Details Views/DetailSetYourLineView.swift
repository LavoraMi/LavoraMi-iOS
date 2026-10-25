//
//  DetailSetYourLineView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 25/10/2026.
//

import SwiftUI
import MapKit
import SafariServices
import WidgetKit
import LocalAuthentication
import SwiftUIMailView
import AuthenticationServices
import CryptoKit
import FirebaseCore
import FirebaseMessaging
import Translation
import StoreKit
import Combine
import SystemConfiguration
import CoreLocation
import FoundationModels

internal import Auth

struct DetailSetYourLineView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage = 0
    @State var startImageTransition: Bool = false
    @State var imageTransitionFirstPage: Bool = false
    @State var i = 0
    @Binding var showInfoView: Bool
    @AppStorage("enableAnimations") var enableAnimations = true

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $currentPage) {
                    ScrollView {
                        VStack(spacing: 30) {
                            if #available(iOS 18.0, *), enableAnimations {
                                Image(systemName: startImageTransition ? "heart.fill" : "plus.app.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.red)
                                    .padding(.top, 50)
                                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                                    .onAppear {
                                        Task {
                                            try? await Task.sleep(for: .seconds(1))
                                            withAnimation {
                                                startImageTransition = true
                                            }
                                        }
                                    }
                                    .onDisappear {
                                        startImageTransition = false
                                    }
                            } else {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.red)
                                    .padding(.top, 40)
                            }

                            Text("Come posso mettere una linea nei preferiti?")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            (Text("Per poter mettere la TUA linea tra i preferiti, basta che vai nella sezione \"Linee\" con questo simbolo: ")
                             + Text(Image(systemName: "arrow.branch")))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Text("Per aggiungere una linea in questa sezione, vai nella scheda della tua ")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            + Text("linea").bold()
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            + Text(", clicca su ")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            + Text(Image(systemName: "heart"))
                            + Text(" per aggiungerla alla lista. Puoi modificarla in qualsiasi momento.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Divider()
                            
                            Text("Scegli qualsiasi linea.")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            HStack{
                                Text("M1")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: "M1"))
                                    )
                                
                                Text("S5")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: "S5"))
                                    )
                                
                                Text("M3")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: "M3"))
                                    )
                                
                                Text("S2")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: "S2"))
                                    )
                                
                                Text("z620")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColor(for: "z620"))
                                    )
                            }
                            
                            Text("Non importa se Suburbano, Metro o Bus, scegli la linea che più ti interessa.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                    .tag(0)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("Linee Preferite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .padding(4)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func dismiss() {
        showInfoView = false
        presentationMode.wrappedValue.dismiss()
    }
    
    @ViewBuilder
    private func currentStatus(icon: String, color: Color, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.branch")
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                .font(.headline)

                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }

            Text(description)
                .font(.callout)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}
