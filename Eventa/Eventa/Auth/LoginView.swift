// LoginView.swift
// Eventa (Apple-native style)

import SwiftUI

struct LoginView: View {
    @Bindable var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLogin = true
    @State private var fullName = ""
    @State private var rememberMe = true

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header (aligned left to match native design)
                VStack(alignment: .leading, spacing: 6) {
                    Text(isLogin ? "Sign in" : "Sign up")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color(.label))
                    
                    Text(isLogin ? "Give credential to sign in your account" : "Create account and enjoy all services")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 40)
                
                // Form Fields
                VStack(spacing: 20) {
                    if !isLogin {
                        nativeTextField(icon: "person.circle", placeholder: "Type your full name", text: $fullName)
                    }
                    
                    nativeTextField(icon: "envelope", placeholder: "Type your email", text: $email, keyboardType: .emailAddress)
                    
                    nativeSecureField(icon: "lock", placeholder: "Type your password", text: $password)
                    
                    if !isLogin {
                        nativeSecureField(icon: "lock", placeholder: "Type your confirm password", text: $confirmPassword)
                    }
                }
                .padding(.horizontal, 24)
                
                // Remember Me & Forgot Password (Sign in only)
                if isLogin {
                    HStack {
                        Toggle(isOn: $rememberMe) {
                            Text("Remember Me")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .labelsHidden()
                        
                        Text("Remember Me")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button("Forgot Password?") {
                            // Forgot action
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
                
                // Sign In / Sign Up Button
                Button {
                    // Quick validations and state update
                    if !isLogin && !fullName.isEmpty {
                        appState.userName = fullName
                    }
                    if !email.isEmpty {
                        appState.userEmail = email
                    }
                    withAnimation { appState.isLoggedIn = true }
                } label: {
                    Text(isLogin ? "SIGN IN" : "SIGN UP")
                        .font(.headline.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(white: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                
                Spacer()
                
                // Social Login Section
                VStack(spacing: 30) {
                    HStack {
                        VStack { Divider() }
                        Text("or continue with")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        VStack { Divider() }
                    }
                    .padding(.horizontal, 40)
                    
                    HStack(spacing: 20) {
                        socialIcon(image: "fb_logo") // We will use SF Symbols since assets might differ
                        socialIcon(image: "google_logo")
                        socialIcon(image: "apple_logo")
                    }
                    
                    Button {
                        withAnimation {
                            isLogin.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isLogin ? "Don't have an account?" : "Already have an account?")
                                .foregroundStyle(.secondary)
                            Text(isLogin ? "Sign Up" : "Sign In")
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                        .font(.subheadline)
                    }
                    .padding(.bottom, 20)
                }
            }
            // Align back button visually
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Action for back, mostly empty in root view
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func nativeTextField(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        }
    }
    
    private func nativeSecureField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            SecureField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            Image(systemName: "eye.slash.fill")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        }
    }
    
    // Abstracting social icons to closely match screenshot with standard symbols
    private func socialIcon(image: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
                .frame(width: 70, height: 60)
            
            if image == "fb_logo" {
                Text("f").font(.title.weight(.bold)).foregroundStyle(.blue)
            } else if image == "google_logo" {
                Text("G").font(.title.weight(.bold)).foregroundStyle(.red)
            } else {
                Image(systemName: "applelogo").font(.title2)
            }
        }
    }
}

#Preview {
    LoginView(appState: AppState.shared)
}
