//
//  RelayConfigView.swift
//  damus
//
//  Created by William Casarin on 2023-01-30.
//

import SwiftUI

struct RelayConfigView: View {
    let state: DamusState
    @State var relays: [RelayDescriptor]
    @State private var showActionButtons = false
    @State var show_add_relay: Bool = false
    @SceneStorage("RelayConfigView.show_recommended") var show_recommended : Bool = true
    
    @Environment(\.dismiss) var dismiss
    
    init(state: DamusState) {
        self.state = state
        _relays = State(initialValue: state.pool.our_descriptors)
    }
    
    var recommended: [RelayDescriptor] {
        let rs: [RelayDescriptor] = []
        let recommended_relay_addresses = get_default_bootstrap_relays()
        return recommended_relay_addresses.reduce(into: rs) { xs, x in
            if state.pool.get_relay(x) == nil, let url = RelayURL(x) {
                xs.append(RelayDescriptor(url: url, info: .rw))
            }
        }
    }
    
    var body: some View {
        MainContent
        .onReceive(handle_notify(.relays_changed)) { _ in
            self.relays = state.pool.our_descriptors
        }
        .onReceive(handle_notify(.switched_timeline)) { _ in
            dismiss()
        }
    }
    
    var MainContent: some View {
        VStack {
            Divider()
            
            if showActionButtons && !show_recommended {
                VStack {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            show_recommended.toggle()
                        }
                    }) {
                        Text("Show recommended relays", comment: "Button to show recommended relays.")
                            .foregroundStyle(DamusLightGradient.gradient)
                            .padding(10)
                            .background {
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(DamusLightGradient.gradient)
                            }
                    }
                    .padding(.top, 10)
                }
            }
            
            if recommended.count > 0 && show_recommended {
                VStack {
                    HStack(alignment: .top) {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                show_recommended.toggle()
                            }
                        }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(DamusLightGradient.gradient)
                        }
                        .padding([.top, .trailing], 8)
                    }
                    
                    Text("Recommended relays", comment: "Title for view of recommended relays.")
                        .foregroundStyle(DamusLightGradient.gradient)
                        .padding(10)
                        .background {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(DamusLightGradient.gradient)
                        }
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: 20) {
                            ForEach(recommended, id: \.url) { r in
                                RecommendedRelayView(damus: state, relay: r.url.id)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 5)
                    }
                    .scrollIndicators(.hidden)
                    .mask(
                        HStack(spacing: 0) {
                            LinearGradient(gradient: Gradient(colors: [Color.clear, Color.white]), startPoint: .leading, endPoint: .trailing)
                                .frame(width: 30)
                            
                            Rectangle()
                                .fill(Color.white)
                                .frame(maxWidth: .infinity)
                            
                            LinearGradient(gradient: Gradient(colors: [Color.white, Color.clear]), startPoint: .leading, endPoint: .trailing)
                                .frame(width: 30)
                        }
                    )
                    .padding()
                }
                .frame(minWidth: 250, maxWidth: .infinity, minHeight: 250, alignment: .center)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DamusLightGradient.gradient.opacity(0.15), strokeBorder: DamusLightGradient.gradient, lineWidth: 1)
                }
                .padding(.horizontal)
            }
            
            HStack {
                Text(NSLocalizedString("My Relays", comment: "Section title for relay servers that the user is connected to."))
                    .font(.system(size: 32, weight: .bold))

                Spacer()
                
                Button(action: {
                    show_add_relay.toggle()
                }) {
                    HStack {
                        Text(verbatim: "Add relay")
                            .padding(10)
                    }
                }
                .buttonStyle(NeutralButtonStyle())
            }
            .padding(25)
            
            List(Array(relays), id: \.url) { relay in
                RelayView(state: state, relay: relay.url.id, showActionButtons: $showActionButtons)
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle(NSLocalizedString("Relays", comment: "Title of relays view"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $show_add_relay, onDismiss: { self.show_add_relay = false }) {
            if #available(iOS 16.0, *) {
                AddRelayView(state: state)
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
            } else {
                AddRelayView(state: state)
            }
        }
        .toolbar {
            if state.keypair.privkey != nil {
                if showActionButtons {
                    Button("Done") {
                        withAnimation {
                            showActionButtons.toggle()
                        }
                    }
                } else {
                    Button("Edit") {
                        withAnimation {
                            showActionButtons.toggle()
                        }
                    }
                }
            }
        }
    }
}

struct RelayConfigView_Previews: PreviewProvider {
    static var previews: some View {
        RelayConfigView(state: test_damus_state)
    }
}
