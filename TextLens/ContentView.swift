//
//  ContentView.swift
//  TextLens
//
//  Created by Tricster on 2020/11/6.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack{
            Text("Hello, World!")
            Button(action: {
                print("click")
            }, label: {
                Text("click me")
            })
        }.frame(width: 200, height: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
