//
//  PasskeysView.swift
//  LavoraMi
//
//  Created by Andrea Filice on 12/11/2026.
//

import SwiftUI
import UIKit

struct PasskeysView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthManager
    
    @State private var passkeys: [PasskeyInfo] = []
    @State private var isLoading: Bool = true
    @State private var errorFetching: Bool = false
    @State private var isWorking: Bool = false
    @State private var window: UIWindow?
    @State private var skeletonPulse: Bool = false
    
    @State private var deleteTarget: PasskeyInfo?
    @State private var showDeleteAlert: Bool = false
    
    @State private var feedbackMessage: String = ""
    @State private var showFeedbackAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    listSection
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                addPasskeyButton
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))
            }
            .background(PasskeyWindowReader(window: $window))
            .navigationTitle("Passkey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
            .task { await loadPasskeys() }
            .alert("Sei sicuro?", isPresented: $showDeleteAlert) {
                Button("Annulla", role: .cancel) { }
                Button("Continua", role: .destructive) { deleteSelectedPasskey() }
            } message: {
                Text("Sei sicuro di voler eliminare questa Passkey collegata al tuo Account?")
            }
            .alert("Passkey", isPresented: $showFeedbackAlert) {
                Button("Chiudi", role: .cancel) { }
            } message: {
                Text(feedbackMessage)
            }
        }
    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundColor(Color("TextColor"))
                .padding(4)
                .clipShape(Circle())
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gestisci Passkey")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Gestisci le Passkey collegate al tuo Account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var listSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                skeletonList
            }
            else if errorFetching {
                errorState
            }
            else if passkeys.isEmpty {
                emptyState
            }
            else {
                ForEach(passkeys) { passkey in
                    passkeyRow(passkey)
                }
            }
        }
    }
    
    private var skeletonList: some View {
        VStack(spacing: 12) {
            skeletonRow
            skeletonRow
            skeletonRow
        }
        .opacity(skeletonPulse ? 0.45 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                skeletonPulse = true
            }
        }
    }
    
    private var skeletonRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.badge.key.fill")
                .foregroundStyle(Color.gray.opacity(0.4))
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 190, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 110, height: 10)
            }
            
            Spacer()
            
            Image(systemName: "trash.fill")
                .foregroundStyle(Color.gray.opacity(0.4))
                .font(.title3)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var errorState: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.red)
            Text("Errore di connessione.")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Riprova") {
                Task { await loadPasskeys() }
            }
            .foregroundStyle(.blue)
        }
        .padding(.leading, 5)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.key")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            
            Text("Nessuna Passkey per questo Account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func passkeyRow(_ passkey: PasskeyInfo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.badge.key.fill")
                .foregroundStyle(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(passkey.name.isEmpty ? "Passkey" : passkey.name)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                
                Text("Creata il \(formatted(passkey.createdAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                deleteTarget = passkey
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .disabled(isWorking)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .contentShape(Rectangle())
    }
    
    private var addPasskeyButton: some View {
        Button(action: addPasskey) {
            HStack(spacing: 8) {
                if isWorking {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                else {
                    Image(systemName: "person.badge.key.fill")
                }
                
                Text("Aggiungi Passkey")
                    .fontWeight(.bold)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isWorking ? Color.gray.opacity(0.5) : Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isWorking || isLoading)
    }
    
    private func formatted(_ date: Date?) -> String {
        guard let date else { return "-" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func show(_ message: String) {
        feedbackMessage = message
        showFeedbackAlert = true
    }
    
    private func loadPasskeys() async {
        isLoading = true
        errorFetching = false
        
        do {
            passkeys = try await authManager.listPasskeys()
        }
        catch {
            print("Errore nel caricamento delle passkey: \(error)")
            errorFetching = true
        }
        
        isLoading = false
    }
    
    private func addPasskey() {
        guard !isWorking else { return }
        
        guard let anchor = window else {
            show("Impossibile avviare la creazione della passkey. Riprova.")
            return
        }
        
        isWorking = true
        
        Task {
            do {
                try await authManager.registerPasskey(anchor: anchor)
                await loadPasskeys()
            }
            catch {
                if !AuthManager.isPasskeyCancellation(error) {
                    print("Errore registrazione passkey: \(error)")
                    show(AuthManager.passkeyMessage(for: error))
                }
            }
            isWorking = false
        }
    }
    
    private func deleteSelectedPasskey() {
        guard let target = deleteTarget else { return }
        
        Task {
            do {
                try await authManager.deletePasskey(target)
                passkeys.removeAll { $0.id == target.id }
            }
            catch {
                print("Errore eliminazione passkey: \(error)")
                show(AuthManager.passkeyMessage(for: error))
            }
        }
    }
}

struct PasskeyWindowReader: UIViewRepresentable {
    @Binding var window: UIWindow?
    
    func makeUIView(context: Context) -> WindowObserverView {
        let view = WindowObserverView()
        view.isUserInteractionEnabled = false
        view.onWindowChange = { newWindow in
            DispatchQueue.main.async { window = newWindow }
        }
        return view
    }
    
    func updateUIView(_ uiView: WindowObserverView, context: Context) { }
    
    final class WindowObserverView: UIView {
        var onWindowChange: ((UIWindow?) -> Void)?
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            onWindowChange?(window)
        }
    }
}
