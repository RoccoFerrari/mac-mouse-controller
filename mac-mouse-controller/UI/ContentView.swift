//
//  ContentView.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            if appState.hasPermissions {
                // UI with no errors
                Image(systemName: "computermouse.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("Mouse Control Enabled")
                    .font(.title)
                Text("Application is running in background.")
                    .foregroundStyle(.secondary)
            } else {
                // UI permession request
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                Text("Permissions Needed")
                    .font(.title)
                Text("Please, allow mouse control in system settings.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                                
                Button("Open Settings") {
                    appState.openSettings()
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            Button("Exit") {
                appState.quitApp()
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

